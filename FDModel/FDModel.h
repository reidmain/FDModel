#import <FDFoundationKit/FDFoundationKit.h>
#import "FDModelProvider.h"
#import "FDModelStore.h"
#import "FDArchivedFileModelStore.h"


#ifndef LOG_MISSING_EXPECTED_REMOTE_KEYS
    #define LOG_MISSING_EXPECTED_REMOTE_KEYS 0
#endif

#ifndef LOG_UNUSED_REMOTE_KEYS
    #define LOG_UNUSED_REMOTE_KEYS 0
#endif

#ifndef VERBOSE
    #define VERBOSE 0
#endif


#pragma mark Type Definitions

/**
@param identifier The identifier of the model to create.

@return Returns an instance of FDModel with the specified identifier. If that model cannot be created returns nil.
*/
typedef FDModel *(^FDModelInitBlock)(id identifier);

/**
When an instance of FDModel is initialized for the first time this block is called to give the opportunity to set default properties or perform any other first time initialization steps.

@param model The model that was just initialized.
*/
typedef void (^FDModelCustomizationBlock)(FDModel *model);


#pragma mark - Class Interface

/**
FDModel is an abstract model class that allows for easy creation from remote objects (i.e. NSDictionary, NSString, NSValue). Users only need to override the remoteKeyPathsToLocalKeyPaths method in their subclasses of FDModel to define what remote key paths map to local key paths and all of the parsing, transformation and setting of those local key paths are handled automatically. 

FDModel guarantees that if an instance of it is created with an identifier only one instance of that model will ever exist in memory at any given time. All instances of FDModel created with an identifier are stored in a weakly retained cache that ensures if an instance of FDModel is referenced by anything it will always exist in memory. During low memory situations this cache will be purged of models that are no longer retained by anything. To have this identifier automatically be set during the conversion process the remoteKeyPathForUniqueIdentifier method must be overrided.

FDModel provides the ability to transform an object just before it is set on a local key path. For example, if a subclass of FDModel has a property named 'status' and the user wants to transform the value that the remote key path resolves to they can implement a method named 'statusTransformer' that returns back a NSValueTransformer. This transformer will be automatically used whenever the status property is about to be set.

By default all FDModel objects are pesisted only in-memory. Model objects can be saved to a FDModelStore and any models that are saved to the model store and automatically read from the store if a model with the corresponding identifier is attempted to be created.
*/
@interface FDModel : NSObject<
	NSCoding,
	NSCopying>


#pragma mark - Properties

@property (nonatomic, readonly) id identifier;


#pragma mark - Constructors

/**
Creates or loads a model with the specified identifier.

@param identifier The identifier of the model being created.

@see initWithIdentifier:initBlock:customizationBlock:
*/
+ (instancetype)modelWithIdentifier: (id)identifier;

/**
Creates or loads a model with the specified dictionary.

This method uses the shared FDModelProvider instance to attempt to transform the dictionary into an instance of the class this method is called on.

@param dictionary The dictionary the model is being created from.
*/
+ (instancetype)modelWithDictionary: (NSDictionary *)dictionary;

/**
Returns an initialized model with the specified identifier.

This is the designated initializer for this class.

If an instance of the model with the specified identifier already exists in memory that model will be returned instead of the  object that this initializer was called on.

If the model does not exist in memory the initBlock will be called. If the initBlock returns a model it will be used otherwise the object this method was called on will be initialized. Finally the model will then be passed onto the customizationBlock.

@param identifier The identifier of the model being initialized.
@param initBlock The block to call if a model with the specified identifier does not exist in memory. This parameter may be nil.
@param customizationBlock The block to call on the model after the initBlock has been called. This block should be used to set the defaults of any properties of the model. This parameter may be nil.

@return Returns either a model from the model store or a brand new mem
*/
- (instancetype)initWithIdentifier: (id)identifier 
	initBlock: (FDModelInitBlock)initBlock 
	customizationBlock: (FDModelCustomizationBlock)initializerBlock;

/**
Returns an initialized model with the specified identifier.

This initializer may not return the same object that it was called on if a model with the specified identifier already exists in the model store.

@param identifier The identifier of the model being initialized.

@see initWithIdentifier:initBlock:customizationBlock:
*/
- (instancetype)initWithIdentifier: (id)identifier;

/**
Creates a shallow copy of the object. Any properties that reference objects will use the memory semantics defined by that property, strong will own, copy will copy, etc.

@param zone Ignored.

@return Returns a copy of the object.
*/
- (id)copyWithZone: (NSZone *)zone;


#pragma mark - Static Methods

/**
Returns the key path that will be used to retrieve the identifier from the object that is being used to create a instance of this FDModel.
*/
+ (NSString *)remoteKeyPathForUniqueIdentifier;

/**
Returns a dictionary mapping remote key paths on the object being used to populate the FDModel to local key paths of the properties being set.
*/
+ (NSDictionary *)remoteKeyPathsToLocalKeyPaths;

/**
Looks up the value transformer for the specified key.

This method will usually never be called directly and should most likely never be subclassed. Instead implement a method named '+<key>Transformer' and this method will automatically look it up.

@return Returns the value transformer that should be used to transform the remote object for the specified key. If no transform should occur return nil.
*/
+ (NSValueTransformer *)transformerForKey: (NSString *)key;

/**
Determines which class a NSDictionary should be parsed into.

The method behaves almost identically to FDDataClientModelClassBlock whereas the block is usually scoped to a specific request this method is only for key paths that are being parsed by this FDModel subclass.

@param dictionary The dictionary that the FDModel is being populated with.
@param value The key on the dictionary that is about to be parsed.

@return Return a FDModel subclass if the value can be parsed into an instance of that subclass. Return nil if the value does not map to a FDModel subclass. Return NSNull if the value is 'invalid' or 'bad' in some way and should not be parsed at all.

@see FDDataClientModelClassBlock
*/
+ (Class)modelClassForDictionary: (NSDictionary *)dictionary 
	withRemoteKeyPath: (NSString *)remoteKeyPath;

/**
Returns the recursive lock that is used to ensure the creation, modification and encoding of FDModel objects can only occur on a single thread at any given time.
*/
+ (NSRecursiveLock *)modificationLock;

/**
Sets the model store that will be used to back all FDModels.

By default FDModel uses FDArchivedFileModelStore.

@see FDModelStore
*/
+ (void)setModelStore: (FDModelStore *)modelStore;

/**
Queries the existing instances of this model for an instance with the specified identifier.

@param identifier The identifier with which to query for an existing instance.

@return Returns either an instance of the model with the specified identifier, or nil if no instance with the identifier exists.
*/
+ (instancetype)existingModelWithIdentifier: (id)identifier;

/**
Returns a new array containing all of the instances of the model that FDModel is currently tracking.
*/
+ (NSArray *)existingModels;


#pragma mark - Instance Methods

/**
Attempts to save the model to the model store.

This method uses the modification lock so it could take a long amount of time to complete and therefore should never be called on the UI thread.

@return Returns YES if the model was successfully saved to the model store otherwise NO.

@see saveAsynchronously
*/
- (BOOL)save;

/**
Attempts to save the model to the model store in a background thread.
*/
- (void)saveAsynchronously;

/**
Attempts to delete the model from the model store.

This method uses the modification lock so it could take a long amount of time to complete and therefore should never be called on the UI thread.

@return Returns YES if the model was successfully deleted from the model store otherwise NO.
*/
- (BOOL)delete;

/**
Attempts to delete the model from the model store in a background thread.
*/
- (void)deleteAsynchronously;


#pragma mark - Debug Methods

/// -----------
/// @name Debug
/// -----------

/**
Notifies the model that it is about to begin parsing the specified remote object.

This method will only be called when the DEBUG preprocessor macro is active.
*/
- (void)modelWillBeginParsingRemoteObject: (NSDictionary *)remoteObject;

/**
Notifies the model that it has finished parsing the specified remote object.

This method will only be called when the DEBUG preprocessor macro is active.
*/
- (void)modelDidFinishParsingRemoteObject: (NSDictionary *)remoteObject;

/**
Notifies the model that it is about to begin parsing the specified remote key path.

This method will only be called when the DEBUG preprocessor macro is active.
*/
- (void)modelWillBeginParsingRemoteKeyPath: (NSString *)remoteKeyPath;

/**
Notifies the model that it has finished parsing the specified remote key path.

This method will only be called when the DEBUG preprocessor macro is active.

By default this method validates a remote object against the expected response and logs the difference. Useful for identifying missing and unused keys.

To log missing keys build with LOG_MISSING_EXPECTED_REMOTE_KEYS preprocessor macro.
To log unused keys build with LOG_UNUSED_REMOTE_KEYS preprocessor macro.
*/
- (void)modelDidFinishParsingRemoteKeyPath: (NSString *)remoteKeyPath;

/**
Returns an array of keys to ignore when validating the expected response.

To log these ignored keys build with VERBOSE preprocessor macro.
*/
+ (NSArray *)ignoredRemoteKeyPaths;


@end