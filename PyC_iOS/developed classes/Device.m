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
static const UInt8 publicKeyIdentifier[] = "com.apple.sample.publickey";
static const UInt8 privateKeyIdentifier[] = "com.apple.sample.privatekey";

@implementation Device
@synthesize locMgr, delegate, mapDelegate, xmlviewDelegate;

static Device *mydevice = nil;

#pragma mark Standard functions
+ (Device*)initialize
{
    if (mydevice == nil) {
        mydevice = [[super allocWithZone:NULL] init];
    }
    return mydevice;
}
+ (id)allocWithZone:(NSZone *)zone
{
    return [[self initialize] retain];
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
- (id)retain
{
    return self;
}
- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}
- (void)release
{
    //do nothing
}
- (id)autorelease
{
    return self;
}
-(id)init
{
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
- (void)dealloc
{
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
-(void)log
{
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
    NSData *encryptedLogFile = [self encryptSingleFile:@"log.arc" atpath:logPath];
    [encryptedLogFile writeToFile:[logPath stringByAppendingString:@"log.arc"] options:NSDataWritingFileProtectionComplete error:nil];
    
    }
-(NSMutableDictionary *) getInfo
{
    return information;
}
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
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
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}
-(void) uploadLog
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/upload.php"]];
    [request setFile:logPath forKey:@"file"];
    [request setDelegate:self];
    [request setTimeOutSeconds:10.00000];
    [request setDidFailSelector:@selector(test)];
    [request startAsynchronous];
    [self startIndicators];
}
-(void) startIndicators
{
    //[xmlviewDelegate startIndicator];
    //[delegate startIndicator];
}
-(void) stopIndicators
{
    //[xmlviewDelegate stopIndicator];
    //[delegate stopIndicator];
}
-(void) test
{
    NSLog(@"Fail selector test");
    [self stopIndicators];
}
#pragma mark Device and policy controls
-(void)timerFireMethod:(NSTimer*)theTimer
{
    [self gpsController:nil];
}
-(void) deactivateControls
{
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
-(void) wipeOrRestoreData
{
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
-(void) wipeData 
{
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
-(void) restoreFiles
{
    [self startIndicators];
    NSURL *url = [NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/requestFiles.php"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
    [request setDelegate:self];
    [request startAsynchronous];
    [request setDidFinishSelector:@selector(requestFilesFinished:)];
    [request setDidFailSelector:@selector(requestFilesFailed:)];
    
}
-(void) uploadFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrayFromFile = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    [self startIndicators];

    for (NSMutableString *file in arrayFromFile){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/upload.php"]];
        [request setFile:[NSString stringWithString:[filePath stringByAppendingString:file]] forKey:@"file"];
        [request setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(uploadFinished:)];
        [request setDidFailSelector:@selector(UploadFailed:)];
        [request startAsynchronous];
    }
    
}
-(void) archiveFilesToDict
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrayFromFile = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    
    int i = 0;
    if ([arrayFromFile count] > 0) {
        if (fileArchive!=nil) 
            [fileArchive release];
        fileArchive = [[NSMutableDictionary alloc] init];
        for(NSString *file in arrayFromFile){
            //NSLog(@"File name: %@", file);
            [fileArchive setObject:[arrayFromFile objectAtIndex:i] forKey:file];
        }
        [fileArchive writeToFile:[filePath stringByAppendingString:@"files.arc"] atomically:TRUE];
    }
}
-(void) onTimeTrigger:(NSTimer *)timer
{
    [self gpsController:nil];
}
-(void) encryptAllSharedFiles{
    NSArray *sharedDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedPath error:nil];
    for (NSString *file in sharedDirContents){
        NSData *encryptedFile = [self encryptSingleFile:file atpath:sharedPath];
        [encryptedFile writeToFile:[sharedPath stringByAppendingString:file] options:NSDataWritingFileProtectionComplete error:nil];
    }
}
-(NSData *) encryptSingleFile:(NSString *)file atpath:(NSString *) path
{
    //Get date to use as KEY and IV
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    //Compute KEY
    NSString *key = [NSString stringWithString:[[KeychainWrapper computeSHA256DigestForString:dateString] substringWithRange:NSMakeRange(0, 16)]];
    //Store KEY to the keyChain
    [KeychainWrapper createKeychainValue:key forIdentifier:file];
    
    //NSLog(@"%@, %@", path, file);
    NSString *fileContent = [NSString stringWithContentsOfFile:[path stringByAppendingString:file] encoding:NSUTF8StringEncoding error:nil];
    if (!fileContent){
        NSDictionary *fileContentDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingString:file]];
        fileContent = [fileContentDict description];
    }
    
    //NSLog(@"INside encryption : %@", fileContent);
    //NSLog(@"Shared path is :%@",sharedPath);
    //NSLog(@"File: %@, FILECONTENT: %@", file, fileContent);
    NSString *encryptedStr = [NSString stringWithString:[[CryptoHelper sharedInstance] 
                                                         encryptString:fileContent 
                                                         withKey:key 
                                                         andIV:nil] ];
    NSData *encryptedFile =[encryptedStr dataUsingEncoding:NSUTF8StringEncoding];
    return encryptedFile;
}
#pragma mark GPS Controller
-(void) gpsController:(NSDictionary *)restrictions
{
    if (restrictions!=nil) {
        locationLimit = [NSDictionary dictionaryWithDictionary:restrictions];
        [locationLimit retain];
    }
    [self.locMgr startUpdatingLocation];
    //NSLog(@"Activate GPS Locator");
    // [self archiveFilesToDict];
}
-(float) getLong
{
    return self.locMgr.location.coordinate.longitude;
}
-(float) getLat
{
    return self.locMgr.location.coordinate.latitude;
}
#pragma mark Timer Controller
-(void) timeController:(NSDictionary *)restrictions
{
    if (timelimit==nil)
        timelimit = [NSDictionary dictionaryWithDictionary:restrictions];
    else {
        //[timelimit release];
        timelimit = [NSDictionary dictionaryWithDictionary:restrictions];
    }
    [self checkTime];
}
-(void) checkTime
{
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
- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    //request 
    
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    
    // Use when fetching binary data
    NSData *responseData = [request responseData];
    [responseData writeToFile:[NSString stringWithString:[rootPath stringByAppendingString:@"/files/empty.txt"]] atomically:true];
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"Error in HTTP request: %@", [error description]);
}
-(void) requestPolicy
{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/requestPolicy.php"]];
    [request setPostValue:[SystemUtilities getUniqueIdentifier] forKey:@"deviceID"];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestPolicyFinished:)];
    [request setDidFailSelector:@selector(requestPolicyFailed:)];
    [request startAsynchronous];
}
-(void) requestPolicyFinished:(ASIHTTPRequest *) response
{
    NSLog(@"Response string %@", [response responseString]);
    [xmlviewDelegate newPolicy: [response responseString]];
}
-(void) requestPolicyFailed:(ASIHTTPRequest *) response
{
    [xmlviewDelegate newPolicy: [response responseString]];
}
-(void)uploadFinished:(ASIHTTPRequest *)request
{
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    [self stopIndicators];    

}
-(void)UploadFailed:(ASIHTTPRequest *)request
{
    NSString *responseString = [request responseString];
    NSLog(@"Response string: %@", responseString);
    [self stopIndicators];
}
-(void)requestFilesFinished:(ASIHTTPRequest *)response
{
    NSString *responseString = [response responseString];
    NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]];
    [myparser setDelegate:self];
    lastFile = 0;
    verifyLastFile = 0;
    [myparser parse];
    [myparser setDelegate:nil];
    [myparser release];
}
-(void) requestUniqueFileFinished:(ASIHTTPRequest *) response
{
    verifyLastFile ++;
    if (verifyLastFile == lastFile){
        [self stopIndicators];
        
        files = restored;
        [self encryptAllSharedFiles];
    }
}
-(void) requestUniqueFileFailed:(ASIHTTPRequest *) response
{
    verifyLastFile ++;
    if (verifyLastFile == lastFile){
        [self stopIndicators];
    }
    files = uncertain;
}
#pragma mark XMLparser delegate methods
-(void)parserDidStartDocument:(NSXMLParser *)parser
{

}
-(void)parser: (NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
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
-(void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"shared"])
    {
        sharedFile = false;
    }
}

//Not used methods (yet!), included for testing purposes
#pragma mark Encryption methods
-(SecKeyRef)getPublicKeyRef
{ 
    
    OSStatus sanityCheck = noErr; 
    SecKeyRef publicKeyReference = NULL;
    
    if (publicKeyReference == NULL) { 
        [self generateKeyPair:512];
        NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init];
        // Set the public key query dictionary.
        [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
        [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
        // Get the key.
        sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyReference);
        if (sanityCheck != noErr)
        {
            publicKeyReference = NULL;
        }
        //        [queryPublicKey release];
    } else { 
        publicKeyReference = publicKey; }
    
    return publicKeyReference;
}
-(void)testAsymmetricEncryptionAndDecryption
{
    
    uint8_t *plainBuffer;
    uint8_t *cipherBuffer;
    uint8_t *decryptedBuffer;
    const char inputString[] = "Sample test to be encrypted";
    int len = strlen(inputString);
    // TODO: this is a hack since i know inputString length will be less than BUFFER_SIZE
    if (len > BUFFER_SIZE) len = BUFFER_SIZE-1;
    
    plainBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
    cipherBuffer = (uint8_t *)calloc(CIPHER_BUFFER_SIZE, sizeof(uint8_t));
    decryptedBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
    
    strncpy( (char *)plainBuffer, inputString, len);
    
    NSLog(@"init() plainBuffer: %s", plainBuffer);
    //NSLog(@"init(): sizeof(plainBuffer): %d", sizeof(plainBuffer));
    [self encryptWithPublicKey:(UInt8 *)plainBuffer cipherBuffer:cipherBuffer];
    NSLog(@"encrypted data: %s", cipherBuffer);
    //NSLog(@"init(): sizeof(cipherBuffer): %d", sizeof(cipherBuffer));
    [self decryptWithPrivateKey:cipherBuffer plainBuffer:decryptedBuffer];
    NSLog(@"decrypted data: %s", decryptedBuffer);
    //NSLog(@"init(): sizeof(decryptedBuffer): %d", sizeof(decryptedBuffer));
    NSLog(@"====== /second test =======================================");
    
    free(plainBuffer);
    free(cipherBuffer);
    free(decryptedBuffer);
}
-(void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer
{
    
    NSLog(@"== encryptWithPublicKey()");
    
    OSStatus status = noErr;
    
    NSLog(@"** original plain text 0: %s", plainBuffer);
    
    size_t plainBufferSize = strlen((char *)plainBuffer);
    size_t cipherBufferSize = CIPHER_BUFFER_SIZE;
    
    NSLog(@"SecKeyGetBlockSize() public = %lu", SecKeyGetBlockSize([self getPublicKeyRef]));
    //  Error handling
    // Encrypt using the public.
    status = SecKeyEncrypt([self getPublicKeyRef],
                           PADDING,
                           plainBuffer,
                           plainBufferSize,
                           &cipherBuffer[0],
                           &cipherBufferSize
                           );
    NSLog(@"encryption result code: %ld (size: %lu)", status, cipherBufferSize);
    NSLog(@"encrypted text: %s", cipherBuffer);
}
- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer
{
    OSStatus status = noErr;
    
    size_t cipherBufferSize = strlen((char *)cipherBuffer);
    
    NSLog(@"decryptWithPrivateKey: length of buffer: %lu", BUFFER_SIZE);
    NSLog(@"decryptWithPrivateKey: length of input: %lu", cipherBufferSize);
    
    // DECRYPTION
    size_t plainBufferSize = BUFFER_SIZE;
    
    //  Error handling
    status = SecKeyDecrypt([self getPrivateKeyRef],
                           PADDING,
                           &cipherBuffer[0],
                           cipherBufferSize,
                           &plainBuffer[0],
                           &plainBufferSize
                           );
    NSLog(@"decryption result code: %ld (size: %lu)", status, plainBufferSize);
    NSLog(@"FINAL decrypted text: %s", plainBuffer);
    
}
-(SecKeyRef)getPrivateKeyRef
{
    OSStatus resultCode = noErr;
    SecKeyRef privateKeyReference = NULL;
    //    NSData *privateTag = [NSData dataWithBytes:@"ABCD" length:strlen((const char *)@"ABCD")];
    //    if(privateKey == NULL) {
    [self generateKeyPair:512];
    NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];
    
    // Set the private key query dictionary.
    [queryPrivateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPrivateKey setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPrivateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Get the key.
    resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKeyReference);
    NSLog(@"getPrivateKey: result code: %ld", resultCode);
    
    if(resultCode != noErr)
    {
        privateKeyReference = NULL;
    }
    
    //        [queryPrivateKey release];
    //    } else {
    //        privateKeyReference = privateKey;
    //    }
    
    return privateKeyReference;
}
-(void)generateKeyPair:(NSUInteger)keySize
{
    OSStatus sanityCheck = noErr;
    publicKey = NULL;
    privateKey = NULL;
    
    //  LOGGING_FACILITY1( keySize == 512 || keySize == 1024 || keySize == 2048, @"%d is an invalid and unsupported key size.", keySize );
    
    // First delete current keys.
    //  [self deleteAsymmetricKeys];
    
    // Container dictionaries.
    NSMutableDictionary * privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * keyPairAttr = [[NSMutableDictionary alloc] init];
    
    // Set top level dictionary for the keypair.
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:keySize] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    // Set the private key dictionary.
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set the public key dictionary.
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set attributes to top level dictionary.
    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
    
    // SecKeyGeneratePair returns the SecKeyRefs just for educational purposes.
    sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    //  LOGGING_FACILITY( sanityCheck == noErr && publicKey != NULL && privateKey != NULL, @"Something really bad went wrong with generating the key pair." );
    if(sanityCheck == noErr  && publicKey != NULL && privateKey != NULL)
    {
        NSLog(@"Successful");
    }
    //  [privateKeyAttr release];
    //  [publicKeyAttr release];
    //  [keyPairAttr release];
}
@end
