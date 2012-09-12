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

-(void)createDummyCoordinates{
    
    pinsCoordinates = [NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:@"37.77544", @"-122.408527", nil],
                        [NSArray arrayWithObjects:@"37.78044", @"-122.408627", nil],
                        [NSArray arrayWithObjects:@"37.77044", @"-122.408727", nil],
                        [NSArray arrayWithObjects:@"37.77044", @"-122.415727", nil],
                        nil];
    for(NSArray *point in pinsCoordinates){
        GpsPins *pin1 = [[GpsPins alloc] init];
        [pin1 setCoordinate:CLLocationCoordinate2DMake([[point objectAtIndex:0] doubleValue], [[point objectAtIndex:1] doubleValue])];
        [_mapView addAnnotation:pin1];
        [pin1 release];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //GpsPins *pin1 = [[GpsPins alloc] init];
    //[pin1 setCoordinate:CLLocationCoordinate2DMake(37.77544, -122.408427)];
    //[_mapView addAnnotation:pin1];
    [self createDummyCoordinates];
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
