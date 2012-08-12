//
//  LocationViewController.h
//  Thesis
//
//  Created by Lion User on 7/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Device.h"

#define METERS_PER_MILE 1609.344

@interface LocationViewController : UIViewController <MapDelegate>
{
    MKMapView *_mapView;
    Device *myphone;
}
@property (weak, nonatomic) IBOutlet MKMapView *_mapView;
-(void) updateRegion;
@end