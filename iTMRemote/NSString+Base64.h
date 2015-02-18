//
//  NSString+Base64.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 01.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Base64)

+ (NSString *) base64StringFromData:(NSData *)data length:(int)length;

@end
