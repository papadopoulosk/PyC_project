#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window , connectivity;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIImage* tabBarBackground = [UIImage imageNamed:@"tabbar.png"];
    [[UITabBar appearance] setBackgroundImage:tabBarBackground];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"selection-tab.png"]];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    [navController.topViewController setTitle:@"Protect your Company v0.5"];
    
    
    UIViewController *xmlvc = [[XMLparserViewController alloc] init];
    UIViewController *devicevc = [[DeviceViewController alloc] init];
    UIViewController *locationvc = [[LocationViewController alloc] init];
   
    viewControllers = [NSArray arrayWithObjects:xmlvc, devicevc,locationvc, nil];
   
    for (UIViewController *viewItem in viewControllers)
    {
        //UIColor *background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"background.jpg"]];
        UIColor *background = [UIColor colorWithRed:0.5 green:0.6 blue:0.7 alpha:0.4];
        viewItem.view.backgroundColor = background;
        //[background release];
    }
    
    [xmlvc release];
    [devicevc release];
    [locationvc release];

    [tabBarController setViewControllers:viewControllers];
    //[[self window] setRootViewController:tabBarController];
    [[self window] setRootViewController:navController];
    [tabBarController release];
    
    [self.window makeKeyAndVisible];
    
    //Initialization of internet connectivity variable
    [self reachabilityChanged:NULL];
    
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    [internetReachable startNotifier];
     
    /*UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    //if (localNotif == nil) return;
    NSDate *fireTime = [[NSDate date] addTimeInterval:10]; // adds 10 secs
    localNotif.fireDate = fireTime;
    localNotif.alertBody = @"Alert!";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    [localNotif release];*/    
    
    return YES;
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
    // called after network status changes
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {

        case NotReachable:
        {
            NSLog(@"The internet is down.");
            [self setConnectivity:false];
            [[viewControllers objectAtIndex:0] unarchive ];
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"The internet is working via WIFI.");
            [self setConnectivity:true];
            [[viewControllers objectAtIndex:0] updatePolicy];
            break;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            [self setConnectivity:true];
            [[viewControllers objectAtIndex:0] updatePolicy];
            break;
        }
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
/*
- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MyAlertView"
                                                        message:@"Local notification was received"
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    if (alertView) {
        [alertView release];
    }
}
 */

@end
