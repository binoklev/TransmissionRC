//
//  TRTorrent.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRBaseTorrent.h"

#define TR_JSON_KEY_TORRENT_ID @"id"
#define TR_JSON_KEY_TORRENT_DOWNLOADED_EVER @"downloadedEver"
#define TR_JSON_KEY_TORRENT_UPLOADED_EVER   @"uploadedEver"
#define TR_JSON_KEY_TORRENT_UPLOAD_RATIO    @"uploadRatio"
#define TR_JSON_KEY_TORRENT_STATUS      @"status"
#define TR_JSON_KEY_TORRENT_PEERS_CONNECTED @"peersConnected"
#define TR_JSON_KEY_TORRENT_PEERS_GETTING_FROM_US @"peersGettingFromUs"
#define TR_JSON_KEY_TORRENT_PEERS_SENDING_TO_US @"peersSendingToUs"
#define TR_JSON_KEY_TORRENT_RATE_DOWNLOAD   @"rateDownload"
#define TR_JSON_KEY_TORRENT_RATE_UPLOAD     @"rateUpload"
#define TR_JSON_KEY_TORRENT_IS_FINISHED     @"isFinished"
#define TR_JSON_KEY_TORRENT_ADDED_DATE      @"addedDate"
#define TR_JSON_KEY_TORRENT_QUEUE_POSITION  @"queuePosition"

@interface TRTorrent : TRBaseTorrent

@property (assign, nonatomic) NSUInteger ident;
@property (assign, nonatomic) long long downloadedEver;
@property (assign, nonatomic) long long uploadedEver;
@property (assign, nonatomic) double    uploadRatio;
@property (assign, nonatomic) long long peersConnected;
@property (assign, nonatomic) long long peersGettingFromUs;
@property (assign, nonatomic) long long peersSendingToUs;
@property (assign, nonatomic) long long rateDownload;
@property (assign, nonatomic) long long rateUpload;

@property (assign, nonatomic) long long status;
@property (assign, nonatomic) BOOL isFinished;
@property (assign, nonatomic) long long addedDate;
@property (assign, nonatomic) long long activityDate;
@property (assign, nonatomic) long long queuePosition;

@property (nonatomic, retain) NSString *downloadDir;
@property (nonatomic, retain) NSString *tracker;

+ (NSArray*)requestFields;
+ (NSArray*)requestTorrentInfoFields;

- (instancetype)initWithDictionary:(NSDictionary*)dict;
/** 
 * method to check the torrent is updated
 * by comparing with another instance
 */
- (BOOL)isEqualToTorrent:(TRTorrent*)torrent;
/**
 * Copy inner values from another torrent
 */
- (void)fillValuesFromTorrent:(TRTorrent*)torrent;

@end
