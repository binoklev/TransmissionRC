//
//  TRTransmissionClient.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "transmission.h"

@class TRConnection;
@class TRAccount;
@class TRSession;
@class TRTorrent;
@class TRExtTorrent;

@interface TRTransmissionClient : NSObject

/**
 * singleton
 */
+ (TRTransmissionClient*)sharedTRTransmissionClient;
/**
 *  Selected account
 */
@property (nonatomic,retain) TRAccount *account;
/**
 * Selected account's host is reachable via net
 */
@property (nonatomic, assign) BOOL  reachable;
/**
 * current server session params
 */
@property (nonatomic,retain) TRSession *session;
/**
 * list of torrents
 */
@property (nonatomic,retain) __block NSArray *torrents;
/**
 * list of incoming torrent files
 */
@property (nonatomic,retain) __block NSMutableArray *files;
/**
 * index path(section,row) of selected filter
 */
@property (nonatomic,retain) NSIndexPath *filterPath;
/**
 *  count of torrents files pathes
 */
@property (nonatomic,retain) NSArray *pathes;
/**
 *  count of torrents trackers
 */
@property (nonatomic,retain) NSArray *trackers;


- (void)getSessionWithErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)(TRSession*))successBlock;
- (void)disconnect;

/**
 *  Method updated List of torrents from server,
 *  send notification with torrents array object 
 *  and starting update recent torrents loop
 */
- (void)updateListOfTorrents;
/**
 *  Manual starting update recent torrents loop
 */
- (void)startUpdatingTimer;
- (void)stopUpdateRecentTorrentsLoop;
/**
 *  Metod requests rescently updated torrents, merges result with
 *  exists torrents and sends notification to updated torrents
 */
- (void)updateRecentTorrents;

/**
 *  Metod update torrent info and return result as dictionary
 *  @param torrent - torrent for update info
 */
- (void)updateTorrent:(TRTorrent*)torrent withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)(NSDictionary*))successBlock;

- (void)addTorrent:(TRExtTorrent*)torrent toPath:(NSString*)path paused:(BOOL)paused toTop:(BOOL)toTop withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock;
/**
 *  Method for delete torrent
 *  @param torrent - MUST NOT BE nil
 *  @param deleteLocalData - wether delete files from server
 */
- (void)deleteTorrent:(TRTorrent*)torrent withLocalData:(BOOL)deleteLocalData withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock;
/**
 * Method for set action to one or all torrents
 * @param action is a constant member of torrentActionsEnum
 * @param torrent - if nil then action sets to all torrents on server
 */
- (void)setAction:(torrentActionsEnum)action forTorrent:(TRTorrent*)torrent withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock;
/**
 * Getter of filtered torrents list
 * @param filterPath is an indexPath(section,row) of selected filter
 * @return array of filtered torrents from self.torrents
 */
- (NSArray*)torrentsWithFilterPath:(NSIndexPath*)filterPath;
@end
