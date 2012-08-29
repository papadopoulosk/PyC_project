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
    [self updateRegion:nil];
}
-(void) updateRegion:(NSDictionary *)safeZone
{
    //TODO: Fix code to add overlay with secure zone
    //if (safeZone!=nil){
        //CLLocationCoordinate2D  points[4];
        
        //points[0] = CLLocationCoordinate2DMake(41.000512, -109.050116);
        //points[1] = CLLocationCoordinate2DMake(41.002371, -102.052066);
        //points[2] = CLLocationCoordinate2DMake(36.993076, -102.041981);
        //points[3] = CLLocationCoordinate2DMake(36.99892, -109.045267);
        
        //MKPolygon* poly = [MKPolygon polygonWithCoordinates:points count:4];
        
        //[_mapView addOverlay:poly];    
    //}
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = [myphone getLat];
    zoomLocation.longitude= [myphone getLong];
    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance (zoomLocation, 3*METERS_PER_MILE, 3*METERS_PER_MILE);
    // 3
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];                
    // 4
    [_mapView setRegion:adjustedRegion animated:YES]; 
    
}
@end
