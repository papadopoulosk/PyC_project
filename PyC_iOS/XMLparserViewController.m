#import "XMLparserViewController.h"

@interface XMLparserViewController ()

@end

@implementation XMLparserViewController
@synthesize textView, mylabel, updatePolicyButton;
- (id)init
{
    [depth initWithInteger:0];
    output = [[NSMutableString alloc] initWithString:@""];
    rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/files/"]];
    dictPath = [NSString stringWithString:[rootPath stringByAppendingString:@"/policy/archive.arc"]];
   
    [[Device initialize] setXmlviewDelegate:self];
    [dictPath retain];
    [rootPath retain];
    [filePath retain];
    [dictPath2 retain];
   
    errors = 0;
    self = [super initWithNibName:nil bundle:Nil];
    if (self) {
        UITabBarItem *tbi = [self tabBarItem];
        [tbi setTitle:@"Policy"];
        UIImage* anImage = [UIImage imageNamed:@"tab-icon2.png"];
        [tbi setImage:anImage];
        
        myindicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        myindicator.center = CGPointMake(300, 365);
        [myindicator setColor:[UIColor blackColor]];
        [self.view addSubview:myindicator];

    }    
    return self;
}
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
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
-(IBAction) updatePolicy
{
    [updatePolicyButton setEnabled:false];
    [self startIndicator];
    //NSMutableString *tempurl = [NSMutableString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/policies/"];
    [[Device initialize] requestPolicy];
/*   NSURL *xmlUrl = [[NSURL alloc] initWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/policies/aaaaaaa.xml"];
    NSXMLParser *myparser = [[NSXMLParser alloc] initWithContentsOfURL: xmlUrl];
   // NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:<#(NSData *)#>
   // NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:dictPath2]];
    [myparser setDelegate:self];
   bool result =  [myparser parse];
    if(result)
    {
        //archiving
        NSMutableString *title = [NSMutableString stringWithString:[[xmlUrl lastPathComponent] stringByDeletingPathExtension]];

        //[self archieveXML:[NSString stringWithContentsOfURL:xmlUrl encoding:NSASCIIStringEncoding error:NULL] withTitle: title];
       [self archieveXML:output withTitle:title];
        [textView setText:[self getXMLbyKey:title]];
        NSLog(@"Policy updated and archived");
    } else {
        [textView setText:@"Cannot parse this document"];
    }
    [output release];
    [myparser setDelegate:nil];
    [xmlUrl release];
    [myparser release]; */
    
}
-(void) newPolicy:(NSString *)newDoc
{
   
    NSMutableString *tempurl = [NSMutableString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/policies/"];
    [tempurl appendString:newDoc];
     NSLog(@"TEMP URL %@", tempurl);
    NSURL *xmlUrl = [[NSURL alloc] initWithString:tempurl];
    NSXMLParser *myparser = [[NSXMLParser alloc] initWithContentsOfURL: xmlUrl];
    [myparser setDelegate:self];
    bool result =  [myparser parse];
    if(result)
    {
        //archiving
        NSMutableString *title = [NSMutableString stringWithString:[[tempurl lastPathComponent] stringByDeletingPathExtension]];
        
        //[self archieveXML:[NSString stringWithContentsOfURL:xmlUrl encoding:NSASCIIStringEncoding error:NULL] withTitle: title];
        [self archieveXML:output withTitle:title];
        [textView setText:[self getXMLbyKey:title]];
        NSLog(@"Policy updated and archived");
    } else {
        [textView setText:@"Cannot parse this document"];
    }
    
    //[output release];
    [myparser setDelegate:nil];
    [xmlUrl release];
    [myparser release];
    [updatePolicyButton setEnabled:true];
}
                             
-(IBAction)unarchive
{
    //NSLog(@"DictPath %@: ", dictPath);
    NSMutableDictionary *archiveDict2 = [NSMutableDictionary dictionaryWithDictionary:[self retrieveArchive]];
    //NSString *key2;
    for (id key2 in [archiveDict2 allKeys]){
        [textView setText:[archiveDict2 valueForKey:key2]];
        NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[[archiveDict2 valueForKey:key2] dataUsingEncoding:NSUTF8StringEncoding]];
        [myparser setDelegate:self];
        [myparser parse];
        [myparser setDelegate:nil];
        [myparser release];
    }
    
    UIAlertView *connectFailMessage = [[UIAlertView alloc] initWithTitle:@"Result" message:@"Policy Restored from DB"  delegate: self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [connectFailMessage show];
    [connectFailMessage release];
}
-(IBAction)clearAll
{
    [textView setText:@""];
    
    NSFileManager *fileMgr = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
       NSLog(@"File path is %@", filePath);
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:filePath error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [filePath stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                NSLog(@"Error in clearing file");
            } else {
                NSLog(@"File deleted!");
            }
        }
        //Alert window
        UIAlertView *connectFailMessage = [[UIAlertView alloc] initWithTitle:@"Result" message:@"Files deleted"  delegate: self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [connectFailMessage show];
        [connectFailMessage release];
        
    } else {
        NSLog(@"Error %@", [error description]);
    }
}

//Parsing actions from protocol
-(void)parser: (NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
  
    if ([elementName isEqualToString:@"geolocation"]) {
        [[Device initialize] gpsController:attributeDict];
    }
    [output appendString:[NSString stringWithFormat:@"<%@",elementName]];
     for (id keys in [attributeDict allKeys]) {
        [output appendFormat:@" %@=\"%@\"", keys, [attributeDict objectForKey:keys]];
    }
    [output appendString:@">"];
}

-(void)parser: (NSXMLParser *) parser foundCharacters:(NSString *)string {
    //NSLog(@"Element value: %@", string);          
}

-(void)parser: (NSXMLParser *) parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    [output appendFormat:@"</%@>", elementName];
}

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    NSLog(@"Start Parsing Document!");
    [[Device initialize] deactivateControls];
    output = [[NSMutableString alloc] initWithString:@""];
}

-(void)parserDidEndDocument:(NSXMLParser *) parser
{
    NSLog(@"End parsing Document");
    [self stopIndicator];
}

-(void)parser: (NSXMLParser *) parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"Errors in parsing: %@", [parseError description]);
    [self stopIndicator];
    errors = 1;
}

-(NSString *) retrieve:(NSURL *) url{
    
    @try {
        NSString *str = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:NULL];
        return str;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

-(void) archieveXML:(NSString *) content withTitle:(NSString *)title
{
    NSMutableDictionary *archiveDict = [NSMutableDictionary dictionaryWithDictionary:[self retrieveArchive]];
    [archiveDict setValue:content forKey:title];
    [NSKeyedArchiver archiveRootObject:archiveDict toFile:dictPath];
    NSMutableString *location = [NSMutableString stringWithString:rootPath];
    [location appendString:@"/policy/"];
    [location appendString:title];
    [location appendString:@".xml"];
    [content writeToFile:location atomically:true encoding:NSUTF8StringEncoding error: NULL]; 
}
-(NSMutableDictionary *) retrieveArchive
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:dictPath];
}
-(NSString *) getXMLbyKey:(NSString *) key
{
    return [[NSKeyedUnarchiver unarchiveObjectWithFile:dictPath] objectForKey:key];
}
-(NSArray *) returnKeys
{
    return [[NSKeyedUnarchiver unarchiveObjectWithFile:dictPath] allKeys];
}
-(void) startIndicator
{
    [myindicator startAnimating];
}
-(void) stopIndicator
{
    [myindicator stopAnimating];
}
@end
