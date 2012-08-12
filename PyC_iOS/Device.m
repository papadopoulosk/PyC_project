//
//  Device.m
//  Thesis
//
//  Created by Lion User on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "Device.h"

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
        eraseTimer=nil;
        netInfo = [[CTTelephonyNetworkInfo alloc] init];
        mycarrier = [netInfo subscriberCellularProvider];
        information = [[NSMutableDictionary alloc] init];
        infoStatus = neutral;
        fileArchive = nil;
        gpsTimer = nil;
        lastFile = 0;
        verifyLastFile = 0;
    
        rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/files/"]];
        logPath = [NSString stringWithString:[filePath stringByAppendingString:@"/log.arc"]];
      
        [logPath retain];
        [rootPath retain];
        [filePath retain];
    
        
        
        /*[information addObject:[[UIDevice currentDevice] model]];
        [information addObject:[[UIDevice currentDevice] name]];
        [information addObject:[[UIDevice currentDevice] systemName]];
        [information addObject:[[UIDevice currentDevice] systemVersion]];
         */
        //[information addObject:[NSString stringWithFormat:@"%f", [[UIDevice currentDevice] batteryLevel]] ];
        /* This is comment because it is not working properly in the SIMULATOR. Normally it should display normal data */
        //[information addObject:@"Vodafone"];            //[mycarrier carrierName] ];
        //[information addObject:@"15 - Greece"];         //[mycarrier isoCountryCode] ];
        /*[information addObject:[mycarrier mobileCountryCode] ];
        [information addObject:[mycarrier mobileNetworkCode] ];
        */
        //[information setObject:<#(id)#> forKey:<#(id)#>];
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
        // [information setObject:[NSString stringWithString:@"Greece"] forKey:@"Country"];
        /*
        [information addObject:[SystemUtilities getUniqueIdentifier]];
        [information addObject:[SystemUtilities getSystemUptime]];
        [information addObject:[SystemUtilities getModel]];
        [information addObject:[SystemUtilities getIPAddress]];
        [information addObject:[SystemUtilities netmaskForWifi]];
        [information addObject:[SystemUtilities getBatteryLevelInfo]];
        [information addObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.latitude]];
        [information addObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.longitude]];
         */
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
    [information writeToFile:logPath atomically:YES];
    
    NSArray *arrayFromFile = [NSArray arrayWithContentsOfFile:logPath];
    for (NSString *element in arrayFromFile) 
        NSLog(@"Data: %@", element);
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:logPath];
    for (id key in [dict allKeys])
    {
        NSLog(@"Key: %@, info: %@", [key description], [dict objectForKey:key]);
    }
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
        if (newLocation.coordinate.latitude < [[locationLimit objectForKey:@"NElat"] floatValue] && newLocation.coordinate.latitude>[[locationLimit objectForKey:@"SWlat"] floatValue] && newLocation.coordinate.longitude < [[locationLimit objectForKey:@"NElng"] floatValue] && newLocation.coordinate.longitude > [[locationLimit objectForKey:@"SWlng"] floatValue] ){
                        
            if (eraseTimer !=nil) {
                // Stop timer:
                 if ([eraseTimer isValid])
                    [eraseTimer invalidate];
                infoStatus = neutral;
                eraseTimer = nil;
                NSLog(@"Delete countdown canceled!");
            }
            if (infoStatus  != restored){
                [self restoreFiles];
                NSLog(@"Files restored");
            }
            
        } else {
            //Out of limits alert!
            NSLog(@"Out of limits!");
            if (eraseTimer==nil && infoStatus!=deleted) {
                eraseTimer = [NSTimer scheduledTimerWithTimeInterval:32.0 target:self selector:@selector(wipeData) userInfo:nil repeats:NO];
                NSLog(@"Files will be deleted soon!");
            }
            //[self wipeData];
        }
    }
    
    [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.latitude] forKey:@"Latitude"];
    [information setObject:[NSString stringWithFormat:@"%f", self.locMgr.location.coordinate.longitude] forKey:@"Longitute"];
    
   // [delegate locationUpdate:newLocation];
    [mapDelegate updateRegion];
   
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
    [xmlviewDelegate startIndicator];
    [delegate startIndicator];
}
-(void) stopIndicators
{
    [xmlviewDelegate stopIndicator];
    [delegate stopIndicator];
}
-(void) test
{
    NSLog(@"Fail selector test");
    [self stopIndicators];
}
#pragma mark Device and policy controls
-(void) gpsController:(NSDictionary *)restrictions
{
    if (restrictions!=nil) {
        locationLimit = [NSDictionary dictionaryWithDictionary:restrictions];
        [locationLimit retain];
    }
    [self.locMgr startUpdatingLocation];
    NSLog(@"Activate GPS Locator");
    // [self archiveFilesToDict];
}
-(void)timerFireMethod:(NSTimer*)theTimer
{
    [self gpsController:nil];
}
-(void) deactivateControls
{
    NSLog(@"Everything is switched off due to Update");
    //Cancel GPS tracking
    if (gpsTimer!=nil) {
        [gpsTimer invalidate];
        gpsTimer=nil;
    }
    [self.locMgr stopUpdatingLocation];
}
-(void) wipeData 
{
    NSFileManager *fileMgr = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:filePath error:&error];
    if (error == nil) {
        int counter = 0;
        for (NSString *path in directoryContents) {
            counter++;
            NSString *fullPath = [filePath stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                NSLog(@"Error in clearing file");
            } else {
                NSLog(@"File deleted!");
            }
        }
        //Alert window
        if (counter > 0 ) {
            UIAlertView *dataWipeMessage = [[UIAlertView alloc] initWithTitle:@"Result" message:@"Files deleted"  delegate: self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [dataWipeMessage show];
            [dataWipeMessage release];
            infoStatus = deleted;
        }
    }
}
-(void) restoreFiles
{
    [self startIndicators];
    NSURL *url = [NSURL URLWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/requestFiles.php"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
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
-(float) getLong
{
    return self.locMgr.location.coordinate.longitude;
}
-(float) getLat
{
    return self.locMgr.location.coordinate.latitude;
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
    NSLog(@"File list: %@", responseString);
     NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]];
    [myparser setDelegate:self];
   //[myparser setShouldResolveExternalEntities:true];
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
    }
    
}
-(void) requestUniqueFileFailed:(ASIHTTPRequest *) response
{
    NSLog(@"ERROR");
    
   if (verifyLastFile == lastFile){
        [self stopIndicators];
    }
    verifyLastFile ++;
}

#pragma mark XMLparser delegate methods
-(void)parser: (NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
    if (![elementName isEqualToString:@"fileslist"]) {
        lastFile = lastFile +1;
        NSString *remoteStorage = [NSString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/logfiles/"];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[remoteStorage stringByAppendingString:elementName]]];
        [request setDownloadDestinationPath:[filePath stringByAppendingString:elementName]];
        [request setDelegate:self];
        [request startAsynchronous];
        [request setDidFinishSelector:@selector(requestUniqueFileFinished:)];
        [request setDidFailSelector:@selector(requestUniqueFileFailed:)];
        infoStatus = restored;
    }
}
-(void)parser: (NSXMLParser *) parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"Errors in parsing: %@", [parseError description]);
    
}

@end
