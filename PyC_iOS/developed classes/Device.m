//
//  Device.m
//  Thesis
//
//  Created by Lion User on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "Device.h"
const size_t BUFFER_SIZE = 64;
const size_t CIPHER_BUFFER_SIZE = 1024;
const uint32_t PADDING = kSecPaddingNone;
//static const UInt8 publicKeyIdentifier[] = "com.apple.sample.publickey";
//static const UInt8 privateKeyIdentifier[] = "com.apple.sample.privatekey";

@implementation Device
@synthesize locMgr, delegate, mapDelegate, xmlviewDelegate;

#if DEBUG
#define LOGGING_FACILITY(X, Y)  \
NSAssert(X, Y); 

#define LOGGING_FACILITY1(X, Y, Z)  \
NSAssert1(X, Y, Z); 
#else
#define LOGGING_FACILITY(X, Y)  \
if (!(X)) {         \
NSLog(Y);       \
}                   

#define LOGGING_FACILITY1(X, Y, Z)  \
if (!(X)) {             \
NSLog(Y, Z);        \
}                       
#endif

static Device *mydevice = nil;

#pragma mark Standard functions
+ (Device*)initialize {
    if (mydevice == nil) {
        mydevice = [[super allocWithZone:NULL] init];
    }
    return mydevice;
}
+ (id)allocWithZone:(NSZone *)zone {
    return [[self initialize] retain];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}
- (void)release {
    //do nothing
}
- (id)autorelease {
    return self;
}
-(id)init {
    self = [super init];
    
    if (self !=nil) {
        self.locMgr = [[[CLLocationManager alloc] init] autorelease];
        self.locMgr.delegate = self; 
        [self.locMgr stopUpdatingLocation];
        locationLimit = nil;
        timelimit = nil;
        eraseTimer=nil;
        netInfo = [[CTTelephonyNetworkInfo alloc] init];
        mycarrier = [netInfo subscriberCellularProvider];
        information = [[NSMutableDictionary alloc] init];
        gpsStatus = undefined;
        timeFrameStatus = undefined;
        files = uncertain;
        fileArchive = nil;
        gpsTimer = nil;
        lastFile = 0;
        verifyLastFile = 0;
        sharedFile = false;
        
        staticExtensions = [[NSArray arrayWithObjects:@"png",@"jpg",@"pdf",@"ppt",@"doc",@"xls",@"pptx",@"docx",@"xlsx", nil] retain];
    
        rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/Files/"]];
        logPath = [NSString stringWithString:[filePath stringByAppendingString:@""]];
        sharedPath = [NSString stringWithString:[rootPath stringByAppendingString:@"/Shared/"]];
        
        [logPath retain];
        [rootPath retain];
        [filePath retain];
        [sharedPath retain];
    
        [information setObject:[SystemUtilities getUniqueIdentifier] forKey:@"Unique Identifier"];
        [information setObject:[SystemUtilities getSystemUptime] forKey:@"System Uptime"];
        [information setObject:[SystemUtilities getModel] forKey:@"Model"];
        [information setObject:[SystemUtilities getIPAddress] forKey:@"IP Address"];
        [information setObject:[SystemUtilities netmaskForWifi] forKey:@"Netmask For Wifi"];
        [information setObject:[SystemUtilities getBatteryLevelInfo] forKey:@"Battery Level Info"];
        [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.latitude] forKey:@"Latitude"];
        [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.longitude] forKey:@"Longitute"];
        [information setObject:[SystemUtilities getRealDeviceType ] forKey:@"Real device type"];
        [information setObject:[NSString stringWithString:@"Vodafone"] forKey:@"Carrier name"];
    }
    return self;
}
- (void)dealloc {
    [self.locMgr release];
    [netInfo release];
    [mycarrier release];
    [information release];
    [fileArchive release];
    [mapDelegate release];
    [xmlviewDelegate release];
    [delegate release];
    [super dealloc];
}
-(void)log {
    [information writeToFile:[logPath stringByAppendingString:@"log.arc"] atomically:YES];
    //NSArray *arrayFromFile = [NSArray arrayWithContentsOfFile:logPath];
    //for (NSString *element in arrayFromFile) 
    //    NSLog(@"Data: %@", element);
    
    //NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:logPath];
    //for (id key in [dict allKeys])
    //{
    //    NSLog(@"Key: %@, info: %@", [key description], [dict objectForKey:key]);
    //}

    
    NSString *temp =[[NSString alloc] init];
    temp = [information description];
    [temp retain];
    //NSLog(@"%@", [logPath stringByAppendingString:@"log.arc"]);
    NSData *encryptedLogFile = [self encryptSingleFile:@"log.arc" atpath:logPath withType:true];
    [encryptedLogFile writeToFile:[logPath stringByAppendingString:@"log.arc"] options:NSDataWritingFileProtectionComplete error:nil];
    
    }
-(NSMutableDictionary *) getInfo {
    return information;
}
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self.locMgr stopUpdatingLocation];
    
    //Reverse Geolocation
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            NSLog(@"Your are in %@",[placemark locality]);
            NSLog(@"Next check in %@ secs", [locationLimit objectForKey:@"freq"]);
            NSLog(@"-------------------------------");
        }    
    }]; 
    
    if (locationLimit !=nil) {
        if (newLocation.coordinate.latitude < [[locationLimit objectForKey:@"NElat"] floatValue] && newLocation.coordinate.latitude>[[locationLimit objectForKey:@"SWlat"] floatValue] && newLocation.coordinate.longitude < [[locationLimit objectForKey:@"NElng"] floatValue] && newLocation.coordinate.longitude > [[locationLimit objectForKey:@"SWlng"] floatValue] )
        
        {//Inside the limits of the Safe zone                        
            if (eraseTimer !=nil) {
                // Stop timer:
                 if ([eraseTimer isValid])
                    [eraseTimer invalidate];
                gpsStatus =  undefined;
                eraseTimer = nil;
                NSLog(@"Delete countdown canceled!");
            }
            if (gpsStatus != toRestore ){
                NSLog(@"to restore is gps status");
                [self wipeOrRestoreData];
            }
        } else {
            //Out of limits alert!
            NSLog(@"Out of limits!");
            if (eraseTimer==nil) {
                gpsStatus = toDelete;
                NSLog(@"To delete is gps status");
                eraseTimer = [NSTimer scheduledTimerWithTimeInterval:25.0 target:self selector:@selector(wipeOrRestoreData) userInfo:nil repeats:NO];
            }
            //[self wipeData];
        }
    }
    [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.latitude] forKey:@"Latitude"];
    [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.longitude] forKey:@"Longitute"];
    
    [delegate locationUpdate:newLocation];
    [mapDelegate updateRegion:locationLimit];
   
    gpsTimer = [NSTimer scheduledTimerWithTimeInterval:[[locationLimit objectForKey:@"freq"] doubleValue]                                target:self selector:@selector(onTimeTrigger:) userInfo:nil repeats:NO];
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}
-(void) uploadLog {
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/upload.php"]];
    [request setFile:logPath forKey:@"file"];
    [request setDelegate:self];
    [request setTimeOutSeconds:10.00000];
    [request setDidFailSelector:@selector(test)];
    [request startAsynchronous];
    [self startIndicators];
}
-(void) startIndicators {
    //[xmlviewDelegate startIndicator];
    //[delegate startIndicator];
}
-(void) stopIndicators {
    //[xmlviewDelegate stopIndicator];
    //[delegate stopIndicator];
}
-(void) test {
    NSLog(@"Fail selector test");
    [self stopIndicators];
}
#pragma mark Device and policy controls
-(void)timerFireMethod:(NSTimer*)theTimer {
    [self gpsController:nil];
}
-(void) deactivateControls {
    //NSLog(@"Everything is switched off due to Update");
    //Cancel GPS tracking
    if (gpsTimer!=nil) {
        [gpsTimer invalidate];
        gpsTimer=nil;
    }
    [self.locMgr stopUpdatingLocation];
    gpsStatus = undefined;
    //reset TimeFrame
    timeFrameStatus=undefined;
    
}
-(void) wipeOrRestoreData {
    NSLog(@"WipeOrRestore called - No action yet");
    if (gpsStatus != toDelete && timeFrameStatus != toDelete && files != restored){
        NSLog(@"Restore called");
        [self restoreFiles];
    }
    else if ( (gpsStatus == toDelete || timeFrameStatus == toDelete) && files != deleted) {
        NSLog(@"Wipe called");
        [self wipeData];
    }
    eraseTimer = nil;
}
-(void) wipeData {
    NSLog(@"Into Wipe data");
    NSFileManager *fileMgr = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
    NSError *error2 = nil;
    NSArray *directoryContents =[fileMgr contentsOfDirectoryAtPath:filePath error:&error];
    NSArray *directoryContents2 =[fileMgr contentsOfDirectoryAtPath:sharedPath error:&error2];
    int counter = 0;
    if (error == nil) {
            for (NSString *path in directoryContents) {
                counter++;
                NSString *fullPath = [filePath stringByAppendingPathComponent:path];
                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                if (!removeSuccess) {
                    NSLog(@"Error in clearing file");
                } else {
                    //NSLog(@"File deleted!");
                }
            }
        }
    if (error2 == nil) {
        int counter = 0;
        for (NSString *path in directoryContents2) {
            counter++;
            NSString *fullPath = [sharedPath stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                NSLog(@"Error in clearing file");
            } else {
                NSLog(@"File deleted!");
            }
        }
    }
    //Alert window
    if (counter > 0 ) {
        UIAlertView *dataWipeMessage = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Files deleted"  delegate: self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [dataWipeMessage show];
        [dataWipeMessage release];
    }
    files = deleted;
}
-(void) restoreFiles {
    [self startIndicators];
    
    //Operations to restore files from custom personal web server
    
    /*
    NSURL *url = [NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/requestFiles.php"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
    [request setDelegate:self];
    [request startAsynchronous];
    //[request startSynchronous];
    [request setDidFinishSelector:@selector(requestFilesFinished:)];
    [request setDidFailSelector:@selector(requestFilesFailed:)];
    */
    
    //Request username and user role
    ASIFormDataRequest *infoRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/getdeviceinfo.php"]];
    [infoRequest setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
    //[request setDelegate:self];
    //[request setDidFinishSelector:@selector(requestPolicyFinished:)];
    //[request setDidFailSelector:@selector(requestPolicyFailed:)];
    [infoRequest startSynchronous];
    NSError *error = [infoRequest error];
    if (!error){
        NSString *fullresponse = [NSString stringWithString:[infoRequest responseString]];
        NSArray *responseItems = [fullresponse componentsSeparatedByString:@"/"];
        NSLog(@"%@", [responseItems objectAtIndex:0]);
        NSLog(@"%@", [responseItems objectAtIndex:1]);
        
        if (![AmazonClientManager hasCredentials]) {
            NSLog(@"Creds not found");
        }
        else {
            Response *response = [AmazonClientManager validateCredentials];
            if (![response wasSuccessful]) {
                NSLog(@"CREDS not successful");
            }
            else {
                //Variables so as to know when downloading is completed
                lastFile = 0;
                verifyLastFile = 0;
                
                //Request shared list of files
                S3ListObjectsRequest *reqShared = [[S3ListObjectsRequest alloc] initWithName:@"pycthesis"];
                reqShared.prefix = [[NSString stringWithString:@"documents/shared/"] stringByAppendingString:[responseItems objectAtIndex:0]];
                //NSLog(@"%@", req.prefix);
                reqShared.requestTag=@"shared";
                S3ListObjectsResponse *respShared = [[AmazonClientManager s3] listObjects:reqShared];
                NSMutableArray* objectSummariesShared = [[NSArray arrayWithArray:respShared.listObjectsResult.objectSummaries] retain];  
                //NSString *remoteFilePath = [[NSString stringWithString:@"documents/shared/"] stringByAppendingString:[responseItems objectAtIndex:0]];
                for (int x = 0; x < [objectSummariesShared count]; x++) {
                    //Download files
                    if (x!=0){
                        lastFile++;
                        //NSLog(@"objectSummaries: %@",[objectSummariesShared objectAtIndex:x]);
                        //NSString *remoteFile = [[NSString stringWithString:[objectSummaries objectAtIndex:x]] retain];
                        //NSLog(@"Remote filE: %@", remoteFile);
                        S3GetObjectRequest *request = [[S3GetObjectRequest alloc] initWithKey:[[objectSummariesShared objectAtIndex:x]description] withBucket:@"pycthesis"];
                        request.requestTag = [[NSString stringWithString:@"shared/"] stringByAppendingString:[[[objectSummariesShared objectAtIndex:x]description] lastPathComponent]];  
                        //NSLog(@"Request tag is: %@", request.requestTag);
                        [request setDelegate:self];                    
                        S3GetObjectResponse *downloadResponse = [[AmazonClientManager s3] getObject:request];
                    }   
                }
                
                //Request personal list of files
                S3ListObjectsRequest *reqPersonal = [[S3ListObjectsRequest alloc] initWithName:@"pycthesis"];
                reqPersonal.prefix = [[NSString stringWithString:@"documents/users/"] stringByAppendingString:[responseItems objectAtIndex:1]];
                //NSLog(@"%@", req.prefix);
                reqPersonal.requestTag=@"users";
                S3ListObjectsResponse *resp = [[AmazonClientManager s3] listObjects:reqPersonal];
                NSMutableArray* objectSummariesPersonal = [[NSArray arrayWithArray:resp.listObjectsResult.objectSummaries] retain];  
                //NSString *remoteFilePath = [[NSString stringWithString:@"documents/shared/"] stringByAppendingString:[responseItems objectAtIndex:0]];
                for (int x = 0; x < [objectSummariesPersonal count]; x++) {
                    //Download files
                    if (x!=0){
                        lastFile++;
                        //NSLog(@"objectSummaries: %@",[objectSummariesPersonal objectAtIndex:x]);
                        //NSString *remoteFile = [[NSString stringWithString:[objectSummaries objectAtIndex:x]] retain];
                        //NSLog(@"Remote filE: %@", remoteFile);
                        S3GetObjectRequest *request = [[S3GetObjectRequest alloc] initWithKey:[[objectSummariesPersonal objectAtIndex:x]description] withBucket:@"pycthesis"];
                        request.requestTag = [[NSString stringWithString:@"users/"] stringByAppendingString:[[[objectSummariesPersonal objectAtIndex:x]description] lastPathComponent]];  
                        //NSLog(@"Request tag is: %@", request.requestTag);
                        [request setDelegate:self];                    
                        S3GetObjectResponse *downloadResponse = [[AmazonClientManager s3] getObject:request];
                    }
            }
            }
        }
    }
}
-(void) uploadFiles {
    //[self generateKeyPair:128];
    //[self testAsymmetricEncryptionAndDecryption];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrayFromFile = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    [self startIndicators];

    if (![AmazonClientManager hasCredentials]) {
        NSLog(@"Creds not found");
    }
    else {
        Response *response = [AmazonClientManager validateCredentials];
        if (![response wasSuccessful]) {
            NSLog(@"CREDS not successful");
        }
        else {
            for (NSMutableString *file in arrayFromFile){
        
        //Commands to upload files to personal server instead of AWS S3
        
        //ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/upload.php"]];
        //[request setFile:[NSString stringWithString:[filePath stringByAppendingString:file]] forKey:@"file"];
        //[request setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
        //[request setDelegate:self];
        //[request setDidFinishSelector:@selector(uploadFinished:)];
        //[request setDidFailSelector:@selector(UploadFailed:)];
        //[request startAsynchronous];
        
        /* Start of code to upload files to S3 */
            
                    //Upload personal files to AWS S3
                    S3PutObjectRequest *request = [[S3PutObjectRequest alloc] initWithKey:[[NSString stringWithString:@"documents/users/konos/"] stringByAppendingString:file] inBucket:@"pycthesis"];
                    request.filename = [filePath stringByAppendingString:file];
                    //[request setDelegate:self];
                
                    S3PutObjectResponse *downloadResponse = [[AmazonClientManager s3] putObject:request];
                }
            }
    }
}
-(void) archiveFilesToDict {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrayFromFile = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    
    int i = 0;
    if ([arrayFromFile count] > 0) {
        if (fileArchive!=nil) 
            [fileArchive release];
        fileArchive = [[NSMutableDictionary alloc] init];
        for(NSString *file in arrayFromFile){
            [fileArchive setObject:[arrayFromFile objectAtIndex:i] forKey:file];
        }
        [fileArchive writeToFile:[filePath stringByAppendingString:@"files.arc"] atomically:TRUE];
    }
}
-(void) onTimeTrigger:(NSTimer *)timer {
    [self gpsController:nil];
}
-(void) encryptAllSharedFiles{
    NSArray *sharedDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedPath error:nil];
    for (NSString *file in sharedDirContents){
        NSData *encryptedFile = nil;
        if (![staticExtensions containsObject:[file pathExtension]])
        {    
            encryptedFile = [self encryptSingleFile:file atpath:sharedPath withType:true];
        } else {
            encryptedFile = [self encryptSingleFile:file atpath:sharedPath withType:false];
        }
        [encryptedFile writeToFile:[sharedPath stringByAppendingString:file] options:NSDataWritingFileProtectionComplete error:nil];
    }
}
-(NSData *) encryptSingleFile:(NSString *)file atpath:(NSString *) path withType:(BOOL)isString {
    NSData *encryptedFile = nil;
    //Compute KEY
    NSArray *encryptionCredentials = [NSArray arrayWithArray:[self generateKeyAndIv]];
    //Store KEY to the keyChain
    NSString *key = [[encryptionCredentials objectAtIndex:0] retain];
    NSString *iv = [[encryptionCredentials objectAtIndex:1] retain];
    [KeychainWrapper createKeychainValue:key forIdentifier:[[file lastPathComponent] stringByAppendingString:@"key"]];
    [KeychainWrapper createKeychainValue:iv forIdentifier:[[file lastPathComponent] stringByAppendingString:@"iv"]];
    if (isString) {
        NSString *fileContent = [NSString stringWithContentsOfFile:[path stringByAppendingString:file]];
        if (!fileContent){
            NSDictionary *fileContentDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingString:file]];
            fileContent = [fileContentDict description];
        }
        
    
        NSString *encryptedStr = [NSString stringWithString:[[CryptoHelper sharedInstance] 
                                                         encryptString:fileContent 
                                                         withKey:key 
                                                         andIV:iv]];
        encryptedFile =[encryptedStr dataUsingEncoding:NSUTF8StringEncoding];
    } else if (!isString) {
        NSData *fileContent = [NSData dataWithContentsOfFile:[path stringByAppendingString:file]];
        
        NSData *encryptedData = [NSData dataWithData:[[CryptoHelper sharedInstance] 
                                                             encryptData:fileContent 
                                                             withKey:key 
                                                             andIV:iv]];
        encryptedFile = encryptedData;
    }
    return encryptedFile;
}
#pragma mark GPS Controller
-(void) gpsController:(NSDictionary *)restrictions {
    if (restrictions!=nil) {
        locationLimit = [NSDictionary dictionaryWithDictionary:restrictions];
        [locationLimit retain];
    }
    [self.locMgr startUpdatingLocation];
    //NSLog(@"Activate GPS Locator");
    // [self archiveFilesToDict];
}
-(float) getLong {
    return self.locMgr.location.coordinate.longitude;
}
-(float) getLat {
    return self.locMgr.location.coordinate.latitude;
}
#pragma mark Timer Controller
-(void) timeController:(NSDictionary *)restrictions {
    if (timelimit==nil)
        timelimit = [NSDictionary dictionaryWithDictionary:restrictions];
    else {
        //[timelimit release];
        timelimit = [NSDictionary dictionaryWithDictionary:restrictions];
    }
    [self checkTime];
}
-(void) checkTime {
    //NSLog(@"Active TimeCheck.");
    unsigned int flags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:[NSDate date]];
    NSDate *currentTime = [calendar dateFromComponents:components];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
    [timeFormatter setDateFormat:@"HH:mm"];
        
    NSDate *timestart = [[NSDate alloc] init];
    timestart = [timeFormatter dateFromString:[timelimit objectForKey:@"start"]];
    NSDateComponents* components2 = [calendar components:flags fromDate:timestart];
    NSDate *timestartH = [calendar dateFromComponents:components2];
   
    NSDate *timeend = [[NSDate alloc] init];
    timeend = [timeFormatter dateFromString:[timelimit objectForKey:@"end"]];
    NSDateComponents* components3 = [calendar components:flags fromDate:timeend];
    NSDate *timeendH = [calendar dateFromComponents:components3];
    
    timeFrameStatus = toDelete;
    switch ([currentTime compare:timestartH]) {
        case NSOrderedAscending:
            //NSLog(@"before start");
            // do something
            break;
        case NSOrderedSame:
            //NSLog(@"myDate is the same as start");
            // do something
            break;
        case NSOrderedDescending:
            //NSLog(@"After start");
            // do something
            
            switch ([currentTime compare:timeendH]) {
                case NSOrderedAscending:
                    //NSLog(@"before end");
                    // do something
                    NSLog(@"Inside Time frame.");
                    timeFrameStatus = toRestore;
                    break;
                case NSOrderedSame:
                    //NSLog(@"myDate is the same as enddate");
                    // do something
                    break;
                case NSOrderedDescending:
                    //NSLog(@"After end");
                    // do something
                    break;
            }            
            break;
    }
    [self wipeOrRestoreData];
}
#pragma mark Request functions
- (void)requestFinished:(ASIHTTPRequest *)request {
    // Use when fetching text data
    //request 
    
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    
    // Use when fetching binary data
    NSData *responseData = [request responseData];
    [responseData writeToFile:[NSString stringWithString:[rootPath stringByAppendingString:@"/files/empty.txt"]] atomically:true];
}
- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"Error in HTTP request: %@", [error description]);
}
-(void) requestPolicy {
    
    ASIFormDataRequest *nameRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/requestPolicy.php"]];
    [nameRequest setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
    //[request setDelegate:self];
    //[request setDidFinishSelector:@selector(requestPolicyFinished:)];
    //[request setDidFailSelector:@selector(requestPolicyFailed:)];
    [nameRequest startSynchronous];
    NSError *error = [nameRequest error];
    if (!error){
        
               
        NSString *secretAccessKey = @"XNs8PqYItsEtdQf+RghD75BMylEhiDV9U1pNMPAz";
        NSString *accessKey = @"AKIAJ3YRMNOMNPX4EX5Q";
        NSString *bucket = @"pycthesis";
        NSString *path = @"policies/";
        
        //Response *response = [AmazonClientManager validateCredentials];
        
        AmazonS3Client *client = [[AmazonS3Client alloc] initWithAccessKey:accessKey withSecretKey:secretAccessKey];
        S3GetObjectRequest *downloadRequest = [[[S3GetObjectRequest alloc] initWithKey:[path stringByAppendingString:[nameRequest responseString]] withBucket:bucket] autorelease];
        [downloadRequest setDelegate:self];
        downloadRequest.requestTag = @"policy";
        S3GetObjectResponse *downloadResponse = [client getObject:downloadRequest];

        /* Request policy operation from custome server */
        //ASIS3ObjectRequest *request = [ASIS3ObjectRequest requestWithBucket:bucket key:[path stringByAppendingString:[nameRequest responseString]]];
        //[request setSecretAccessKey:secretAccessKey];
        //[request setAccessKey:accessKey];
        //[request setDelegate:self];
        //[request setDidFinishSelector:@selector(requestPolicyFinished:)];
        //[request setDidFailSelector:@selector(requestPolicyFailed:)];
        //[request startAsynchronous];
        //if(![request error]){
        //    NSLog(@"%@", [request responseString]);
        //} else {
        //    NSLog(@"%@", [[request error] localizedDescription]);
        //}

    }       
}
-(void) request:(S3Request *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    
    verifyLastFile++;
    NSArray *responseItems = [response.request.requestTag componentsSeparatedByString:@"/"];
    NSString *tag = [NSString stringWithString:[responseItems objectAtIndex:0]];
    if ([tag isEqualToString:@"shared"]) {
        if ([staticExtensions containsObject:[[responseItems objectAtIndex:1] lastPathComponent]]){
            NSString *file = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
            [file writeToFile:[sharedPath stringByAppendingString:[responseItems objectAtIndex:1]] 
                   atomically:YES 
                     encoding:NSUTF8StringEncoding 
                        error:nil];
        } else {
            NSData *output = [NSData dataWithData:response.body];
            [output writeToFile:[sharedPath stringByAppendingString:[responseItems objectAtIndex:1]] 
                     atomically:YES];
        }
    } else if ([tag isEqualToString:@"users"]) {
        NSData *output = [NSData dataWithData:response.body];
        [output writeToFile:[filePath stringByAppendingString:[responseItems objectAtIndex:1]] atomically:YES];
    } else  if ([response.request.requestTag isEqualToString:@"policy"]){
        NSLog(@"Downloading policy finished (%d)", response.httpStatusCode);
        [xmlviewDelegate newPolicy: [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]];
    }
    if (verifyLastFile==lastFile){
        files = restored;
        [self encryptAllSharedFiles];
    }

}
-(void) requestPolicyFinished:(ASIHTTPRequest *) response {
    //NSLog(@"Response string %@", [response responseString]);
    [xmlviewDelegate newPolicy: [response responseString]];
}
-(void) requestPolicyFailed:(ASIHTTPRequest *) response {
    NSLog(@"Response string %@", [response responseString]);
    [xmlviewDelegate newPolicy: [response responseString]];
}
-(void)uploadFinished:(ASIHTTPRequest *)request {
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    [self stopIndicators];    

}
-(void)UploadFailed:(ASIHTTPRequest *)request {
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    [self stopIndicators];
}
-(void)requestFilesFinished:(ASIHTTPRequest *)response {
    NSString *responseString = [response responseString];
    NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]];
    [myparser setDelegate:self];
    lastFile = 0;
    verifyLastFile = 0;
    [myparser parse];
    [myparser setDelegate:nil];
    [myparser release];
}
-(void) requestUniqueFileFinished:(ASIHTTPRequest *) response {
    verifyLastFile ++;
    if (verifyLastFile == lastFile){
        [self stopIndicators];
        
        files = restored;
        [self encryptAllSharedFiles];
    }
}
-(void) requestUniqueFileFailed:(ASIHTTPRequest *) response {
    verifyLastFile ++;
    if (verifyLastFile == lastFile){
        [self stopIndicators];
    }
    files = uncertain;
}
#pragma mark XMLparser delegate methods
-(void)parserDidStartDocument:(NSXMLParser *)parser {

}
-(void)parser: (NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSLog(@"%@", elementName);
    
    if (![elementName isEqualToString:@"fileslist"] && ![elementName isEqualToString:@"shared"]) {
        if (!sharedFile){
            lastFile = lastFile +1;
            NSString *remoteStorage = [NSString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/documents/users/konos/"];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[remoteStorage stringByAppendingString:elementName]]];
            [request setDownloadDestinationPath:[filePath stringByAppendingString:elementName]];
            [request setDelegate:self];
            [request startAsynchronous];
            [request setDidFinishSelector:@selector(requestUniqueFileFinished:)];
            [request setDidFailSelector:@selector(requestUniqueFileFailed:)];
            files = restored;
        } else if (sharedFile) {
            lastFile = lastFile +1;
            NSMutableString *remoteStorage = [NSMutableString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/documents/shared/"];
            [remoteStorage appendString:[attributeDict objectForKey:@"subfolder"]];
            [remoteStorage appendString:@"/"];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[remoteStorage stringByAppendingString:elementName]]];
            [request setDownloadDestinationPath:[rootPath stringByAppendingString:[[NSString stringWithString:@"/Shared/"] stringByAppendingString:elementName]]];
            [request setDelegate:self];
            [request startAsynchronous];
            [request setDidFinishSelector:@selector(requestUniqueFileFinished:)];
            [request setDidFailSelector:@selector(requestUniqueFileFailed:)];
            //files = restored;
        }
    }
    if ([elementName isEqualToString:@"shared"]) {
        sharedFile = true;
    }
}
-(void)parser: (NSXMLParser *) parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"Files parser - Errors in parsing: %@", [parseError description]);
    
}
-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"shared"])
    {
        sharedFile = false;
    }
}
#pragma mark Key and IV generation
-(NSArray *) generateKeyAndIv {
    
    //Get date to use as KEY and IV
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; 
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    
    NSString *fullText = [[[NSString stringWithString:dateString] stringByAppendingString:dateString] stringByAppendingString:[self generateRandomNumberMaxValue:999999]];
    
    //Compute KEY
    NSString *key = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:fullText] substringWithRange:NSMakeRange(0, 16)]];
    NSString *iv = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:fullText] substringWithRange:NSMakeRange(16, 16)]];
    
    NSArray *encryptionCredentials =[NSArray arrayWithObjects:key,iv, nil];
    return encryptionCredentials;
}
-(NSString *) generateRandomNumberMaxValue:(int)max {
    int number = (arc4random()%max)+1; //Generates Number from 1 to 100.
    NSString *string = [NSString stringWithFormat:@"%i", number];
    return string;
}
//Not used methods (yet!), included for testing purposes
#pragma mark Asymetric Encryption methods
- (BOOL)addPublicKey:(NSString *)key withTag:(NSString *)tag {
    NSString *s_key = [NSString string];
    NSArray  *a_key = [key componentsSeparatedByString:@"\n"];
    BOOL     f_key  = FALSE;
    
    for (NSString *a_line in a_key) {
        if ([a_line isEqualToString:@"-----BEGIN PUBLIC KEY-----"]) {
            f_key = TRUE;
        }
        else if ([a_line isEqualToString:@"-----END PUBLIC KEY-----"]) {
            f_key = FALSE;
        }
        else if (f_key) {
            s_key = [s_key stringByAppendingString:a_line];
        }
    }
    if (s_key.length == 0) return(FALSE);
    
    // This will be base64 encoded, decode it.
    NSData *d_key = [NSData dataFromBase64String:s_key];
    d_key = [self stripPublicKeyHeader:d_key];
    if (d_key == nil) return(FALSE);
    
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    publicTag = [NSData dataWithData:d_tag];
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    SecItemDelete((CFDictionaryRef)publicKey);
    
    CFTypeRef persistKey = nil;
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:d_key forKey:(id)kSecValueData];
    [publicKey setObject:(id) kSecAttrKeyClassPublic forKey:(id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)
     kSecReturnPersistentRef];
    
    OSStatus secStatus = SecItemAdd((CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) CFRelease(persistKey);
    
    if ((secStatus != noErr) && (secStatus != errSecDuplicateItem)) {
        [publicKey release];
        return(FALSE);
    }
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    
    [publicKey removeObjectForKey:(id)kSecValueData];
    [publicKey removeObjectForKey:(id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef
     ];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    secStatus = SecItemCopyMatching((CFDictionaryRef)publicKey,
                                    (CFTypeRef *)&keyRef);
    
    [publicKey release];
    
    if (keyRef == nil) return(FALSE);
    
    // Add to our pseudo keychain
    //[keyRefs addObject:[NSValue valueWithBytes:&keyRef objCType:@encode(SecKeyRef)]];
    
    return(TRUE);
}
- (NSData *)stripPublicKeyHeader:(NSData *)d_key {
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned int len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}
- (void)encryptWithPublicKey {
    OSStatus status = noErr;
    
    size_t cipherBufferSize;
    uint8_t *cipherBuffer;                     // 1
    
    // [cipherBufferSize]
    const uint8_t nonce[] = "the quick brown fox jumps over the lazy dog\0"; // 2
    
    SecKeyRef publicKey = NULL;                                 // 3
    
    //NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier length:strlen((const char *)publicKeyIdentifier)]; // 4
    
    //NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init]; // 5
    
    //[queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
    //[queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
    //[queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    //[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
    // 6
    
    //status = SecItemCopyMatching ((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKey); // 7
    
    //  Allocate a buffer
    
    //cipherBufferSize = sizeof(publicKey);
    cipherBuffer = malloc(1024);
    
    //  Error handling
    
    //if (cipherBufferSize < sizeof(nonce)) {
        // Ordinarily, you would split the data up into blocks
        // equal to cipherBufferSize, with the last block being
        // shorter. For simplicity, this example assumes that
        // the data is short enough to fit.
    //    printf("Could not decrypt.  Packet too large.\n");
    //    return;
    //}
    
    // Encrypt using the public.
    status = SecKeyEncrypt( [self getPublicKeyRef],
                           kSecPaddingPKCS1,
                           nonce,
                           (size_t) sizeof(nonce)/sizeof(nonce[0]),
                           cipherBuffer,
                           &cipherBufferSize
                           );                              // 8
    NSLog(@"%@",[NSString stringWithUTF8String:(char *)cipherBuffer]);
    
    //  Error handling
    //  Store or transmit the encrypted text
    
    if(publicKey) CFRelease(publicKey);
    //if(queryPublicKey) [queryPublicKey release];                // 9
    free(cipherBuffer);
}
- (SecKeyRef)getPublicKeyRef {
    OSStatus sanityCheck = noErr;
    SecKeyRef publicKeyReference = NULL;
    
    if (publicKeyRef == NULL) {
        NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
        
        // Set the public key query dictionary.
        [queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
        [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
        [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
        [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
        
        // Get the key.
        sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyReference);
        
        if (sanityCheck != noErr)
        {
            publicKeyReference = NULL;
        }
        
        [queryPublicKey release];
    } else {
        publicKeyReference = publicKeyRef;
    }
    
    return publicKeyReference;
}
@end
