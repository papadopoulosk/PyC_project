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
    NSString *sharedPath;
    NSMutableDictionary *fileArchive;
   
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
    
    SecKeyRef publicKey;
    SecKeyRef privateKey;
    NSData *publicTag;
    NSData *privateTag;
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
-(NSData *) encryptSingleFile:(NSString *)file atpath:(NSString *)path;

-(void) deactivateControls; //Method called to deactivate all controls everytime policy is updated
-(void) timerFireMethod:(NSTimer*)theTimer;

-(void) onTimeTrigger:(NSTimer *)timer;
-(void) gpsController:(NSDictionary *) restrictions;
-(float) getLong;
-(float) getLat;

-(void) checkTime;
-(void) timeController:(NSDictionary *)restrictions;

-(void) requestPolicy;

- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer;
- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer;
- (SecKeyRef)getPublicKeyRef;
- (SecKeyRef)getPrivateKeyRef;
- (void)testAsymmetricEncryptionAndDecryption;
- (void)generateKeyPair:(NSUInteger)keySize;

@end
