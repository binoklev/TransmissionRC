//
//  TRBaseTorrent.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TR_JSON_KEY_TORRENT_NAME   @"name"
#define TR_JSON_KEY_TORRENT_TOTAL_SIZE @"totalSize"

static NSString* torrentStatusStings[7] = {@"Paused", @"Check waiting", @"Checking",
    @"Download waiting", @"Downloading", @"Seed waiting", @"Seeding"};

@interface TRBaseTorrent : NSObject

@property (retain, nonatomic) NSString *name;
@property (assign, nonatomic) long long totalSize;

@end
