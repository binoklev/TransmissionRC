//
//  TRExtTorrent.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRExtTorrent.h"

@implementation TRExtTorrent

- (void)flatOutTheArray:(NSArray*)arr toMutableArray:(NSMutableArray**)marr {
    for (id obj in arr) {
        if ([obj isKindOfClass:[NSString class]]) {
            [*marr addObject:obj];
        }
        else if ([obj isKindOfClass:[NSArray class]]) {
            [self flatOutTheArray:obj toMutableArray:marr];
        }
    }
}


- (instancetype)initWithDictionary:(NSDictionary*)dict {
    if (self = [super init]) {
        NSArray *keys = [dict allKeys];
        if ([keys containsObject:TR_KEY_TORRENT_ENCODING]) {
            NSString *encoding = [dict objectForKey:TR_KEY_TORRENT_ENCODING];
            if ( ! [@"UTF-8" isEqualToString:encoding]) {
                return self;
            }
        }
        self.annonce = [dict objectForKey:TR_KEY_TORRENT_ANNOUNCE];
        NSArray *arr = [dict objectForKey:TR_KEY_TORRENT_ANNOUNCE_LIST];
        NSMutableArray *marr = [NSMutableArray array];
        [self flatOutTheArray:arr toMutableArray:&marr];
        self.annonceList = marr;
        self.comment = [dict objectForKey:TR_KEY_TORRENT_COMMENT];
        self.createdBy = [dict objectForKey:TR_KEY_TORRENT_CREATED_BY];
        if ([keys containsObject:TR_KEY_TORRENT_CREATION_DATE]) {
            self.creationDate = [NSDate dateWithTimeIntervalSince1970:[[dict valueForKey:TR_KEY_TORRENT_CREATION_DATE] floatValue]];
        }
        self.publisher = [dict objectForKey:TR_KEY_TORRENT_PUBLISHER];
        self.publisherUrl = [dict objectForKey:TR_KEY_TORRENT_PUBLISHER_URL];

        NSDictionary *info = [dict objectForKey:TR_KEY_TORRENT_INFO];
        self.name = [info objectForKey:@"name.utf-8"];
        if (! self.name) {
            self.name = [info objectForKey:TR_JSON_KEY_TORRENT_NAME];
        }
        self.piecesLength = (NSUInteger)[[info valueForKey:TR_KEY_TORRENT_INFO_PIECE_LENGTH] longLongValue];
        self.pieces = [info objectForKey:TR_KEY_TORRENT_INFO_PIECES];

        arr = [info objectForKey:TR_KEY_TORRENT_INFO_FILES];
        self.totalSize = 0;
        self.files = nil;
        if (arr) {
            marr = [NSMutableArray array];
            // calculate total size
            for (NSDictionary *fdic in arr) {
                long long size = [[fdic valueForKey:TR_KEY_TORRENT_INFO_FILES_LENGTH] longLongValue];
                self.totalSize += size;
                NSArray *parr = [fdic objectForKey:TR_KEY_TORRENT_INFO_FILES_PATH];
                [self flatOutTheArray:parr toMutableArray:&marr];
            }
            if ([marr count]) {
                self.files = marr;
                // create selected files array
                NSMutableArray *seld = [NSMutableArray arrayWithCapacity:marr.count];
                for (id obj in marr) {
                    if (obj) {
                        [seld addObject:[NSNumber numberWithBool:YES]];
                    }
                }
                self.selectedFiles = seld;
            }
        }
        else {
            self.totalSize = [[info valueForKey:TR_KEY_TORRENT_INFO_FILES_LENGTH] longLongValue];
        }
    }
    return self;
}

@end
