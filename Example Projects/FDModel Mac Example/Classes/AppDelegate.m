#import "AppDelegate.h"
#import "FDGame.h"


#pragma mark Class Definition

@implementation AppDelegate


#pragma mark - NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
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
				NSArray *games = [modelProvider parseObject: gamesJSON 
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
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
	return YES;
}


@end