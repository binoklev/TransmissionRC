//
//  TRExtTorrent.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRBaseTorrent.h"

/*
 #define TR_JSON_KEY_TORRENT_NAME   @"name"
 #define TR_JSON_KEY_TORRENT_TOTAL_SIZE @"totalSize"
 
 @interface TRBaseTorrent : NSObject
 
 @property (retain, nonatomic) NSString *name;
 @property (assign, nonatomic) long long totalSize;
*/

#define TR_KEY_TORRENT_ANNOUNCE      @"announce"
#define TR_KEY_TORRENT_ANNOUNCE_LIST @"announce-list"
#define TR_KEY_TORRENT_COMMENT      @"comment"
#define TR_KEY_TORRENT_CREATED_BY   @"created by"
#define TR_KEY_TORRENT_CREATION_DATE    @"creation date"
#define TR_KEY_TORRENT_ENCODING     @"encoding"
#define TR_KEY_TORRENT_INFO         @"info"
#define TR_KEY_TORRENT_INFO_FILES       @"files"
#define TR_KEY_TORRENT_INFO_FILES_LENGTH    @"length"
#define TR_KEY_TORRENT_INFO_FILES_PATH      @"path"
#define TR_KEY_TORRENT_INFO_PIECE_LENGTH    @"piece length"
#define TR_KEY_TORRENT_INFO_PIECES  @"pieces"
#define TR_KEY_TORRENT_PUBLISHER    @"publisher"
#define TR_KEY_TORRENT_PUBLISHER_URL    @"publisher-url"


@interface TRExtTorrent : TRBaseTorrent

@property (nonatomic,retain) NSString *annonce;
@property (nonatomic,retain) NSArray  *annonceList;
@property (nonatomic,retain) NSString *comment;
@property (nonatomic,retain) NSString *createdBy;
@property (nonatomic,retain) NSDate   *creationDate;
@property (nonatomic,retain) NSArray  *files;
@property (nonatomic,retain) NSArray  *selectedFiles;
@property (nonatomic,assign) NSUInteger piecesLength;
@property (nonatomic,retain) NSData *pieces;
@property (nonatomic,retain) NSString *publisher;
@property (nonatomic,retain) NSString *publisherUrl;

@property (nonatomic,retain) NSURL *externalFileUrl;
@property (nonatomic,retain) NSData *externalFileContent;

- (instancetype)initWithDictionary:(NSDictionary*)dict;

@end
