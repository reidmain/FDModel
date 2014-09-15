# Overview
FDModel is an Objective-C model layer designed to greatly simplify the process of creating model objects from remote objects (i.e. NSDictionary, NSString, NSValue). Users only need to override the remoteKeyPathsToLocalKeyPaths method in their subclasses of FDModel to define what remote key paths map to local key paths and all of the parsing, transformation and setting of those local key paths are handled automatically. 

Another major benefit of FDModel is that it guarantees that if an instance of FDModel is created with an identifier only one instance of that model will ever exist in memory at any given time. To automate this process users need only override the remoteKeyPathForUniqueIdentifier method in their subclass. All instances of FDModel created with an identifier are stored in a weakly retained cache that ensures if an instance of FDModel is referenced by anything it will always exist in memory. During low memory situations this cache will be purged of models that are no longer retained by anything. To have this identifier automatically be set during the conversion process the remoteKeyPathForUniqueIdentifier method must be overrided.

FDModel also provides the ability to transform an object just before it is set on a local key path. For example, if a subclass of FDModel has a property named 'status' and the user wants to transform the value that the remote key path resolves to they can implement a method named 'statusTransformer' that returns back a NSValueTransformer. This transformer will be automatically used whenever the status property is about to be set.

By default all FDModel objects are pesisted only in-memory. Model objects can be saved to a FDModelStore and any models that are saved to the model store and automatically read from the store if a model with the corresponding identifier is attempted to be created.

# Installation
There are two supported methods for FDModel. Both methods assume your Xcode project is using modules.

### 1. Subprojects
1. Add the "FDModel" project inside the "Framework Project" directory as a subproject or add it to your workspace.
2. Add "FDModel (iOS/Mac)" to the "Target Dependencies" section of your target.
3. Use "@import FDModel" inside any file that will be using FDModel.

### 2. CocoaPods
Simply add `pod "FDModel", "~> 1.0.0"` to your Podfile.

# Example
Here is a simple example of the implementation details of a "game" model object. This project includes both iOS and Mac example projects which show how to actually create an instance of this game object from a NSDictionary.

FDGame.h

	@interface FDGame : FDModel


	@property (nonatomic, copy) NSString *name;
	@property (nonatomic, copy) NSString *genre;
	@property (nonatomic, copy) NSDate *releaseDate;


	@end

FDGame.m

	@implementation FDGame


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
