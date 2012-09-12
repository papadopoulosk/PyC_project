//
//  DeviceViewController.h
//  Thesis
//
//  Created by Lion User on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Device.h"

#import "AmazonClientManager.h"

@interface DeviceViewController : UIViewController <CoreLocationControllerDelegate, UITableViewDataSource, UITableViewDelegate, busyIndicatorDelegate>
{
    NSArray *labelsArray;
    Device *myphone;
    NSArray *listData;
    UITableView *mytable;
    UIActivityIndicatorView *myindicator;
}
@property (assign) IBOutlet UITableView *mytable;
@property (nonatomic, retain) NSArray *listData;
@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray *labelsArray;
-(IBAction)logBut;
-(IBAction)uploadLog;
@end
