//
//  CryptoHelper.h
//  Thesis
//
//  Created by Lion User on 8/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "SystemUtilities.h"

@interface CryptoHelper : NSObject
{
	NSMutableData *symmetricKey;
    //uint8_t kKeyBytes;
}

+ (CryptoHelper *)sharedInstance;

- (NSString*)encryptString:(NSString*)string withKey:(NSString *) key andIV:(NSString *) IV;
- (NSString*)decryptString:(NSString*)string withKey:(NSString *) key andIV:(NSString *) IV;
@end
