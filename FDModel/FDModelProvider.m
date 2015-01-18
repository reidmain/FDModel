#import "FDModelProvider.h"
#import <FDFoundationKit/FDFoundationKit.h>


#pragma mark Class Extension

@interface FDModelProvider ()

- (id)_parseObject: (id)object 
	parentModelClass: (Class)parentModelClass 
	parentRemoteKeypath: (NSString *)parentRemoteKeyPath 
	modelClassBlock: (FDModelProviderModelClassBlock)modelClassBlock;

@end


#pragma mark - Class Variables

static FDModelProvider *_sharedInstance;


#pragma mark - Class Definition

@implementation FDModelProvider


#pragma mark - Constructors

+ (void)initialize
{
	// NOTE: initialize is called in a thead-safe manner so we don't need to worry about two shared instances possibly being created.
	
	// Create a flag to keep track of whether or not this class has been initialized because this method could be called a second time if a subclass does not override it.
	static BOOL classInitialized = NO;
	
	// If this class has not been initialized then create the shared instance.
	if (classInitialized == NO)
	{
		_sharedInstance = [[FDModelProvider alloc] 
			init];
		
		classInitialized = YES;
	}
}

- (id)init
{
	// Abort if base initializer fails.
	if ((self = [super init]) == nil)
	{
		return nil;
	}
	
	// Initialize instance variables.
	_modificationLock = [FDModel modificationLock];
	
	// Return initialized instance.
	return self;
}


#pragma mark - Public Methods

+ (FDModelProvider *)sharedInstance
{
	return _sharedInstance;
}

- (id)parseObject: (id)object 
	modelClassBlock: (FDModelProviderModelClassBlock)modelClassBlock;
{
	id parsedObject = [self _parseObject: object 
		parentModelClass: nil 
		parentRemoteKeypath: nil 
		modelClassBlock: modelClassBlock];
	
	return parsedObject;
}


#pragma mark - Private Methods

- (id)_parseObject: (id)object 
	parentModelClass: (Class)parentModelClass 
	parentRemoteKeypath: (NSString *)parentRemoteKeyPath 
	modelClassBlock: (FDModelProviderModelClassBlock)modelClassBlock
{
	[_modificationLock lock];
	
	// Ensure the parent model class is a subclass of FDModel.
	if (parentModelClass != nil 
		&& [parentModelClass isSubclassOfClass: [FDModel class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException 
			format: @"The parentModelClass parameter on %@ must be a subclass of FDModel", 
				NSStringFromSelector(_cmd)];
		
		[_modificationLock unlock];
		
		return object;
	}
	
	// If the object is an array attempt to transform each element of the array.
	if ([object isKindOfClass: [NSArray class]] == YES)
	{
		NSMutableArray *array = [NSMutableArray arrayWithCapacity: [object count]];
		
		[object enumerateObjectsUsingBlock: ^(id objectInArray, NSUInteger index, BOOL *stop)
			{
				id transformedObject = [self _parseObject: objectInArray 
					parentModelClass: parentModelClass 
					parentRemoteKeypath: parentRemoteKeyPath 
					modelClassBlock: modelClassBlock];
				
				if (FDIsNull(transformedObject) == NO)
				{
					[array addObject: transformedObject];
				}
			}];
		
		[_modificationLock unlock];
		
		return array;
	}
	// If the object is a dictionary attempt to transform it to a local model.
	else if ([object isKindOfClass: [NSDictionary class]] == YES)
	{
		// Ask the parent model class if it understands the dictionary.
		Class modelClass = nil;
		if (modelClass == nil)
		{
			modelClass = [parentModelClass modelClassForDictionary: object 
				withRemoteKeyPath: parentRemoteKeyPath];
		}
		
		// If the parent model class did not return a model class ask the block for the model class represented by the dictionary.
		if (modelClass == nil 
			&& modelClassBlock != nil)
		{
			modelClass = modelClassBlock(parentRemoteKeyPath, object);
		}
		
		// If the model class is NSNull ignore the dictionary entirely.
		if (modelClass == [NSNull class])
		{
			[_modificationLock unlock];
			
			return nil;
		}
		
		// If there is no model class iterate over all the keys and objects and attempt to convert them to local models.
		if (modelClass == nil)
		{
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: [object count]];
			
			[object enumerateKeysAndObjectsUsingBlock: ^(id key, id objectInDictionary, BOOL *stop)
				{
					id transformedObject = [self _parseObject: objectInDictionary 
						parentModelClass: parentModelClass 
						parentRemoteKeypath: key 
						modelClassBlock: modelClassBlock];
					
					[dictionary setValue: transformedObject 
						forKey: key];
				}];
			
			[_modificationLock unlock];
			
			return dictionary;
		}
		// If the model class block returned a model class populate an instance of it.
		else
		{
			// Ensure the model class is a subclass of FDModel.
			if ([modelClass isSubclassOfClass: [FDModel class]] == NO)
			{
				[NSException raise: NSInternalInconsistencyException 
					format: @"The model class for the following dictionary is not a subclass of FDModel:\n%@", 
						object];
				[_modificationLock unlock];
				
				return object;
			}
			
			// Get the remote key path that that points to the unique identifier of the object.
			NSString *remoteKeyPathForUniqueIdentifier = [modelClass remoteKeyPathForUniqueIdentifier];
			id identifier = [object valueForKeyPath: remoteKeyPathForUniqueIdentifier];
			
			// Load the instance of the model for the identifier if it exists. Otherwise create a blank instance of the model.
			FDModel *model = [modelClass modelWithIdentifier: identifier];
			
#if DEBUG
			[model modelWillBeginParsingRemoteObject: object];
#endif
			
			// Get the mapping of remote key paths to local key paths for the model class.
			NSDictionary *keyPathsMapping = [modelClass remoteKeyPathsToLocalKeyPaths];
			
			// Iterate over the mapping and attempt to parse the objects for each remote key path into their respective local model key paths.
			[keyPathsMapping enumerateKeysAndObjectsUsingBlock: ^(id remoteKeyPath, id localKeyPath, BOOL *stop)
				{
				#if DEBUG
					[model modelWillBeginParsingRemoteKeyPath: remoteKeyPath];
				#endif
					
					// Load the object for the remote key path.
					id remoteObject = [object valueForKeyPath: remoteKeyPath];
					
					// If the remote key path does not exist on the object ignore it and move onto the next item. There is no point in dealing with a remote key path that does not exist because it could only delete data that currently exists.
					if (remoteObject == nil)
					{
						return;
					}
					
					// Get the property info on the property that is about to be set.
					FDDeclaredProperty *declaredProperty = [modelClass declaredPropertyForKeyPath: localKeyPath];
					
					id transformedObject = nil;
					
					// If the remote object is not NSNull attempt to transform the remote object into local models. If the remote object is NSNull do nothing and allow the property being set to be cleared.
					if (remoteObject != [NSNull null])
					{
						// If a local transformer has been defined use it on the remote object.
						NSValueTransformer *valueTransformer = [modelClass transformerForKey: localKeyPath];
						if (valueTransformer != nil)
						{
							transformedObject = [valueTransformer transformedValue: remoteObject];
						}
						// If there is no local transformer attempt to transform the remote object into the property type being set.
						else
						{
							// If the property being set is of type FDModel and the remote object is a NSString or NSValue it is possible that the string is the unique identifier for the model. Check and see if an instance of model class with that identifier exists.
							if ([declaredProperty.type isSubclassOfClass: [FDModel class]] == YES 
								&& ([remoteObject isKindOfClass: [NSString class]] == YES 
									|| [remoteObject isKindOfClass: [NSValue class]] == YES))
							{
								// Ask the block for the model class represented by the remote object.
								Class modelClass = nil;
								if (modelClassBlock != nil)
								{
									modelClass = modelClassBlock(remoteKeyPath, remoteObject);
								}
								
								// If the model class is NSNull ignore the object entirely.
								if (modelClass == [NSNull class])
								{
									return;
								}
								
								// Ensure the model class is a subclass of FDModel.
								if (modelClass != nil 
									&& [modelClass isSubclassOfClass: [FDModel class]] == NO)
								{
									[NSException raise: NSInternalInconsistencyException 
										format: @"The model class for '%@' is not a subclass of FDModel.", 
											remoteObject];
									
									return;
								}
								
								// If the model class is still nil use the declared property type.
								if (modelClass == nil)
								{
									modelClass = declaredProperty.type;
								}
								
								transformedObject = [modelClass modelWithIdentifier: remoteObject];
							}
							// If the property being set is of type FDModel and the remote object is a NSDictionary attempt to transform the dictionary into an instance of the FDModel class.
							else if ([declaredProperty.type isSubclassOfClass: [FDModel class]] == YES 
								&& [remoteObject isKindOfClass: [NSDictionary class]] == YES)
							{
								transformedObject = [self _parseObject: remoteObject 
									parentModelClass: parentModelClass 
									parentRemoteKeypath: remoteKeyPath 
									modelClassBlock: ^Class(NSString *parentKey, id value)
										{
											Class modelClass = modelClassBlock(parentKey, value);
											
											if (parentKey == remoteKeyPath 
												&& modelClass == nil)
											{
												modelClass = declaredProperty.type;
											}
											
											return modelClass;
										} ];
							}
							// If the property being set is a NSURL and the remote object is a NSString convert the string to a NSURL object.
							else if ([declaredProperty.type isSubclassOfClass: [NSURL class]] == YES 
								&& [remoteObject isKindOfClass: [NSString class]] == YES)
							{
								transformedObject = [NSURL URLWithString: remoteObject];
							}
							// If the property being set is a NSDate and the remote object is a NSString attempt to convert the string to a NSDate using the date formatter.
							else if ([declaredProperty.type isSubclassOfClass: [NSDate class]] == YES 
								&& [remoteObject isKindOfClass: [NSString class]] == YES)
							{
								transformedObject = [_dateFormatter dateFromString: remoteObject];
							}
							// If the property being set is a NSString and the remote object is a NSNumber convert the number to a string.
							else if ([declaredProperty.type isSubclassOfClass: [NSString class]] == YES 
								&& [remoteObject isKindOfClass: [NSNumber class]] == YES)
							{
								transformedObject = [remoteObject stringValue];
							}
							// If the property being set is a NSNumber and the remote object is a NSString convert the string to a number.
							else if ([declaredProperty.type isSubclassOfClass: [NSNumber class]] == YES
								&& [remoteObject isKindOfClass: [NSString class]] == YES)
							{
								double value = [remoteObject doubleValue];
								transformedObject = @(value);
							}
							// If the remote object is a collection object and is the same type as the property type being set attempt to transformation the collection into local models.
							else if ([remoteObject isKindOfClass: declaredProperty.type] == YES 
								&& ([declaredProperty.type isSubclassOfClass: [NSArray class]] == YES 
									|| [declaredProperty.type isSubclassOfClass: [NSDictionary class]] == YES))
							{
								transformedObject = [self _parseObject: remoteObject 
									parentModelClass: modelClass 
									parentRemoteKeypath: remoteKeyPath 
									modelClassBlock: modelClassBlock];
							}
							// If no transformations were valid attempt to set the remote object on the property.
							else
							{
								transformedObject = remoteObject;
							}
						}
					}
					
				#if DEBUG
					[model modelDidFinishParsingRemoteKeyPath: remoteKeyPath];
				#endif
					
					// If the transformed object is not the same type as the property that is being set stop parsing and move onto the next item because there is no point in attempting to set it since it will always result in nil.
					if (transformedObject != nil 
						&& declaredProperty.type != nil 
						&& [transformedObject isKindOfClass: declaredProperty.type] == NO)
					{
						return;
					}
					// If the transformed object is nil and the declared property is a scalar type do not bother trying to set it because it will only result in an exception.
					else if (transformedObject == nil 
						&& declaredProperty.type == nil)
					{
						return;
					}
					
					@try
					{
						[model setValue: transformedObject 
							forKeyPath: localKeyPath];
					}
					// If the key path on the local model does not exist an exception will most likely be thrown. Catch this exeception and log it so that any incorrect mappings will not crash the application.
					@catch (NSException *exception)
					{
						FDLog(FDLogLevelInfo, @"Could not set %@ property on %@ because %@", localKeyPath, [model class], [exception reason]);
					}
				}];
			
#if DEBUG
			[model modelDidFinishParsingRemoteObject: object];
#endif
			
			[_modificationLock unlock];
			
			return model;
		}
	}
	else if ([object isKindOfClass: [NSString class]] == YES)
	{
		// Ask the block for the model class represented by the string.
		Class modelClass = nil;
		if (modelClassBlock != nil)
		{
			modelClass = modelClassBlock(parentRemoteKeyPath, object);
		}
		
		// If the model class is NSNull return nothing.
		if (modelClass == [NSNull class])
		{
			[_modificationLock unlock];
			
			return nil;
		}
		// If the model class is nil return the string.
		else if (modelClass == nil)
		{
			[_modificationLock unlock];
			
			return object;
		}
		
		// Ensure the model class is a subclass of FDModel.
		if ([modelClass isSubclassOfClass: [FDModel class]] == NO)
		{
			[NSException raise: NSInternalInconsistencyException 
				format: @"The model class for '%@' is not a subclass of FDModel.", 
					object];
			
			[_modificationLock unlock];
			
			return object;
		}
		
		// Load the instance of the model for the string if it exists. Otherwise create a blank instance of the model.
		id transformedObject = [modelClass modelWithIdentifier: object];
		
		[_modificationLock unlock];
		
		return transformedObject;
	}
	// If the object is a NSNull replace it with nil to prevent the inevitable crash caused by NSNull getting sent a message.
	else if (object == [NSNull null])
	{
		[_modificationLock unlock];
		
		return nil;
	}
	
	[_modificationLock unlock];
	
	// Return the object if it could not be transformed.
	return object;
}


@end