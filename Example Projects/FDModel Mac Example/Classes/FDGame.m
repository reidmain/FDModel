#import "FDGame.h"


#pragma mark Class Definition

@implementation FDGame


#pragma mark - Overridden Methods

+ (NSString *)remoteKeyPathForUniqueIdentifier
{
	return @"game_id";
}

+ (NSDictionary *)remoteKeyPathsToLocalKeyPaths
{
	FDGame *game = nil;
	
	NSDictionary *remoteKeyPathsToLocalKeyPaths = @{
		@"name" : @keypath(game.name), 
		@"genre" : @keypath(game.genre), 
		@"release_date" : @keypath(game.releaseDate)
		};
	
	return remoteKeyPathsToLocalKeyPaths;
}

+ (NSValueTransformer *)releaseDateTransformer
{
	FDValueTransformer *releaseDateTransformer = [FDValueTransformer registerTransformerWithName: @"ReleaseDateTransformer" 
		block: ^id(id value)
		{
			NSDateFormatter *dateFormatter = [NSDateFormatter new];
			dateFormatter.dateFormat = @"MM-dd-yyyy";
			
			NSDate *releaseDate = [dateFormatter dateFromString: value];
			
			return releaseDate;
		}];
	
	return releaseDateTransformer;
}

- (NSString *)description
{
	NSString *description = [NSString stringWithFormat: @"<%@: %p; id = %@; name = %@; genre = %@; release date = %@>", 
		[self class], 
		self, 
		self.identifier, 
		_name, 
		_genre, 
		_releaseDate];
	
	return description;
}


@end