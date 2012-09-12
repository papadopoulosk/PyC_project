#import "XMLparserViewController.h"

@interface XMLparserViewController ()

@end

@implementation XMLparserViewController
@synthesize textView, mylabel, updatePolicyButton, mytable;
- (id)init
{
    [depth initWithInteger:0];
    output = [[NSMutableString alloc] initWithString:@""];
    rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    filePath = [NSString stringWithString:[rootPath stringByAppendingString:@"/files/"]];
    dictPath = [NSString stringWithString:[rootPath stringByAppendingString:@"/policy/archive.arc"]];
   
    NSArray *keys = [NSArray arrayWithObjects:@"geolocation", @"SWlat",@"SWlng",@"NElng",@"NElat", @"freq",@"killpill",@"logfreq",@"uploadfreq",@"timeframe",@"start",@"end",@"status",@"value", nil];
    NSArray *uivalues= [NSArray arrayWithObjects:@"GPS restrictions",@"Min latitude",@"Min longitude",@"Max longitude", @"Max latitude",@"Update frequency in seconds",@"Kill-pill status",@"Log keeping frequency",@"File back-up frequency",@"Allowed time frame",@"Start time",@"End time",@"Status", @"Value in seconds", nil];
    policyTags = [[NSDictionary dictionaryWithObjects:uivalues forKeys:keys] retain];
    
    sectionTitles = [[NSMutableArray alloc] init];
    sectionContent = [[NSMutableDictionary alloc] init];
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
}
-(void) newPolicy:(NSString *)newDoc
{
    //NSMutableString *tempurl = [NSMutableString stringWithString:@"http://konpapadopoulos.kiwedevelopment.eu/thesis/policies/"];
    //[tempurl appendString:newDoc];
    // NSLog(@"TEMP URL %@", tempurl);
    //NSURL *xmlUrl = [[NSURL alloc] initWithString:tempurl];
    //NSXMLParser *myparser = [[NSXMLParser alloc] initWithContentsOfURL: xmlUrl];
    NSXMLParser *myparser = [[NSXMLParser alloc] initWithData:[[NSString stringWithString:newDoc] dataUsingEncoding:NSUTF8StringEncoding]];
    [myparser setDelegate:self];
    bool result =  [myparser parse];
    if(result)
    {
        //archiving
        //NSMutableString *title = [NSMutableString stringWithString:[[tempurl lastPathComponent] stringByDeletingPathExtension]];
        
        //[self archieveXML:[NSString stringWithContentsOfURL:xmlUrl encoding:NSASCIIStringEncoding error:NULL] withTitle: title];
        [self archieveXML:output withTitle:@"policy"];
        [textView setText:[self getXMLbyKey:@"policy"]];
        NSLog(@"Policy updated and archived");
    } else {
        [textView setText:@"Cannot parse this document"];
    }
    
    //[output release];
    [myparser setDelegate:nil];
    //[xmlUrl release];
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
    //[connectFailMessage show];
    [connectFailMessage release];
}
-(IBAction)clearAll
{
    [[Device initialize] wipeData];
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
    NSFileManager *fileMgr = [[[NSFileManager alloc] init] autorelease];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:[rootPath stringByAppendingString:@"/policy/"] error:&error];
    for (NSString *path in directoryContents) {
        NSString *fullPath = [[rootPath stringByAppendingString:@"/policy/"] stringByAppendingPathComponent:path];
        BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
    }
    //NSMutableDictionary *archiveDict = [NSMutableDictionary dictionaryWithDictionary:[self retrieveArchive]];
    NSMutableDictionary *archiveDict = [NSMutableDictionary dictionaryWithObject:content forKey:title];
    //[archiveDict setValue:content forKey:title];
    [NSKeyedArchiver archiveRootObject:archiveDict toFile:dictPath];
    NSMutableString *location = [NSMutableString stringWithString:rootPath];
    [location appendString:@"/Policy/"];
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
    //[myindicator startAnimating];
}
-(void) stopIndicator
{
    //[myindicator stopAnimating];
}
#pragma mark Parser delegate methods
//Parsing actions from protocol
-(void)parser: (NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:@"geolocation"]) {
        [[Device initialize] gpsController:attributeDict];
    }
    if ([elementName isEqualToString:@"timeframe"]) {
        [[Device initialize] timeController:attributeDict];
    }
    [output appendString:[NSString stringWithFormat:@"<%@",elementName]];
    for (id keys in [attributeDict allKeys]) {
        [output appendFormat:@" %@=\"%@\"", keys, [attributeDict objectForKey:keys]];
    }
    
    if (![elementName isEqualToString:@"policy"]){
        [sectionContent setObject:attributeDict forKey: elementName];
        [sectionTitles addObject:elementName];
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
    //NSLog(@"Start Parsing Document!");
    [[Device initialize] deactivateControls];
    output = [[NSMutableString alloc] initWithString:@""];
    [sectionContent release];
    sectionContent = nil;
    sectionContent = [[NSMutableDictionary alloc] init];
    [sectionTitles release];
    sectionTitles = nil;
    sectionTitles = [[NSMutableArray alloc] init];
}

-(void)parserDidEndDocument:(NSXMLParser *) parser
{
    //NSLog(@"End parsing Document");
    [self stopIndicator];
    [mytable reloadData];
}

-(void)parser: (NSXMLParser *) parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"Policy parser - Errors in parsing: %@", [parseError description]);
    [self stopIndicator];
    errors = 1;
}

#pragma mark Table delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger) [sectionTitles count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [sectionTitles objectAtIndex:section];
    NSArray *keys = [[sectionContent objectForKey:key] allKeys];
    NSInteger rows = [keys count];
    
    return rows;
    //return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [sectionTitles objectAtIndex:[indexPath section]];
    NSDictionary *contents = [sectionContent objectForKey:key];
    
    NSString *contentForThisRow = [contents objectForKey:[[contents allKeys] objectAtIndex:[indexPath row]]];
    
    static NSString *CellIdentifier = @"CellIdentifier";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        // Do anything that should be the same on EACH cell here.  Fonts, colors, etc.
    }
	
    // Do anything that COULD be different on each cell here.  Text, images, etc.
    NSString *keyForLabel = [NSString stringWithString:[[contents allKeys] objectAtIndex:[indexPath row]]];
    if ([keyForLabel isEqualToString:@"status"] && [contentForThisRow isEqualToString:@"1"]){
        contentForThisRow = [NSString stringWithString:@"Active"];
        //NSLog(@"%@", contentForThisRow);
    }
    else if ([keyForLabel isEqualToString:@"status"] && [contentForThisRow isEqualToString:@"0"]) {
        contentForThisRow = [NSString stringWithString:@"Inactive"];
    }
    
    [cell.textLabel setText: [policyTags objectForKey:keyForLabel]];
    [cell.detailTextLabel setText:contentForThisRow];
	
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *key = [sectionTitles objectAtIndex:section];
    
    return [policyTags objectForKey:key];
}
@end
