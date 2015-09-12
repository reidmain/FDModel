#import "FDModelStore.h"

#import "FDModel.h"


#pragma mark - Class Definition

@implementation FDModelStore


#pragma mark - Constructors

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

- (FDModel *)modelForIdentifier: (id)identifier 
	withClass: (Class)modelClass
{
	return nil;
}

- (BOOL)saveModel: (FDModel *)model
{
	return NO;
}

- (BOOL)deleteModel:(FDModel *)model
{
	return NO;
}


@end