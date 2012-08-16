//
//  FilesViewController.m
//  Thesis
//
//  Created by Lion User on 8/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FilesViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface FilesViewController ()

@end

@implementation FilesViewController
@synthesize filesTable, refreshButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:Nil bundle:Nil];
    if (self) {
        tableImages = [[NSDictionary 
                       dictionaryWithObjects:[NSArray arrayWithObjects:@"archive.png",@"css.png",@"pdf.png",@"exml.png",@"rar.png",@"word.png",@"text.png",@"zip.png",@"ppt.png",@"excel.png",@"javascript.png",nil]
                       forKeys:[NSArray arrayWithObjects:@"arc",@"css",@"pdf",@"xml",@"rar",@"doc",@"txt",@"zip",@"ppt",@"xls",@"js",nil]] retain];
        UITabBarItem *tbi = [self tabBarItem];
        UIImage* anImage = [UIImage imageNamed:@"file.png"];
        [tbi setImage:anImage];
        [tbi setTitle:@"Files"];
        
        fileLists = nil;
        fileTypes = nil;
        [self scanFiles];
    }
    return self;

}
-(void) dealloc
{
    
    [fileLists release];
    [fileTypes release];
    [tableImages release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
-(IBAction)refreshFiles
{
    CABasicAnimation *fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    [fullRotation setFromValue:[NSNumber numberWithFloat:0]];
    [fullRotation setToValue:[NSNumber numberWithFloat:((360*M_PI)/180)]];
    [fullRotation setDuration:0.5f];
    
    [[refreshButton layer] addAnimation:fullRotation forKey:@"transform.rotation"];
    [self scanFiles];
    [filesTable reloadData];
}
-(void) scanFiles
{
    if (fileTypes ==nil) {
        fileTypes = [[NSMutableDictionary alloc] init];
    } else {
        [fileTypes release];
        fileTypes = [[NSMutableDictionary alloc] init];
    }
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrayFromFile = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    
    for (NSMutableString *file in arrayFromFile){
        if ( [fileTypes valueForKey:[[file lastPathComponent] pathExtension]]==nil){
            NSMutableArray *specificFileType = [[NSMutableArray arrayWithObject:file] retain];
            [fileTypes setObject:specificFileType forKey:[[file lastPathComponent] pathExtension]];
        } else {
            [[fileTypes objectForKey:[[file lastPathComponent] pathExtension]] addObject:file];
        }
        //NSMutableArray *testAr = [fileTypes objectForKey:[[file lastPathComponent] pathExtension]]; 
       // NSLog(@"TEST: %i , %@", [testAr count], [testAr objectAtIndex:0]); 
    }

}
#pragma mark Table delegate 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger) [[fileTypes allKeys] count];
    //return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *specificFileTypeList = [fileTypes objectForKey: [[fileTypes allKeys] objectAtIndex:section]];
    return (NSInteger) [specificFileTypeList count]; 
    //NSString *key = [fileTypes objectAtIndex:section];
    //NSArray *keys = [[sectionContent objectForKey:key] allKeys];
    //NSInteger rows = [keys count];
    //return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *specificFileTypeList = [fileTypes objectForKey: [[fileTypes allKeys] objectAtIndex:[indexPath section]]];
    // NSString *key = [sectionTitles objectAtIndex:[indexPath section]];
    // NSDictionary *contents = [sectionContent objectForKey:key];
    
    // NSString *contentForThisRow = [contents objectForKey:[[contents allKeys] objectAtIndex:[indexPath row]]];
    NSString *contentForThisRow = [specificFileTypeList objectAtIndex:[indexPath row]];
    
    static NSString *CellIdentifier = @"CellIdentifier";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        // Do anything that should be the same on EACH cell here.  Fonts, colors, etc.
    }
	
    // Do anything that COULD be different on each cell here.  Text, images, etc.
    //[cell.textLabel setText:[[contents allKeys] objectAtIndex:[indexPath row]]];
    [cell.textLabel setText:contentForThisRow];
	//cell.imageView.image = [UIImage imageNamed:@"css.png"];
    //[cell.detailTextLabel setText:@"detailtest"];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
    NSString *image =  [[fileTypes allKeys] objectAtIndex:section];
    UIImage *myImage = nil;
    if ([tableImages objectForKey:image]!=NULL) {
        myImage = [UIImage imageNamed:[tableImages objectForKey:image]];
    } else {
        myImage = [UIImage imageNamed:@"unknown.png"];
    }
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:myImage] autorelease];
	imageView.frame = CGRectMake(10,10,30,30);
    UIView *headerView = [[[UIView alloc] init] autorelease];
    [headerView addSubview:imageView];
	return headerView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 30;
}


@end
