//
//  Defines.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#ifndef iTMRemote_Defines_h
#define iTMRemote_Defines_h

#define TR_APP_NAME @"Transmission Remote"

//#define VM_HTTP_VERBOSE

#define TR_URL_PATH_DEFAULT     @"transmission/rpc"
#define TR_URL_PORT_DEFAULT     9091
#define TR_URL_PROTO_DEFAULT    @"http"

#define TR_HEADER_SESSIONID     @"X-Transmission-Session-Id"

#define TR_ERROR_CODE_SESSION_ERROR         409
#define TR_ERROR_CODE_SERVER_RESPONSE       599
#define TR_ERROR_CODE_JSON_FORMAT           10111

#define TR_JSON_KEY_METHOD  @"method"
#define TR_JSON_KEY_METHOD_TORRENT_GET @"torrent-get"
#define TR_JSON_KEY_METHOD_TORRENT_SET @"torrent-set"
#define TR_JSON_KEY_METHOD_SESSION_GET @"session-get"
#define TR_JSON_KEY_METHOD_TORRENT_ADD @"torrent-add"
#define TR_JSON_KEY_METHOD_TORRENT_REMOVE   @"torrent-remove"
//#define TR_JSON_KEY_METHOD_TORRENT_START    @"torrent-start"
//#define TR_JSON_KEY_METHOD_TORRENT_START_NOW    @"torrent-start-now"
//#define TR_JSON_KEY_METHOD_TORRENT_STOP     @"torrent-stop"
//#define TR_JSON_KEY_METHOD_TORRENT_VERIFY   @"torrent-verify"
//#define TR_JSON_KEY_METHOD_TORRENT_REANNONCE    @"torrent-reannounce"

static NSString* torrentActions[5] = {@"torrent-start",
                                      @"torrent-start-now",
                                      @"torrent-stop",
                                      @"torrent-verify",
                                      @"torrent-reannounce"};
typedef enum : NSUInteger {
    kTorrentStart = 0,
    kTorrentStartNow,
    kTorrentStop,
    kTorrentVerify,
    kTorrentReannonce
} torrentActionsEnum;

// filter types
enum {
    kFilterTorrents = 0,
    kFilterFolders,
    kFilterTrackers,
    kFiltersCount
};

enum {
    kFilterTorrentsAll = 0,
    kFilterTorrentsActive,
    kFilterTorrentsDownloading,
    kFilterTorrentsSeeding,
    kFilterTorrentsPaused,
    kFilterTorrentsCount
} enumFilter;

static NSString *filterStrings[5] = {@"Show All",@"Active",@"Downloading",@"Seeding",@"Paused"};


#define TR_JSON_KEY_TAG     @"tag"
#define TR_JSON_KEY_RESULT  @"result"
#define TR_JSON_KEY_RESULT_SUCCESS  @"success"
#define TR_JSON_KEY_RESULT_NO_METHOD @"no method name"
#define TR_JSON_KEY_RESULT_TORRENT_ADDED  @"torrent-added"

#define TR_JSON_KEY_ARGUMENTS     @"arguments"

#define TR_JSON_KEY_ARGUMENTS_FIELDS    @"fields"
#define TR_JSON_KEY_ARGUMENTS_TORRENTS  @"torrents"

#define TR_JSON_KEY_ARGUMENTS_IDS       @"ids"

#define TR_JSON_KEY_ARGUMENTS_DOWNLOAD_DIR  @"download-dir"
#define TR_JSON_KEY_ARGUMENTS_METAINFO      @"metainfo"
#define TR_JSON_KEY_ARGUMENTS_PAUSED        @"paused"
#define TR_JSON_KEY_ARGUMENTS_FILES_WANTED  @"files-wanted"
#define TR_JSON_KEY_ARGUMENTS_DELETE_LOCAL_DATA    @"delete-local-data"

// Profiles/accounts
#define TR_DEFAULTS_KEY_FILTER @"TR_DEFAULTS_KEY_FILTER"
#define TR_DEFAULTS_KEY_SORT_ORDER @"TR_DEFAULTS_KEY_SORT_ORDER"
#define TR_DEFAULTS_KEY_SORT_REVERSED  @"TR_DEFAULTS_KEY_SORT_REVERSED"

#define TR_DEFAULTS_KEY_ACCOUNT_HOST   @"accountHost"
#define TR_DEFAULTS_KEY_ACCOUNT_SSL    @"TR_DEFAULTS_KEY_ACCOUNT_SSL"
#define TR_DEFAULTS_KEY_ACCOUNT_PORT   @"accountPort"
#define TR_DEFAULTS_KEY_ACCOUNT_DIR    @"accountDir"
#define TR_DEFAULTS_KEY_ACCOUNT_LAST_PATH    @"TR_DEFAULTS_KEY_ACCOUNT_LAST_PATH"

#define TR_COLOR    [UIColor colorWithWhite:0.17 alpha:1.0]
#define TR_BLUE_COLOR [UIColor colorWithRed:0.17 green:0.66 blue:0.88  alpha:1.0]
#define TR_HEADER_COLOR [UIColor colorWithWhite:248.0/255.0 alpha:1.0];
#define TR_TINT_COLOR   [UIColor colorWithRed:92.0/255.0 green:116.0/255.0 blue:142.f/255.f alpha:1.0]

#define TR_NOTIFICATION_SESSION_DATA_UPDATED    @"TR_NOTIFICATION_SESSION_DATA_UPDATED"
#define TR_NOTIFICATION_TORR_LIST_UPDATED       @"TR_NOTIFICATION_TORR_LIST_UPDATED"
#define TR_NOTIFICATION_TORR_RECENT_UPDATED     @"TR_NOTIFICATION_TORR_RECENT_UPDATED"
#define TR_NOTIFICATION_DISCONNECTED    @"TR_NOTIFICATION_DISCONNECTED"

#define TR_NOTIFICATION_TORRENT_UPDATED         @"TR_NOTIFICATION_TORRENT_UPDATED"
#define TR_NOTIFICATION_TORRENT_STATUS_CHANGED  @"TR_NOTIFICATION_TORRENT_STATUS_CHANGED"
#define TR_NOTIFICATION_TORRENT_ADDED           @"TR_NOTIFICATION_TORRENT_ADDED"
#define TR_NOTIFICATION_TORRENT_INFO_UPDATED    @"TR_NOTIFICATION_TORRENT_INFO_UPDATED"
#define TR_NOTIFICATION_TORRENT_FILE_PARSED     @"TR_NOTIFICATION_TORRENT_FILE_PARSED"

#define TR_NOTIFICATION_FILTER_SELECTED    @"TR_NOTIFICATION_FILTER_SELECTED"

#define TR_UPDATING_INTERVAL    5.0
#endif
