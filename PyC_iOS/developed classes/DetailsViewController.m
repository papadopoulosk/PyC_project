//
//  DetailsViewController.m
//  Thesis
//
//  Created by Lion User on 8/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailsViewController.h"

@interface DetailsViewController ()

@end
@implementation DetailsViewController
@synthesize fileView;
-(id) initWithNibName:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay
{
    isNewFile=false;
    isSharedFile = false;
    file = [[NSString stringWithString:fileToDisplay] retain];
    error = false;
    return [self initWithNibName:nibNameOrNil bundle:nil];    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(id)initNewFileWithNibName:(NSString *)nibNameOrNil
{
    isNewFile = true;
    isSharedFile = false;
    error = false;
    return [self initWithNibName:nibNameOrNil bundle:nil];    
}
-(id)initWithSharedFile:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay
{
    isSharedFile = true;
    isNewFile=false;
    error = false;
    file = [[NSString stringWithString:fileToDisplay] retain];
    return [self initWithNibName:nibNameOrNil bundle:nil]; 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (isNewFile){
        UIAlertView *enterTitleMsg = [[UIAlertView alloc] initWithTitle:@"New file" message:@"Enter name"  delegate: self cancelButtonTitle:@"Cancel" otherButtonTitles: @"Ok", nil];
        UITextField *nameField = [[UITextField alloc] 
                                  initWithFrame:CGRectMake(20.0, 45.0, 245.0, 25.0)];
        [nameField setBackgroundColor:[UIColor whiteColor]];
        [enterTitleMsg addSubview:nameField];
        enterTitleMsg.tag = 1001;
        nameField.tag=1002;
        [nameField release];
        //[enterTitleMsg setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [enterTitleMsg show];
        [enterTitleMsg release];  
    } else {
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:file];
        if (fileExists) {
            //Retrieve the key that corresponds to the file
            NSString *key=nil;
            if ([KeychainWrapper keychainStringFromMatchingIdentifier:[file lastPathComponent]]){
                key = [NSString stringWithString:[KeychainWrapper keychainStringFromMatchingIdentifier:[file lastPathComponent]]];
            } else {
                key = [NSString stringWithString:@""];
            }
            //Decrypt file using the key
            NSString *text = [NSString stringWithString:
                              [[CryptoHelper sharedInstance] 
                               decryptString:[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] 
                               withKey:key
                               andIV:nil]];
            [self.navigationController.topViewController setTitle:[file lastPathComponent]];
            
            [fileView setText:text];
            //[fileView setText:[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]];
        }else {
        [fileView setText:@"File does not exist"];
        error=true;
        }
        
    }
    
    UIImage *buttonImage = [UIImage imageNamed:@"locked.png"];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:buttonImage style:UIBarButtonItemStylePlain target:self action:@selector(unlockText)];          
    self.navigationItem.rightBarButtonItem = editButton;

    
}
-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (!error && file!=nil){
        
        //Get date to use as KEY and IV
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        [dateFormatter release];
        //Compute KEY
        NSString *key = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:dateString] substringWithRange:NSMakeRange(0, 16)]];
        //Store KEY to the keyChain
        [KeychainWrapper createKeychainValue:key forIdentifier:[file lastPathComponent]];
       
        if (!isSharedFile) {
            NSData *fileToWrite = [[[CryptoHelper sharedInstance] encryptString:[fileView text] withKey:key andIV:nil] dataUsingEncoding:NSUTF8StringEncoding]; 
            [fileToWrite writeToFile:file options:NSDataWritingFileProtectionComplete error:nil]; 
            
        } else {
            
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]];
            NSString *fileName = [[NSString stringWithString:filePath] stringByAppendingString:[file lastPathComponent]];
                       
            NSData *fileToWrite =[[[CryptoHelper sharedInstance] 
                                   encryptString:[fileView text] 
                                   withKey:key 
                                   andIV:nil] 
                                  dataUsingEncoding:NSUTF8StringEncoding];
            [fileToWrite writeToFile:fileName options:NSDataWritingFileProtectionComplete error:nil]; 
        }
        NSLog(@"Symmetric key used: %@", key);
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
-(void) unlockText
{
    UIImage *buttonImage = [UIImage imageNamed:@"unlocked.png"];
    
    [self.navigationItem.rightBarButtonItem setImage:buttonImage];
    [self.navigationItem.rightBarButtonItem setAction:@selector(lockText)];
    [fileView setEditable:true];
}
-(void) lockText
{
    UIImage *buttonImage = [UIImage imageNamed:@"locked.png"];
    
    [self.navigationItem.rightBarButtonItem setImage:buttonImage];
    [self.navigationItem.rightBarButtonItem setAction:@selector(unlockText)];
    [fileView setEditable:false];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{       
    if (alertView.tag==1001){
        if (buttonIndex==1){
           UITextField* textField = (UITextField*)[alertView viewWithTag:1002];
            if (textField.text==nil)
                textField.text=@"NoName";
            [self.navigationController.topViewController setTitle:textField.text];
            
            NSString *rootPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] retain];
            NSString *filePath = [[NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]] retain];
            
            NSData *newFile = [NSData dataWithData:[[NSString stringWithString:@""] dataUsingEncoding:NSUTF8StringEncoding]];
            [newFile writeToFile:[filePath stringByAppendingString:textField.text] options:NSDataWritingFileProtectionComplete error:nil];
            file = [[filePath stringByAppendingString:textField.text] retain];
            
        } else {
            file = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}
@end
