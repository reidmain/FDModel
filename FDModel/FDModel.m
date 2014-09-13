#import "FDModel.h"
#import "FDModelProvider.h"
#import "FDArchivedFileModelStore.h"
#import <FDFoundationKit/FDFoundationKit.h>


#pragma mark Class Variables

static FDModelStore *_modelStore;
static NSMutableDictionary *_existingModelsByClass;


#pragma mark - Class Definition

@implementation FDModel


#pragma mark - Constructors

+ (void)initialize
{
	// NOTE: initialize is called in a thead-safe manner so we don't need to worry about two shared instances possibly being created.
	
	// Create a flag to keep track of whether or not this class has been initialized because this method could be called a second time if a subclass does not override it.
	static BOOL classInitialized = NO;
	
	// If this class has not been initialized then initalize the class variables.
	if (classInitialized == NO)
	{
		_modelStore = [FDArchivedFileModelStore new];
		_existingModelsByClass = [NSMutableDictionary new];
		
		classInitialized = YES;
	}
}

+ (instancetype)modelWithIdentifier: (id)identifier
{
	FDModel *model = [[self alloc] 
		initWithIdentifier: identifier];
	
	return model;
}

+ (instancetype)modelWithDictionary: (NSDictionary *)dictionary
{
	FDModelProvider *modelProvider = [FDModelProvider sharedInstance];
	FDModel *model = [modelProvider parseObject: dictionary 
		modelClassBlock: ^Class(NSString *parentKey, id value)
			{
				Class modelClass = nil;
				if (parentKey == nil)
				{
					return [self class];
				}
				
				return modelClass;
			}];
	
	if ([model isKindOfClass: [FDModel class]] == NO)
	{
		model = nil;
	}
	
	return model;
}

- (instancetype)initWithIdentifier: (id)identifier 
	initBlock: (FDModelInitBlock)initBlock 
	customizationBlock: (FDModelCustomizationBlock)customizationBlock
{
	// If an identifier has been passed in check if an instance of the class with the identifier already exists.
	if (FDIsEmpty(identifier) == NO)
	{
		// Because models can be created on any thread this code needs to be synchronized on the class being created to ensure that two threads can't create the same object at the same time.
		@synchronized ([self class])
		{
			NSString *modelClassAsString = NSStringFromClass([self class]);
			
			// Load the dictionary of all the existings models for the class. If the dictionary does not yet exist create it.
			FDCache *existingModels = [_existingModelsByClass objectForKey: modelClassAsString];
			if (existingModels == nil)
			{
				existingModels = [FDCache new];
				[_existingModelsByClass setValue: existingModels 
					forKey: modelClassAsString];
			}
			
			// Load the existing model for the identifier.
			FDModel *model = [existingModels objectForKey: identifier];
			
			// If the model does not exist call the init block.
			if (model == nil)
			{
				if (initBlock != nil)
				{
					model = initBlock(identifier);
				}
				
				// If the model still does not exist after the init block create a blank instance of the model.
				if (model == nil)
				{
					if ((self = [super init]) == nil)
					{
						return nil;
					}
				}
				else
				{
					self = model;
				}
				
				// Ensure the identifier is set on the model.
				_identifier = identifier;
				
				// Because the model was just created call the customization block.
				if (customizationBlock != nil)
				{
					customizationBlock(self);
				}
				
				// Store the model in the existing models dictionary to ensure that only one instance of the model will ever exist.
				[existingModels setObject: self 
					forKey: identifier];
			}
			// If the model already exists assign it to self.
			else
			{
				self = model;
			}
		}
	}
	// If there is no identifier create a blank instance of the model.
	else if ((self = [super init]) == nil)
	{
		return nil;
	}
	else	
	{
		// Because the model was just created call the customization block.
		if (customizationBlock != nil)
		{
			customizationBlock(self);
		}
	}
	
	// Return initialized instance.
	return self;
}

- (instancetype)initWithIdentifier: (id)identifier
{
	self = [self initWithIdentifier: identifier 
		initBlock: ^FDModel *(id identifier)
			{
				// If the model does not exist in memory check the model store.
				FDModel *model = [_modelStore modelForIdentifier: identifier];
				
				return model;
			} 
		customizationBlock: nil];
	
	if (self == nil)
	{
		return nil;
		
	}
	
	// Return initialized instance.
	return self;
}

- (id)initWithCoder: (NSCoder *)coder
{
	// Decode the identifier.
	id identifier = [coder decodeObjectForKey: @keypath(self.identifier)];
	
	self = [self initWithIdentifier: identifier 
		initBlock: nil 
		customizationBlock: ^(FDModel *model)
			{
				// Iterate over each declared property and attempt to decode it and set it on the model.
				NSArray *declaredProperties = [[model class] declaredPropertiesForSubclass: [FDModel class]];
				for (FDDeclaredProperty *declaredProperty in declaredProperties)
				{
					NSString *key = declaredProperty.name;
					id value = nil;
					
					@try
					{
						value = [coder decodeObjectForKey: key];
					}
					// If the code cannot successfully decode an object an exception will be thrown. Catch any exceptions and log them so that any failed decodings will not crash the application.
					@catch (NSException *exception)
					{
						FDLog(FDLogLevelInfo, @"Could not decode %@ on %@ because %@", key, [model class], [exception reason]);
					}
					
					@try
					{
						[model setValue: value 
							forKey: key];
					}
					// If the key on the model does not exist an exception will most likely be thrown. Catch any execeptions and log them so that any incorrect decodings will not crash the application.
					@catch (NSException *exception)
					{
						FDLog(FDLogLevelInfo, @"Could not set %@ property on %@ because %@", key, [model class], [exception reason]);
					}
				}
			}];
	
	if (self == nil)
	{
		return nil;
	}
	
	// Return initialized instance.
	return self;
}

- (id)copyWithZone: (NSZone *)zone
{
	FDModel *model = [[self class] new];
	
	// Iterate over each declared property and attempt to set it on the model.
	NSArray *declaredProperties = [[model class] declaredPropertiesForSubclass: [FDModel class]];
	for (FDDeclaredProperty *declaredProperty in declaredProperties)
	{
		NSString *key = declaredProperty.name;
		id value = nil;
		
		@try
		{
			value = [self valueForKey: key];
		}
		// If the code cannot successfully get a property an exception will be thrown. Catch any exceptions and log them so that any failed property accesses will not crash the application.
		@catch (NSException *exception)
		{
			FDLog(FDLogLevelInfo, @"Could not get %@ on %@ because %@", key, [model class], [exception reason]);
		}
		
		@try
		{
			[model setValue: value 
				forKey: key];
		}
		// If the key on the model does not exist an exception will most likely be thrown. Catch any execeptions and log them so that any incorrect property assignments will not crash the application.
		@catch (NSException *exception)
		{
			FDLog(FDLogLevelInfo, @"Could not set %@ property on %@ because %@", key, [model class], [exception reason]);
		}
	}

	return model;
}

#pragma mark - Public Methods

+ (NSString *)remoteKeyPathForUniqueIdentifier
{
	// This method should be overridden by all subclasses.
	return nil;
}

+ (NSDictionary *)remoteKeyPathsToLocalKeyPaths
{
	// This method should be overridden by all subclasses.
	return nil;
}

+ (NSValueTransformer *)transformerForKey: (NSString *)key
{
	// Check if the class implements a method called "<key>Transformer" and return the result if it exists.
	NSString *selectorName = [NSString stringWithFormat: @"%@Transformer", 
		key];
	SEL selector = NSSelectorFromString(selectorName);
	
	if ([self respondsToSelector: selector] == YES)
	{
		__unsafe_unretained NSValueTransformer *transformer = nil;
		
		NSMethodSignature *methodSignature = [self methodSignatureForSelector: selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: methodSignature];
		invocation.target = self;
		invocation.selector = selector;
		
		[invocation invoke];

		[invocation getReturnValue:&transformer];
		
		return transformer;
	}
	
	return nil;
}

+ (Class)modelClassForDictionary: (NSDictionary *)dictionary 
	withRemoteKeyPath: (NSString *)remoteKeyPath
{
	// This method can be overridden by all subclasses.
	return nil;
}

+ (void)setModelStore: (FDModelStore *)modelStore
{
	_modelStore = modelStore;
}

- (BOOL)save
{
	BOOL saveSuccessful = [_modelStore saveModel: self];
	
	return saveSuccessful;
}


#pragma mark - NSCoding Methods

- (void)encodeWithCoder: (NSCoder *)coder
{
	// Iterate over each declared property and encode it.
	NSArray *declaredProperties = [[self class] declaredPropertiesForSubclass: [FDModel class]];
	for (FDDeclaredProperty *declaredProperty in declaredProperties)
	{
		NSString *key = declaredProperty.name;
		id value = [self valueForKey: key];
		[coder encodeObject: value 
			forKey: key];
	}
}


#pragma mark - Overridden Methods

- (NSUInteger)hash
{
	NSString *modelClassAsString = NSStringFromClass([self class]);
	
	NSUInteger hash = [modelClassAsString hash] ^ [_identifier hash];
	
	return hash;
}

- (BOOL)isEqual: (id)object
{
	BOOL isEqual = NO;
	
	if (self == object)
	{
		isEqual = YES;
	}
	else if ([object isMemberOfClass: [FDModel class]] == YES)
	{
		isEqual = YES;
		
		// Iterate over each declared property check if they are equal.
		NSArray *declaredProperties = [[self class] declaredPropertiesForSubclass: [FDModel class]];
		for (FDDeclaredProperty *declaredProperty in declaredProperties)
		{
			NSString *key = declaredProperty.name;
			id modelValue = nil;
			id objectValue = nil;
			
			@try
			{
				modelValue = [self valueForKey: key];
				objectValue = [objectValue valueForKey: key];
			}
			// If the value for a key cannot be retrieved an exception will be thrown. Catch any exceptions and log them so that any failed property accesses will not crash the application.
			@catch (NSException *exception)
			{
				FDLog(FDLogLevelInfo, @"Could not get %@ on %@ because %@", key, [self class], [exception reason]);
			}
			
			if ((modelValue == nil && objectValue == nil) 
				 || [modelValue isEqual: objectValue] == NO)
			{
				isEqual = NO;
				
				break;
			}
		}
	}
	
	return isEqual;
}


#pragma mark - Debug Methods

- (void)modelWillBeginParsingRemoteObject: (NSDictionary *)remoteObject
{
}

- (void)modelDidFinishParsingRemoteObject: (NSDictionary *)remoteObject
{
#if (LOG_UNUSED_REMOTE_KEYS || LOG_MISSING_EXPECTED_REMOTE_KEYS)
	static NSMutableSet *validatedModels = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
		{
			validatedModels = [NSMutableSet set];
		});
	
	NSString *validationKey = NSStringFromClass([self class]);
	if ([validatedModels containsObject: validationKey] == NO)
	{
		NSDictionary *keyPathsMapping = [[self class] remoteKeyPathsToLocalKeyPaths];

		NSSet *remoteKeys = [NSSet setWithArray: remoteObject.allKeys];
		NSSet *ignoredKeys = [NSSet setWithArray: [[self class] ignoredRemoteKeyPaths]];
		NSSet *expectedKeys = [NSSet setWithArray: keyPathsMapping.allKeys];
		
		if (remoteKeys.count > 0 || expectedKeys.count > 0)
		{
			NSString *logHeader = [[NSString stringWithFormat: @"=== Validating response for %@ ", NSStringFromClass([self class])] stringByPaddingToLength: 100 withString: @"=" startingAtIndex: 0];
			FDLog(FDLogLevelDebug, @"");
			FDLog(FDLogLevelDebug, @"%@", logHeader);
		}

#if LOG_UNUSED_REMOTE_KEYS
		NSMutableSet *unusedKeys = [NSMutableSet setWithSet: remoteKeys];
		[unusedKeys minusSet: ignoredKeys];
		[unusedKeys minusSet: expectedKeys];
		
		for (NSString *key in unusedKeys)
		{
			FDLog(FDLogLevelDebug, @"Received key \"%@\" but it is not used by this class.", key);
		}
#endif
		
#if VERBOSE
		NSMutableSet *ignoredUnusedKeys = [NSMutableSet setWithSet: remoteKeys];
		[ignoredUnusedKeys intersectSet: ignoredKeys];
		
		for (NSString *key in ignoredUnusedKeys)
		{
			FDLog(FDLogLevelDebug, @"Ignoring key \"%@\".", key);
		}
#endif
		
#if LOG_MISSING_EXPECTED_REMOTE_KEYS
		NSMutableSet *missingKeys = [NSMutableSet setWithSet: expectedKeys];
		[missingKeys minusSet: remoteKeys];
		
		for (NSString *key in missingKeys)
		{
			FDLog(FDLogLevelDebug, @"Expected key \"%@\" but it was missing from the response.", key);
		}
#endif
		
		[validatedModels addObject: validationKey];
	}
#endif
}

- (void)modelWillBeginParsingRemoteKeyPath: (NSString *)remoteKeyPath
{
}

- (void)modelDidFinishParsingRemoteKeyPath: (NSString *)remoteKeyPath
{
}

+ (NSArray *)ignoredRemoteKeyPaths
{
	return nil;
}


@end