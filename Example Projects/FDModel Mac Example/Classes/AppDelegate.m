#import "AppDelegate.h"
#import "FDGame.h"


#pragma mark Class Definition

@implementation AppDelegate


#pragma mark - NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
	// Create a model object from a hardcoded JSON dictionary.
	NSDictionary *simulatedJSON = @{ 
		@"game_id" : @(22), 
		@"name" : @"Monster Hunter 4 Ultimate", 
		@"genre" : @"Action role-playing game", 
		@"release_date" : @"10-11-2014"
		};
	
	FDGame *game = [FDGame modelWithDictionary: simulatedJSON];
	NSLog(@"%@", game);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
	return YES;
}


@end