#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"
#import "XMLparserViewController.h"
#import "DeviceViewController.h"
#import "LocationViewController.h"
#import "FilesViewController.h"

#import "KeychainWrapper.h"
#import "Constants.h"

#import "CryptoHelper.h"

@class Reachability;


@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    Reachability *internetReachable;
    bool connectivity;
    NSArray *viewControllers;
    IBOutlet UITabBarController *tabBarController;
}
@property (nonatomic) BOOL pinValidated;
@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (assign, nonatomic) bool connectivity;

- (void) reachabilityChanged: (NSNotification* )note;

@end
