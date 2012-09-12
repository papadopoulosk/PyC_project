//
//  XMLparserViewController.h
//  Thesis
//
//  Created by Lion User on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuartzCore/QuartzCore.h"
#import "Device.h"

@interface XMLparserViewController : UIViewController <NSXMLParserDelegate, busyIndicatorDelegate,UITableViewDataSource, UITableViewDelegate>
{
    //NSXMLParser *myparser;
    UITextView *textView;
    UILabel *mylabel;
    NSNumber *depth;
    NSMutableString *output;
    NSString *rootPath;
    NSString *dictPath,*dictPath2;
    NSString *filePath;
    int errors,counter;
    UIActivityIndicatorView *myindicator;
    UIButton *updatePolicyButton;
    NSMutableArray *sectionTitles; // table that holds the policy in array format in order to display the table on view
    NSMutableDictionary *sectionContent;//
    //NSURL *xmlUrl;
    UITableView *mytable;
    NSDictionary *policyTags;
}
@property (assign) IBOutlet UITextView *textView;
@property (assign) IBOutlet UILabel *mylabel;
@property (assign) IBOutlet UIButton *updatePolicyButton;
@property (assign) IBOutlet UITableView *mytable;

-(IBAction)updatePolicy;
-(void) newPolicy:(NSString *)newDoc;
-(IBAction)unarchive;
-(IBAction)clearAll;

-(void) archieveXML:(NSString *) content withTitle:(NSString *)title;
-(NSMutableDictionary *) retrieveArchive;
-(NSString *) getXMLbyKey:(NSString *) key;
-(NSArray *) returnKeys;

@end
