//
//  Device.h
//  Thesis
//
//  Created by Lion User on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreTelephony/CTCarrier.h"
#import "CoreTelephony/CTTelephonyNetworkInfo.h"
#import "CoreLocation/CoreLocation.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SystemUtilities.h"

@protocol CoreLocationControllerDelegate <NSObject>
@required
-(void) locationUpdate:(CLLocation *) location; //location updates are sent here
-(void) locationError:(NSError *) error; // any errors are sent here
@end

@protocol MapDelegate <NSObject>
@required
-(void) updateRegion;
@end

@protocol busyIndicatorDelegate <NSObject>
@required
-(void) startIndicator;
-(void) stopIndicator;

@end

@interface Device : NSObject <CLLocationManagerDelegate, NSXMLParserDelegate>
{
    CTCarrier *mycarrier;
    CTTelephonyNetworkInfo *netInfo;
    NSMutableDictionary *information;
    NSString *rootPath;
    NSString *logPath;
    NSString *filePath;
    NSMutableDictionary *fileArchive;
   
    CLLocationManager *locMgr;
    id delegate, mapDelegate, xmlviewDelegate;
    Device *mydevice;
    
    NSDictionary *locationLimit;
    NSTimer *eraseTimer;
    NSTimer *gpsTimer;
    enum status {restored, deleted, neutral};
    enum status infoStatus;
    
    int lastFile,verifyLastFile;
}
@property (nonatomic, retain) CLLocationManager *locMgr;
@property (nonatomic, assign) id delegate, mapDelegate, xmlviewDelegate;

+(Device*)initialize;
-(NSMutableDictionary *) getInfo;

-(void) log;
-(void) uploadLog;
-(void) uploadFiles;
-(void) archiveFilesToDict;
-(void) wipeData;
-(void) restoreFiles;
-(void) startIndicators;
-(void) stopIndicators;
/*
-(void) generateKeyPairPlease;
-(void) encryptWithPublicKey;
-(void) decryptWithPrivateKey;
*/
-(void) onTimeTrigger:(NSTimer *)timer;
-(void) gpsController:(NSDictionary *) restrictions;
-(void) deactivateControls; //Method called to deactivate all controls everytime policy is updated
-(void) timerFireMethod:(NSTimer*)theTimer;
-(float) getLong;
-(float) getLat;

-(void) requestPolicy;
@end
