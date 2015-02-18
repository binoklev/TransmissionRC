//
//  NSString+formats.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 07.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "NSString+formats.h"

@implementation NSString (formats)

+ (NSString*)bytesSecFromLong:(long long)value {
    float kbs = value / 1024.f;
    if (kbs > 1000.0) {
        float mbs = kbs/1024.f;
        return [NSString stringWithFormat:@"%4.2f MB/s", mbs];
    }
    else {
        return [NSString stringWithFormat:@"%3.1f kB/s", kbs];
    }
}

+ (NSString*)bytesFromLong:(long long)value {
    float mb = (value / 1024.f) / 1024.f;
    if (mb > 1000.0) {
        float gb = mb/1024.f;
        return [NSString stringWithFormat:@"%4.2f GB", gb];
    }
    else {
        return [NSString stringWithFormat:@"%3.1f MB", mb];
    }
}

+ (NSString*)secondsFromTInterval:(NSTimeInterval)interval {
    if (interval > 365*60*60*24) {
        return [NSString stringWithFormat:@"%ld years", (long)(interval/(365*60*60*24))];
    } else if (interval > 30*60*60*24) {
        return [NSString stringWithFormat:@"%ld monthes", (long)(interval/(30*60*60*24))];
    } else if (interval > 60*60*24) {
        return [NSString stringWithFormat:@"%ld days", (long)(interval/(60*60*24))];
    } else if (interval > 60*24) {
        return [NSString stringWithFormat:@"%ld hours", (long)(interval/(60*24))];
    } else if (interval > 60) {
        return [NSString stringWithFormat:@"%ld minutes", (long)interval/60];
    } else {
        return [NSString stringWithFormat:@"%ld seconds", (long)interval];
    }

}

@end
