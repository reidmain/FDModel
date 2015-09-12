@import Foundation;


#pragma mark - Forward Declarations

@class FDModel;


#pragma mark - Class Interface

/**
FDModelStore is an abstract class you use to encapasulate the storage and retrieval of FDModel objects.

FDArchivedFileModelStore is a library-defined concrete subclass of FDModelStore.

@see FDArchivedFileModelStore
*/
@interface FDModelStore : NSObject


#pragma mark - Properties

/**
A recursive lock to be used by concrete subclasses to ensure only a single thread is using the model store at a time.
*/
@property (nonatomic, readonly) NSRecursiveLock *modificationLock;


#pragma mark - Instance Methods

/**
Attempts to retrieve a model from the model store with the specified identifier.

@param identifier The identifier of the model being queried.
@param modelClass The class of the model to be retrieved.

@return Returns the model if it exists otherwise nil.
*/
- (FDModel *)modelForIdentifier: (id)identifier 
	withClass: (Class)modelClass;

/**
Attempts to save the model to the model store.

@param model The model to save to the model store.

@return Returns YES if the model was successfully saved to the model store otherwise NO.
*/
- (BOOL)saveModel: (FDModel *)model;

/**
Attempts to delete the model from the model store.

@param model The model to delete from the model store.

@return Returns YES if the model was successfully deleted from the model store otherwise NO.
*/
- (BOOL)deleteModel: (FDModel *)model;


@end