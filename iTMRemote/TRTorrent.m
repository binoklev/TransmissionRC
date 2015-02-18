//
//  TRTorrent.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrent.h"
#import "TRTransmissionClient.h"
#import "TRSession.h"

@implementation TRTorrent

+ (NSArray*)requestFields {
    return @[@"activityDate",
             TR_JSON_KEY_TORRENT_ID,
             TR_JSON_KEY_TORRENT_NAME,
             TR_JSON_KEY_TORRENT_ADDED_DATE,
             TR_JSON_KEY_TORRENT_TOTAL_SIZE,
             @"downloadDir",
             TR_JSON_KEY_TORRENT_DOWNLOADED_EVER,
             TR_JSON_KEY_TORRENT_UPLOADED_EVER,
             TR_JSON_KEY_TORRENT_UPLOAD_RATIO,
             TR_JSON_KEY_TORRENT_IS_FINISHED,
             TR_JSON_KEY_TORRENT_STATUS,
             TR_JSON_KEY_TORRENT_PEERS_CONNECTED,
             TR_JSON_KEY_TORRENT_PEERS_GETTING_FROM_US,
             TR_JSON_KEY_TORRENT_PEERS_SENDING_TO_US,
             TR_JSON_KEY_TORRENT_QUEUE_POSITION,
             TR_JSON_KEY_TORRENT_RATE_DOWNLOAD,
             TR_JSON_KEY_TORRENT_RATE_UPLOAD,
             @"trackerStats"
             ];
}

+ (NSArray*)requestTorrentInfoFields {
    return @[TR_JSON_KEY_TORRENT_ID,
             @"activityDate",
             @"corruptEver",
             @"desiredAvailable",
             @"downloadDir",
             TR_JSON_KEY_TORRENT_DOWNLOADED_EVER,
             @"fileStats",
             @"haveUnchecked",
             @"haveValid",
             @"peers",
             @"startDate",
             @"trackerStats",
             @"webseedsSendingToUs",
             @"comment",
             @"creator",
             @"dateCreated",
             @"files",
             @"hashString",
             @"isPrivate",
             @"pieceCount",
             @"pieceSize",
             TR_JSON_KEY_TORRENT_QUEUE_POSITION
             ];
}

- (instancetype)initWithDictionary:(NSDictionary*)dict {
    if (self = [super init]) {
        self.activityDate = [[dict valueForKey:@"activityDate"] longLongValue];
        self.ident = [[dict valueForKey:TR_JSON_KEY_TORRENT_ID] integerValue];
        self.name = [dict objectForKey:TR_JSON_KEY_TORRENT_NAME];
        self.status = [[dict valueForKey:TR_JSON_KEY_TORRENT_STATUS] longLongValue];
        self.isFinished = [[dict valueForKey:TR_JSON_KEY_TORRENT_IS_FINISHED] boolValue];
        self.totalSize = [[dict valueForKey:TR_JSON_KEY_TORRENT_TOTAL_SIZE] longLongValue];
        self.downloadedEver = [[dict valueForKey:TR_JSON_KEY_TORRENT_DOWNLOADED_EVER] longLongValue];
        self.uploadedEver = [[dict valueForKey:TR_JSON_KEY_TORRENT_UPLOADED_EVER] longLongValue];
        self.uploadRatio = [[dict valueForKey:TR_JSON_KEY_TORRENT_UPLOAD_RATIO] doubleValue];
        self.peersConnected = [[dict valueForKey:TR_JSON_KEY_TORRENT_PEERS_CONNECTED] longLongValue];
        self.peersGettingFromUs = [[dict valueForKey:TR_JSON_KEY_TORRENT_PEERS_GETTING_FROM_US] longLongValue];
        self.peersSendingToUs = [[dict valueForKey:TR_JSON_KEY_TORRENT_PEERS_SENDING_TO_US] longLongValue];
        self.rateDownload = [[dict valueForKey:TR_JSON_KEY_TORRENT_RATE_DOWNLOAD] longLongValue];
        self.rateUpload = [[dict valueForKey:TR_JSON_KEY_TORRENT_RATE_UPLOAD] longLongValue];
        self.addedDate = [[dict valueForKey:TR_JSON_KEY_TORRENT_ADDED_DATE] longLongValue];
        self.queuePosition = [[dict valueForKey:TR_JSON_KEY_TORRENT_QUEUE_POSITION] longLongValue];
        NSArray *arr = [dict objectForKey:@"trackerStats"];
        NSDictionary *trackerDic = [arr firstObject];
        NSURL *url = [NSURL URLWithString:[trackerDic objectForKey:@"host"]];
        NSString *host = [url host];
        if ([host hasPrefix:@"bt"]) {
            NSRange range = [host rangeOfString:@"."];
            if (range.location < 5) {
                host = [host substringFromIndex:range.location+1];
            }
        }
        self.tracker = host;
        NSString *dir = [dict objectForKey:@"downloadDir"];
        NSString *def = [[[TRTransmissionClient sharedTRTransmissionClient] session] downloadDir];
        if ([dir hasPrefix:def]) {
            dir = [dir substringFromIndex:[def length]];
        }
        if ([dir hasPrefix:@"/"]) {
            dir = [dir substringFromIndex:1];
        }
        if ([dir hasSuffix:@"/"]) {
            dir = [dir substringWithRange:NSMakeRange(0, dir.length - 1)];
        }
        self.downloadDir = dir;
    }
    return self;
}

- (BOOL)isEqualToTorrent:(TRTorrent*)torrent {
    if (self.ident != torrent.ident)
        return NO;
    if (self.addedDate != torrent.addedDate)
        return NO;
    if (self.totalSize != torrent.totalSize)
        return NO;
    if (![self.downloadDir isEqualToString:torrent.downloadDir])
        return NO;
    if (self.downloadedEver != torrent.downloadedEver)
        return NO;
    if (self.uploadedEver != torrent.uploadedEver)
        return NO;
    if (self.uploadRatio != torrent.uploadRatio)
        return NO;
    if (self.peersConnected != torrent.peersConnected)
        return NO;
    if (self.peersGettingFromUs != torrent.peersGettingFromUs)
        return NO;
    if (self.peersSendingToUs != torrent.peersSendingToUs)
        return NO;
    if (self.rateUpload != torrent.rateUpload)
        return NO;
    if (self.rateDownload != torrent.rateDownload)
        return NO;
    if (self.queuePosition != torrent.queuePosition)
        return NO;
    if (self.status != torrent.status)
        return NO;
    return ([self.name isEqualToString:torrent.name]);
}

- (void)fillValuesFromTorrent:(TRTorrent*)torrent {
    self.ident = torrent.ident;
    self.status = torrent.status;
    self.isFinished = torrent.isFinished;
    self.totalSize = torrent.totalSize;
    self.downloadedEver = torrent.downloadedEver;
    self.uploadedEver = torrent.uploadedEver;
    self.uploadRatio = torrent.uploadRatio;
    self.peersConnected = torrent.peersConnected;
    self.peersGettingFromUs = torrent.peersGettingFromUs;
    self.peersSendingToUs = torrent.peersSendingToUs;
    self.rateUpload = torrent.rateUpload;
    self.rateDownload = torrent.rateDownload;
    self.name = torrent.name;
    self.addedDate = torrent.addedDate;
    self.queuePosition = torrent.queuePosition;
    self.downloadDir = torrent.downloadDir;
    self.tracker = torrent.tracker;
}

@end
