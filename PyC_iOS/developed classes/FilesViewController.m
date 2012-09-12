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
@synthesize filesTable, navBar;

-(UIViewController*) initWithNavigationBar:(UINavigationController *)aNavBar{
    navBar = aNavBar;
    
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:Nil bundle:Nil];
    if (self) {
        staticExtensions = [[NSArray arrayWithObjects:@"png",@"jpg",@"pdf",@"ppt",@"doc",@"xls",@"pptx",@"docx",@"xlsx", nil] retain];
        
        rootPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] retain];
        filePath = [[NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]] retain];
        sharedPath = [[NSString stringWithString:[rootPath stringByAppendingString:@"/Shared/"]] retain];
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
    
    //Create Left top button
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [backButton setImage:[UIImage imageNamed:@"refresh.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(refreshFiles) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *refresh =[[UIBarButtonItem alloc] initWithCustomView:backButton];
    navBar.navigationBar.topItem.leftBarButtonItem = refresh;
    
    //Create Right top button
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createFile)];
    navBar.navigationBar.topItem.rightBarButtonItem = addButton;
}
-(void) viewDidAppear:(BOOL)animated
{
    [self refreshFiles];
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

    UIView *button = [[UIButton alloc] init];
    button = navBar.navigationBar.topItem.leftBarButtonItem.customView;
    [[button layer] addAnimation:fullRotation forKey:@"transform.rotation"];
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *arrayFromFile = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:filePath error:nil]];
    NSMutableArray *arrayFromSharedFile = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:sharedPath error:nil]];
    int filesCounter = 0;
    for (NSMutableString *file in arrayFromFile){
        if ( [fileTypes valueForKey:[[file lastPathComponent] pathExtension]]==nil){
            NSMutableArray *specificFileType = [[NSMutableArray arrayWithObject:file] retain];
            [fileTypes setObject:specificFileType forKey:[[file lastPathComponent] pathExtension]];
            filesCounter++;
        } else {
            [[fileTypes objectForKey:[[file lastPathComponent] pathExtension]] addObject:file];
            filesCounter++;
        }
    }
    [fileTypes setObject:arrayFromSharedFile forKey:@"Shared"];
    self.title = @"Repository";
}
#pragma mark Table delegate 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger) [[fileTypes allKeys] count]; 
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *specificFileTypeList = [fileTypes objectForKey: [[fileTypes allKeys] objectAtIndex:section]];
    return (NSInteger) [specificFileTypeList count]; 
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *specificFileTypeList = [fileTypes objectForKey: [[fileTypes allKeys] objectAtIndex:[indexPath section]]];
    NSString *contentForThisRow = [specificFileTypeList objectAtIndex:[indexPath row]];
    
    static NSString *CellIdentifier = @"CellIdentifier";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        // Do anything that should be the same on EACH cell here.  Fonts, colors, etc.
    }
    // Do anything that COULD be different on each cell here.  Text, images, etc.
    [cell.textLabel setText:contentForThisRow];
	return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
    NSString *image =  [[fileTypes allKeys] objectAtIndex:section];
    if (![image isEqualToString:@"Shared"]){
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
    } else {
        return nil;
    }    
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *image =  [[fileTypes allKeys] objectAtIndex:section];
    if ([image isEqualToString:@"Shared"])
    {        
        return @"Shared Files";
    }
    else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 30;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *file0 = [NSString stringWithString:[[[tableView cellForRowAtIndexPath:indexPath] textLabel] text]];
    if (![[[fileTypes allKeys] objectAtIndex:[indexPath section]] isEqualToString:@"Shared"]){
        //Not shared file
        DetailsViewController *detailsViewController = [[DetailsViewController alloc] initWithNibName:@"DetailsViewController" file:[filePath stringByAppendingString:file0]];
        [self.navBar pushViewController:detailsViewController animated:TRUE];
        [detailsViewController release];
    } else {
        //File that has been shared
        if([staticExtensions containsObject:[file0 pathExtension]]) {
            [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
            DetailsViewController *detailsViewController = [[DetailsViewController alloc] initWithStaticFile:@"DetailsViewController" file:[sharedPath stringByAppendingString:file0]];
            [self.navBar pushViewController:detailsViewController animated:TRUE];
            [detailsViewController release];
        } else {
            [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
            DetailsViewController *detailsViewController = [[DetailsViewController alloc] initWithSharedFile:@"DetailsViewController" file:[sharedPath stringByAppendingString:file0]];
            [self.navBar pushViewController:detailsViewController animated:TRUE];
            [detailsViewController release];
        }
    }
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        if([[[fileTypes allKeys] objectAtIndex:[indexPath section]] isEqualToString:@"Shared"]) {
          [self deleteFile:[sharedPath stringByAppendingString:[[[tableView cellForRowAtIndexPath:indexPath] textLabel] text]]];  
        }else {
            [self deleteFile:[filePath stringByAppendingString:[[[tableView cellForRowAtIndexPath:indexPath] textLabel] text]]];
        }
    }    
}
-(void) createFile
{
    DetailsViewController *detailsViewController = [[DetailsViewController alloc] initNewFileWithNibName:@"DetailsViewController"];
    [self.navBar pushViewController:detailsViewController animated:TRUE];
    [detailsViewController release];

}
-(void) deleteFile:(NSString *)file
{
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr removeItemAtPath:file error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    [self refreshFiles];
}
@end
