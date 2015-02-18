//
//  TRTorrentParser.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 28.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TR_PREFIX_DICTIONARY    'd'
#define TR_PREFIX_END           'e'
#define TR_PREFIX_LIST          'l'
#define TR_PREFIX_INT           'i'

@interface TRTorrentParser : NSObject

- (NSDictionary*)parseBuffer:(NSData*)data;

@end
