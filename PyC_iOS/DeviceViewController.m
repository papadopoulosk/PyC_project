//
//  DeviceViewController.m
//  Thesis
//
//  Created by Lion User on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeviceViewController.h"


@implementation DeviceViewController 
@synthesize labelsArray, listData, mytable;
 - (id)init
{
    self = [super initWithNibName:Nil bundle:Nil];
    if (self) {
        UITabBarItem *tbi = [self tabBarItem];
        UIImage* anImage = [UIImage imageNamed:@"tab-icon3.png"];
        [tbi setImage:anImage];
        [tbi setTitle:@"Device"];
        myphone = [Device initialize];
        [myphone setDelegate:self];
        
        myindicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        myindicator.center = CGPointMake(300, 365);
        [myindicator setColor:[UIColor blackColor]];
        [self.view addSubview:myindicator];
    }
    return self;
}
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    int i=0;
    for (UILabel *lab in labelsArray)
        [lab setHidden:TRUE];
    //for (id key in [d allKeys]) {
    //    NSLog(@"%@ - %@",key,[d objectForKey:key]);
    //}
    
    for (id key in [myphone getInfo])
    {
        [[labelsArray objectAtIndex:i] setText:[NSString stringWithFormat:@"%@: %@",[key description],[[myphone getInfo] objectForKey:key]]];
        //[[labelsArray objectAtIndex:i] setHidden:false];
        [[labelsArray objectAtIndex:i] setTextColor:[UIColor whiteColor]];
        i++;
    }	
    [super viewDidLoad];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
-(void) dealloc
{
    [listData dealloc];
    [myphone release];
    [super dealloc];
}
-(IBAction)logBut
{
    [myphone log];
}
-(IBAction)uploadLog
{
  //  [myphone uploadFiles];
    //[myphone uploadLog];
    [myphone restoreFiles];
    
}

-(void) locationUpdate:(CLLocation *)location
{
    [self viewDidLoad];
    mytable.hidden=true;
}
-(void) locationError:(NSError *)error
{
    
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return (NSInteger) [[[myphone getInfo] allKeys] count];
    //return [self.listData count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    //Create instance of a UITableViewCell with default appearance
    //UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"] autorelease];
    //set the text on the cell with the description of the item
    //[[cell textLabel] setText:@"asd"];
    //return cell;
    
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SimpleTableIdentifier] autorelease];
    }
    NSUInteger row = [indexPath row];
    cell.detailTextLabel.text = [[myphone getInfo] objectForKey:[[[myphone getInfo] allKeys] objectAtIndex:row]];

    cell.textLabel.text = [[[myphone getInfo] allKeys] objectAtIndex:row];
    return cell;
}
-(void) startIndicator
{
    [myindicator startAnimating];
}
-(void) stopIndicator
{
    [myindicator stopAnimating];
}
@end