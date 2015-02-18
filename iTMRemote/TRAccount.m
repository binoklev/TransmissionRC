//
//  TRAccount.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRAccount.h"

@implementation TRAccount

@dynamic connectionString;

+ (TRAccount*)savedAccount {
    TRAccount *account = nil;
    NSString *str = [USER_DEFAULTS stringForKey:TR_DEFAULTS_KEY_ACCOUNT_HOST];
    if ([str length]) {
        account = [[TRAccount alloc] init];
        account.host = str;
        NSInteger port = [USER_DEFAULTS integerForKey:TR_DEFAULTS_KEY_ACCOUNT_PORT];
        if (port) {
            account.port = port;
        }
        account.ssl = [USER_DEFAULTS boolForKey:TR_DEFAULTS_KEY_ACCOUNT_SSL];
        str = [USER_DEFAULTS stringForKey:TR_DEFAULTS_KEY_ACCOUNT_DIR];
        if (str) {
            account.directory = str;
        }
        str = [USER_DEFAULTS stringForKey:TR_DEFAULTS_KEY_ACCOUNT_LAST_PATH];
        if (str) {
            account.lastDownloadPath = str;
        }
    }
    return account;
}

- (id)init {
    if (self = [super init]) {
        self.host = @"";
        self.port = TR_URL_PORT_DEFAULT;
        self.ssl = NO;
        self.directory = TR_URL_PATH_DEFAULT;
        self.lastDownloadPath = @"";
    }
    return self;
}

#pragma mark - properties

- (void)setHost:(NSString *)host {
    if ([host hasPrefix:@"https"]) {
        _host = [host substringFromIndex:8];
        self.ssl = YES;
    } else if ([host hasPrefix:@"http"]) {
        _host = [host substringFromIndex:7];
        self.ssl = NO;
    } else {
        _host = host;
    }
}

- (NSString*)connectionString {
    
    if (self.host.length == 0) {
        return @"";
    }
    NSMutableString *str = [NSMutableString stringWithString:@"http"];
    if (self.ssl) {
        [str appendString:@"s"];
    }
    [str appendFormat:@"://%@",self.host];
    if (self.port != 0) {
        [str appendFormat:@":%lu", (unsigned long)self.port];
    }
    if (self.directory.length) {
        if ( ! [self.directory hasPrefix:@"/"]) {
            [str appendString:@"/"];
        }
        [str appendString:self.directory];
    }
    if ([str hasSuffix:@"/"]) {
        return [str substringToIndex:(str.length-1)];
    }
    return str;
}

- (void)saveAccount {
    // save account
    @synchronized(self) {
        // clean
        [USER_DEFAULTS removeObjectForKey:TR_DEFAULTS_KEY_ACCOUNT_HOST];
        [USER_DEFAULTS removeObjectForKey:TR_DEFAULTS_KEY_ACCOUNT_PORT];
        [USER_DEFAULTS removeObjectForKey:TR_DEFAULTS_KEY_ACCOUNT_SSL];
        [USER_DEFAULTS removeObjectForKey:TR_DEFAULTS_KEY_ACCOUNT_DIR];
        [USER_DEFAULTS removeObjectForKey:TR_DEFAULTS_KEY_ACCOUNT_LAST_PATH];
        
        if ([self.host length]) {
            [USER_DEFAULTS setObject:self.host forKey:TR_DEFAULTS_KEY_ACCOUNT_HOST];
            if (self.port != TR_URL_PORT_DEFAULT)
                [USER_DEFAULTS setInteger:self.port forKey:TR_DEFAULTS_KEY_ACCOUNT_PORT];
            if (self.ssl)
                [USER_DEFAULTS setBool:YES forKey:TR_DEFAULTS_KEY_ACCOUNT_SSL];
            if ( ! [self.directory isEqualToString:TR_URL_PATH_DEFAULT])
                [USER_DEFAULTS setObject:self.directory forKey:TR_DEFAULTS_KEY_ACCOUNT_DIR];
            if ([self.lastDownloadPath length])
                [USER_DEFAULTS setObject:self.lastDownloadPath forKey:TR_DEFAULTS_KEY_ACCOUNT_LAST_PATH];
         }
        [USER_DEFAULTS synchronize];
    }
}

@end
