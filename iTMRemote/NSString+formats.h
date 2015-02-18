//
//  NSString+formats.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 07.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (formats)
+ (NSString*)bytesSecFromLong:(long long)value;
+ (NSString*)bytesFromLong:(long long)value;
+ (NSString*)secondsFromTInterval:(NSTimeInterval)interval;
@end
