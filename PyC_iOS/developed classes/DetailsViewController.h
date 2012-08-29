//
//  DetailsViewController.h
//  Thesis
//
//  Created by Lion User on 8/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CryptoHelper.h"
#import "KeychainWrapper.h"
#import "Constants.h"

@interface DetailsViewController : UIViewController <UIAlertViewDelegate>
{
    NSString *file;
    IBOutlet UITextView *fileView;
    BOOL error;
    BOOL isNewFile;
    BOOL isSharedFile;
}
@property (retain) IBOutlet UITextView *fileView;
-(id)initWithNibName:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay;
-(id)initNewFileWithNibName:(NSString *)nibNameOrNil;
-(id)initWithSharedFile:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay;
-(void) unlockText;
-(void) lockText;
@end
