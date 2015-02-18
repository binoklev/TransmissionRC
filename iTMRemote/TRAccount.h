//
//  TRAccount.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRAccount : NSObject

@property (retain, nonatomic) NSString *host;
@property (assign, nonatomic) BOOL ssl;
@property (assign, nonatomic) NSUInteger port;
@property (retain, nonatomic) NSString *directory;

@property (retain, nonatomic) NSString *lastDownloadPath;

@property (readonly, nonatomic) NSString *connectionString;

/**
 * save account properties to UserDefaults
 */
- (void)saveAccount;
/**
 * create and init account with settings from User Defaults
 * or nil if it doesn't exist
 */
+ (TRAccount*)savedAccount;

@end
