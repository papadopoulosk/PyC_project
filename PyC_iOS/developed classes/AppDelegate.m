#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window , connectivity;
@synthesize pinValidated;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //If policy and files directories exist. If not, then create them
    NSArray *folders = [NSArray arrayWithObjects:@"/Files/", @"/Policy/",@"/Shared", nil];
    for (NSString *dir in folders) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSFileManager *NSFm= [NSFileManager defaultManager]; 
        if(![NSFm fileExistsAtPath:[documentsDirectory stringByAppendingString:dir] isDirectory:nil])
            if(![NSFm createDirectoryAtPath:[documentsDirectory stringByAppendingString:dir] withIntermediateDirectories:NO attributes:nil error:NO])
                NSLog(@"Error: Create folder failed");
    }
    
    //Create Tabbar menu
    UIImage* tabBarBackground = [UIImage imageNamed:@"tabbar.png"];
    [[UITabBar appearance] setBackgroundImage:tabBarBackground];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"selection-tab.png"]];
    
    //UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController = [[UITabBarController alloc] init];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    [navController.topViewController setTitle:@"Protect your Company v0.5"];
    [navController setNavigationBarHidden:true];
      
    UIViewController *xmlvc = [[XMLparserViewController alloc] init];
    UIViewController *devicevc = [[DeviceViewController alloc] init];
    UIViewController *locationvc = [[LocationViewController alloc] init];
    UINavigationController *navBar = [[UINavigationController alloc] init];
    UIViewController *filesvc = [[FilesViewController alloc] initWithNavigationBar:navBar];
    [navBar addChildViewController:filesvc];
    [navBar.navigationController.topViewController setTitle:@"Repository"];
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStylePlain target:self action:@selector(refreshPropertyList:)];
    navBar.navigationBar.topItem.rightBarButtonItem =  anotherButton;
    [anotherButton release];
    //[navBar setDelegate:filesvc];
    //UINavigationController *filesvc = [[FilesViewController alloc] init];
    
    viewControllers = [NSArray arrayWithObjects:navBar, xmlvc, devicevc,locationvc, nil];
   
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
        [self.window setHidden:true];
    
    
    //self.pinValidated = NO;
    //[self presentAlertViewForPassword];
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
            [[viewControllers objectAtIndex:1] unarchive ];
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"The internet is working via WIFI.");
            [self setConnectivity:true];
            [[viewControllers objectAtIndex:1] updatePolicy];
            break;
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            [self setConnectivity:true];
            [[viewControllers objectAtIndex:1] updatePolicy];
            break;
        }
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game
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
    [self.window setHidden:true];
    self.pinValidated = NO;
    [self presentAlertViewForPassword];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)presentAlertViewForPassword 
{
    
    // 1
    BOOL hasPin = [[NSUserDefaults standardUserDefaults] boolForKey:PIN_SAVED];
    
    // 2
    if (hasPin) {
        // 3
        NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME];
        NSString *message = [NSString stringWithFormat:@"What is %@'s password?", user];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter Password" 
                                                        message:message  
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Done", nil];
        // 4
        [alert setAlertViewStyle:UIAlertViewStyleSecureTextInput]; // Gives us the password field
        alert.tag = kAlertTypePIN;
        // 5
        UITextField *pinField = [alert textFieldAtIndex:0];
        pinField.delegate = self;
        pinField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        pinField.tag = kTextFieldPIN;
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Setup Credentials" 
                                                        message:@"Secure your Files list!"  
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Done", nil];
        // 6
        [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        alert.tag = kAlertTypeSetup;
        UITextField *nameField = [alert textFieldAtIndex:0];
        nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        nameField.placeholder = @"Name"; // Replace the standard placeholder text with something more applicable
        nameField.delegate = self;
        nameField.tag = kTextFieldName;
        UITextField *passwordField = [alert textFieldAtIndex:1]; // Capture the Password text field since there are 2 fields
        passwordField.delegate = self;
        passwordField.tag = kTextFieldPassword;
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    if (alertView.tag == kAlertTypePIN) {
        if (buttonIndex == 1 && self.pinValidated) { // User selected "Done"
            //[self performSegueWithIdentifier:@"ChristmasTableSegue" sender:self];
            [self.window setHidden:false];
            self.pinValidated = NO;
        } else { // User selected "Cancel"
            [self presentAlertViewForPassword];
        }
    } else if (alertView.tag == kAlertTypeSetup) {
        if (buttonIndex == 1 && [self credentialsValidated]) { // User selected "Done"
           // [self performSegueWithIdentifier:@"ChristmasTableSegue" sender:self];
        } else { // User selected "Cancel"
            [self presentAlertViewForPassword];
        }
    }
}
-(BOOL) credentialsValidated
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:USERNAME];
    BOOL pin = [[NSUserDefaults standardUserDefaults] boolForKey:PIN_SAVED];
    if (name && pin) {
        return YES;
    } else {
        return NO;
    }
}
#pragma mark - Text Field + Alert View Methods
- (void)textFieldDidEndEditing:(UITextField *)textField 
{
    // 1
    switch (textField.tag) {
        case kTextFieldPIN: // We go here if this is the 2nd+ time used (we've already set a PIN at Setup).
            NSLog(@"User entered PIN to validate");
            if ([textField.text length] > 0) {
                // 2
                NSUInteger fieldHash = [textField.text hash]; // Get the hash of the entered PIN, minimize contact with the real password
                // 3
                if ([KeychainWrapper compareKeychainValueForMatchingPIN:fieldHash]) { // Compare them
                    NSLog(@"** User Authenticated!!");
                    self.pinValidated = YES;
                } else {
                    NSLog(@"** Wrong Password :(");
                    self.pinValidated = NO;
                }
            }
            break;
        case kTextFieldName: // 1st part of the Setup flow.
            NSLog(@"User entered name");
            if ([textField.text length] > 0) {
                [[NSUserDefaults standardUserDefaults] setValue:textField.text forKey:USERNAME];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            break;
        case kTextFieldPassword: // 2nd half of the Setup flow.
            NSLog(@"User entered PIN");
            if ([textField.text length] > 0) {
                NSUInteger fieldHash = [textField.text hash];
                // 4
                NSString *fieldString = [KeychainWrapper securedSHA256DigestHashForPIN:fieldHash];
                NSLog(@"** Password Hash - %@", fieldString);
                // Save PIN hash to the keychain (NEVER store the direct PIN)
                if ([KeychainWrapper createKeychainValue:fieldString forIdentifier:PIN_SAVED]) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PIN_SAVED];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSLog(@"** Key saved successfully to Keychain!!");
                }                
            }
            break;
        default:
            break;
    }
}
@end
