@import Foundation;


#pragma mark Forward Declarations

@class FDModel;


#pragma mark - Class Interface

/**
FDModelStore is an abstract class you use to encapasulate the storage and retrieval of FDModel objects.

FDArchivedFileModelStore is a library-defined concrete subclass of FDModelStore.

@see FDArchivedFileModelStore
*/
@interface FDModelStore : NSObject


#pragma mark - Instance Methods

/**
Attempts to retrieve a model from the model store with the specified identifier.

@param The identifier of the model being queried.

@return Returns the model if it exists otherwise nil.
*/
- (FDModel *)modelForIdentifier: (id)identifier;

/**
Attempts to save the model to the model store.

@param The model to save to the model store.

@return Returns YES if the model was successfully saved to the model store otherwise NO.
*/
- (BOOL)saveModel: (FDModel *)model;


@end