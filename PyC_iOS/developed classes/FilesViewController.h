//
//  FilesViewController.h
//  Thesis
//
//  Created by Lion User on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "DetailsViewController.h"

@interface FilesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableDictionary *fileTypes;
    NSDictionary *tableImages;
    NSMutableArray *fileLists;
    UITableView *filesTable;
    NSString *rootPath;
    NSString *filePath;
    NSString *sharedPath;
    UINavigationController *navBar;
}
@property (assign) IBOutlet UITableView *filesTable;
@property (assign) IBOutlet UINavigationController *navBar;

-(IBAction)refreshFiles;
-(void) scanFiles;
-(UIViewController *) initWithNavigationBar:(UINavigationController *)aNavBar;
-(void) createFile;
-(void) deleteFile:(NSString *)file;
@end
