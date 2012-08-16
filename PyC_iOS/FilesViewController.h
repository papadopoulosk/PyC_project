//
//  FilesViewController.h
//  Thesis
//
//  Created by Lion User on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@interface FilesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableDictionary *fileTypes;
    NSDictionary *tableImages;
    NSMutableArray *fileLists;
    UITableView *filesTable;
    UIButton *refreshButton;
}
@property (assign) IBOutlet UITableView *filesTable;
@property (assign) IBOutlet UIButton *refreshButton;

-(IBAction)refreshFiles;
-(void) scanFiles;
@end
