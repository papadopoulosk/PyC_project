//
//  LocationViewController.m
//  Thesis
//
//  Created by Lion User on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationViewController.h"

@interface LocationViewController ()

@end

@implementation LocationViewController
@synthesize _mapView;
-(id) init
{
     self = [super initWithNibName:nil bundle:Nil];
    
    if (self) {
        UITabBarItem *tbi = [self tabBarItem];
        [tbi setTitle:@"Map locator"];  
        UIImage* anImage = [UIImage imageNamed:@"tab-icon4.png"];
        [tbi setImage:anImage];
        myphone = [Device initialize];
        [myphone setMapDelegate:self];
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    //self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    //if (self) {
        // Custom initialization
    //}
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
- (void)viewWillAppear:(BOOL)animated 
{  
    [self updateRegion];
}
-(void) updateRegion
{
    // 1
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = [myphone getLat];
    zoomLocation.longitude= [myphone getLong];
    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance (zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    // 3
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];                
    // 4
    [_mapView setRegion:adjustedRegion animated:YES];  
}

@end
