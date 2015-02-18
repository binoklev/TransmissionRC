//
//  TRConnection.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 17.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRConnection : NSURLConnection

@property (nonatomic, copy) void(^errorBlock)(NSError*);
@property (nonatomic, copy) void(^successBlock)(NSData*);
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, assign) NSUInteger tag;

@end
