#import "AppDelegate.h"
#import "FDGame.h"


#pragma mark Class Definition

@implementation AppDelegate
{
	@private __strong UIWindow *_mainWindow;
}


#pragma mark - UIApplicationDelegate Methods

- (BOOL)application: (UIApplication *)application 
	didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
	// Create the main window.
	UIScreen *mainScreen = [UIScreen mainScreen];
	
	_mainWindow = [[UIWindow alloc] 
		initWithFrame: mainScreen.bounds];
	
	_mainWindow.backgroundColor = [UIColor blackColor];
	
	// TODO: Create the root view controller for the main window.
	
	// Create a model object from a hardcoded JSON dictionary.
	NSDictionary *simulatedJSON = @{ 
		@"game_id" : @(22), 
		@"name" : @"Monster Hunter 4 Ultimate", 
		@"genre" : @"Action role-playing game", 
		@"release_date" : @"10-11-2014"
		};
	
	FDGame *game = [FDGame modelWithDictionary: simulatedJSON];
	NSLog(@"%@", game);
	
	// Show the main window.
	[_mainWindow makeKeyAndVisible];
	
	// Indicate success.
	return YES;
}

- (void)applicationWillResignActive: (UIApplication *)application
{
	// Pause ongoing tasks and disable timers.
}

- (void)applicationDidEnterBackground: (UIApplication *)application
{
	// Save application data, invalidate timers and store enough information to recover previous state if the application becomes active again.
}

- (void)applicationWillEnterForeground: (UIApplication *)application
{
	// Undo any changes that were made when the application entered the background.
}

- (void)applicationDidBecomeActive: (UIApplication *)application
{
	 // Restart tasks that were paused when the application resigned its active status.
}

- (void)applicationWillTerminate: (UIApplication *)application
{
	// Save application data and invalidate timers.
}

- (void)applicationDidReceiveMemoryWarning: (UIApplication *)application
{
	// Free up as much memory as possible by purging cached data or any other data that can be read back from disk.
}


#pragma mark - Private Methods


@end