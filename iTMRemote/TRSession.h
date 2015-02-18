//
//  TRSession.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 01.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRSession : NSObject

@property (nonatomic, readonly) NSString *downloadDir;
@property (nonatomic, readonly) long long freeSpace;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end
