#import "AppDelegate.h"
#import "FDGame.h"
#import <FDModel/FDModelProvider.h>


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
	
	// Load and parse the games.json file in an operation queue a large number of times to test multiple threads creating the same objects.
	NSOperationQueue *operationQueue = [NSOperationQueue new];
	
	for (int i=0; i < 100; i++)
	{
		[operationQueue addOperationWithBlock: ^
			{
				NSBundle *mainBundle = [NSBundle mainBundle];
				NSURL *url = [mainBundle URLForResource: @"games" 
					withExtension: @"json"];
				NSData *data = [NSData dataWithContentsOfURL: url];
				
				id gamesJSON = [NSJSONSerialization JSONObjectWithData: data 
					options: NSJSONReadingAllowFragments 
					error: nil];
				
				FDModelProvider *modelProvider = [FDModelProvider sharedInstance];
				[modelProvider parseObject: gamesJSON 
					modelClassBlock: ^Class(NSString *parentKey, id value)
						{
							Class modelClass = nil;
							if (parentKey == nil)
							{
								return [FDGame class];
							}
							
							return modelClass;
						}];
				
				NSLog(@"Finished %d", i);
			}];
	}
	
	[operationQueue waitUntilAllOperationsAreFinished];
	
	// Show the main window.
	[_mainWindow makeKeyAndVisible];
	
	// Indicate success.
	return YES;
}


#pragma mark - Private Methods


@end