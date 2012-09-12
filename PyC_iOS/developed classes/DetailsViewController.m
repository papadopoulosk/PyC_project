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
@synthesize fileView, webView;
-(id) initWithNibName:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay
{
    isNewFile=false;
    isSharedFile = false;
    isStaticFile = false;
    file = [[NSString stringWithString:fileToDisplay] retain];
    return [self initWithNibName:nibNameOrNil bundle:nil];    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self addGestureControllers];
        error = false;
        randomNumber = nil;
        gestures = [[NSMutableString stringWithString:@""] retain];
    }
    return self;
}
-(id)initNewFileWithNibName:(NSString *)nibNameOrNil
{
    isNewFile = true;
    isSharedFile = false;
    isStaticFile = false;
    return [self initWithNibName:nibNameOrNil bundle:nil];    
}
-(id)initWithSharedFile:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay
{
    isSharedFile = true;
    isNewFile=false;
    isStaticFile = false;
   
    file = [[NSString stringWithString:fileToDisplay] retain];
    return [self initWithNibName:nibNameOrNil bundle:nil]; 
}
-(id)initWithStaticFile:(NSString *)nibNameOrNil file:(NSString *)fileToDisplay
{
    isStaticFile = true;
    isSharedFile = false;
    isNewFile = false;
    
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
            NSString *iv=nil;
            if ([KeychainWrapper keychainStringFromMatchingIdentifier:[[file lastPathComponent] stringByAppendingString:@"key"]] && [KeychainWrapper keychainStringFromMatchingIdentifier:[[file lastPathComponent] stringByAppendingString:@"iv"]]){
                key = [NSString stringWithString:[KeychainWrapper keychainStringFromMatchingIdentifier:[[file lastPathComponent] stringByAppendingString:@"key"]]];
                iv = [NSString stringWithString:[KeychainWrapper keychainStringFromMatchingIdentifier:[[file lastPathComponent] stringByAppendingString:@"iv"]]];
            } else {
                key = [NSString stringWithString:@""];
                iv = [NSString stringWithString:@""];
            }
            
            if (isStaticFile){
                [webView setHidden:false];
                [fileView setHidden:true];
                //Decrypt data using the key
                NSData *decryptedFile = [NSData dataWithData:[[CryptoHelper sharedInstance] decryptData:[NSData dataWithContentsOfFile:file] 
                                                                                                withKey:key 
                                                                                                  andIV:iv ]];
                [decryptedFile writeToFile:file options:NSDataWritingFileProtectionNone error:nil];
                NSURL *targetURL = [NSURL fileURLWithPath:file];
                NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
                [webView loadRequest:request];
            } else {
                //Decrypt file using the key
                NSString *text = [NSString stringWithString:
                                  [[CryptoHelper sharedInstance] 
                                   decryptString:[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] 
                                   withKey:key
                                   andIV:iv]];
                [self.navigationController.topViewController setTitle:[file lastPathComponent]];
                
                [fileView setText:text];
                
            }
        }else {
        [fileView setText:@"File does not exist"];
        error=true;
        }
        
    }
    if (isStaticFile){
        self.navigationItem.rightBarButtonItem=nil; 
    } else {
        UIImage *buttonImage = [UIImage imageNamed:@"locked.png"];
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:buttonImage style:UIBarButtonItemStylePlain target:self action:@selector(unlockText)];          
        self.navigationItem.rightBarButtonItem = editButton;
    }
    
    
}
-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (!error && file!=nil){
        //Compute KEY
        NSArray *encryptionCredentials = [NSArray arrayWithArray:[self generateKeyAndIv]];
        //Store KEY to the keyChain
        NSString *key = [encryptionCredentials objectAtIndex:0];
        NSString *iv = [encryptionCredentials objectAtIndex:1];
        [KeychainWrapper createKeychainValue:key forIdentifier:[[file lastPathComponent] stringByAppendingString:@"key"]];
        [KeychainWrapper createKeychainValue:iv forIdentifier:[[file lastPathComponent] stringByAppendingString:@"iv"]];
        if (!isStaticFile) {
            if (!isSharedFile) {
                NSData *fileToWrite = [[[CryptoHelper sharedInstance] encryptString:[fileView text] withKey:key andIV:iv] dataUsingEncoding:NSUTF8StringEncoding]; 
                [fileToWrite writeToFile:file options:NSDataWritingFileProtectionComplete error:nil]; 
            } else {
                NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]];
                NSString *fileName = [[NSString stringWithString:filePath] stringByAppendingString:[file lastPathComponent]];
                
                NSData *fileToWrite =[[[CryptoHelper sharedInstance] 
                                       encryptString:[fileView text] 
                                       withKey:key 
                                       andIV:iv] 
                                      dataUsingEncoding:NSUTF8StringEncoding];
                [fileToWrite writeToFile:fileName options:NSDataWritingFileProtectionComplete error:nil]; 
            }
        } else {
            NSData *fileToWrite = [[CryptoHelper sharedInstance] encryptData:[NSData dataWithContentsOfFile:file] withKey:key andIV:iv]; 
            [fileToWrite writeToFile:file options:NSDataWritingFileProtectionComplete error:nil]; 
        }
                NSLog(@"Symmetric key used: %@, IV used : %@", key, iv);
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
-(void) addGestureControllers
{
    UITapGestureRecognizer *fingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    fingerTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:fingerTap];
    [fingerTap release];
    
    UISwipeGestureRecognizer *swipeTap = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [self.view addGestureRecognizer:swipeTap];
    [swipeTap release];

    UISwipeGestureRecognizer *swipeTap2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeTap2.direction=UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeTap2];
    [swipeTap2 release];
    
    UISwipeGestureRecognizer *swipeTap3 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeTap3.direction=UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeTap3];
    [swipeTap3 release];
    
    UISwipeGestureRecognizer *swipeTap4 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeTap4.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeTap4];
    [swipeTap4 release];
    
    UIPinchGestureRecognizer *fingerPinch = 
    [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(fingerPinch:)] autorelease];
    [[self view] addGestureRecognizer:fingerPinch];
    
    UIRotationGestureRecognizer *fingersRotate = 
    [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(fingersRotate:)] autorelease];
    [[self view] addGestureRecognizer:fingersRotate];
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

#pragma mark Gesture Recognition methods
- (void)handleTap:(UIGestureRecognizer *)sender 
{   
    CGPoint tapPoint = [sender locationInView:sender.view.superview];
    NSString *temp = [NSString stringWithFormat:@"%d,%d", (int) tapPoint.x, (int) tapPoint.y]; 
    [gestures appendString:temp];
}
-(void)handleSwipe:(UIGestureRecognizer *)sender {
   CGPoint point = [sender locationInView:[self view]];
    NSString *temp = [NSString stringWithFormat:@"%d,%d", (int) point.x, (int) point.y]; 
    [gestures appendString: temp];
}
- (void)fingersRotate:(UIRotationGestureRecognizer *)recognizer {
    NSString *temp = [NSString stringWithFormat:@"%f", [recognizer rotation] * (180 / M_PI)]; 
    [gestures appendString: temp];
}
- (void)fingerPinch:(UIPinchGestureRecognizer *)recognizer {
    NSString *temp = [NSString stringWithFormat:@"%f", recognizer.scale]; 
    [gestures appendString: temp];
}
#pragma mark Key and IV generation
-(NSArray *) generateKeyAndIv {
    
    //Get date to use as KEY and IV
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    
    NSString *fullText = [[[NSString stringWithString:gestures] stringByAppendingString:dateString] stringByAppendingString:[self generateRandomNumberMaxValue:999999]];
    
     //Compute KEY
    NSString *key = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:fullText] substringWithRange:NSMakeRange(0, 16)]];
    NSString *iv = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:fullText] substringWithRange:NSMakeRange(16, 16)]];
    
    NSArray *encryptionCredentials =[NSArray arrayWithObjects:key,iv, nil];
   return encryptionCredentials;
}
-(NSString *) generateRandomNumberMaxValue:(int) max{
    int number = (arc4random()%max)+1; //Generates Number from 1 to 100.
    NSString *string = [NSString stringWithFormat:@"%i", number];
    return string;
}
@end
