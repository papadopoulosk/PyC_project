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
#import <Security/Security.h>
#import "CryptoHelper.h"
#import "KeychainWrapper.h"

#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import "AmazonClientManager.h"
#import "NSData+Base64.h"

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

@interface Device : NSObject <CLLocationManagerDelegate, NSXMLParserDelegate, AmazonServiceRequestDelegate>
{
    CTCarrier *mycarrier;
    CTTelephonyNetworkInfo *netInfo;
    NSMutableDictionary *information;
    NSString *rootPath;
    NSString *logPath;
    NSString *filePath;
    NSString *sharedPath;
    NSMutableDictionary *fileArchive;
    NSArray *staticExtensions;
   
    CLLocationManager *locMgr;
    id delegate, mapDelegate, xmlviewDelegate;
    Device *mydevice;
    
    NSDictionary *locationLimit;
    NSTimer *eraseTimer;
    NSTimer *gpsTimer;
    
#pragma mark Variables to define delete or restore.
    enum status {toRestore, toDelete, undefined};
    enum fileStatus {restored, deleted, uncertain};
    enum status gpsStatus;
    enum status timeFrameStatus;
    enum fileStatus files;
    
    NSDictionary *timelimit;
    
    int lastFile,verifyLastFile;
    BOOL sharedFile;
    
    NSData *publicTag;
    SecKeyRef publicKeyRef;
    /*SecKeyRef privateKey;
    NSData *publicTag;
    NSData *privateTag;*/
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
-(void) wipeOrRestoreData;
-(void) restoreFiles;
-(void) startIndicators;
-(void) stopIndicators;
-(void) encryptAllSharedFiles;
-(NSData *) encryptSingleFile:(NSString *)file atpath:(NSString *)path withType:(BOOL)isString;

-(void) deactivateControls; //Method called to deactivate all controls everytime policy is updated
-(void) timerFireMethod:(NSTimer*)theTimer;

-(void) onTimeTrigger:(NSTimer *)timer;
-(void) gpsController:(NSDictionary *) restrictions;
-(float) getLong;
-(float) getLat;

-(void) checkTime;
-(void) timeController:(NSDictionary *)restrictions;

-(void) requestPolicy;

-(NSData *)stripPublicKeyHeader:(NSData *)d_key;
-(BOOL)addPublicKey:(NSString *)key withTag:(NSString *)tag;

@end
