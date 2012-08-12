#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"
#import "XMLparserViewController.h"
#import "DeviceViewController.h"
#import "LocationViewController.h"


@class Reachability;


@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    Reachability *internetReachable;
    bool connectivity;
    NSArray *viewControllers;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (assign, nonatomic) bool connectivity;

- (void) reachabilityChanged: (NSNotification* )note;

@end
