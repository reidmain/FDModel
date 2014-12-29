#import "FDArchivedFileModelStore.h"
#import "FDModel.h"
#import <FDFoundationKit/FDFoundationKit.h>


#pragma mark Class Extension

@interface FDArchivedFileModelStore ()

- (NSString *)_modelFilePathForIdentifier: (id)identifier;

@end


#pragma mark - Class Definition

@implementation FDArchivedFileModelStore


#pragma mark - Overridden Methods

- (FDModel *)modelForIdentifier: (id)identifier
{
	FDModel *model = nil;

	NSString *modelFilePath = [self _modelFilePathForIdentifier: identifier];
	if (modelFilePath != nil)
	{
		[self.modificationLock lock];
		
		model = [NSKeyedUnarchiver unarchiveObjectWithFile: modelFilePath];
		
		[self.modificationLock unlock];
	}

	return model;
}

- (BOOL)saveModel: (FDModel *)model
{
	NSString *modelFilePath = [self _modelFilePathForIdentifier: model.identifier];
	
	[self.modificationLock lock];
	
	BOOL saveSuccessful = [NSKeyedArchiver archiveRootObject: model 
		toFile: modelFilePath];
	
	[self.modificationLock unlock];
	
	return saveSuccessful;
}

- (BOOL)deleteModel: (FDModel *)model
{
	NSString *modelFilePath = [self _modelFilePathForIdentifier: model.identifier];
	
	[self.modificationLock lock];
	
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	BOOL deleteSuccessful = [defaultFileManager removeItemAtPath: modelFilePath 
		error: nil];
	
	[self.modificationLock unlock];
	
	return deleteSuccessful;
}


#pragma mark - Private Methods

- (NSString *)_modelFilePathForIdentifier: (id)identifier
{
	// If no identifier was passed in a file path cannot be generated.
	if (FDIsEmpty(identifier) == YES)
	{
		return nil;
	}
	
	// Get the path for the cache directory.
	NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSAllDomainsMask, YES);
	NSString *systemCacheFolderPath = [cacheDirectories firstObject];
	NSString *cacheFolderPath = [systemCacheFolderPath stringByAppendingPathComponent: @"FDModel Cache"];
	
	// Ensure the cache directory has been created.
	NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	[defaultFileManager createDirectoryAtPath: cacheFolderPath 
		withIntermediateDirectories: YES 
		attributes: nil 
		error: nil];
	
	// Concatenate the class and identifier together to ensure different classes that use the same identifier do not collide.
	NSString *fullIdentifier = [NSString stringWithFormat: @"%@-%@", 
		[self class], 
		identifier];
	
	// Hash the full identifier to ensure there are no / in the file name.
	NSString *hashedIdentifier = [fullIdentifier sha256HashString];
	
	// Create the file name for the model from the hash and append it to the cache directory path.
	NSString *modelFileName = [NSString stringWithFormat: @"%@.plist", 
		hashedIdentifier];
	NSString *modelFilePath = [cacheFolderPath stringByAppendingPathComponent: modelFileName];
	
	return modelFilePath;
}


@end