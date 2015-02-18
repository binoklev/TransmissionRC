//
//  TRTransmissionClient.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTransmissionClient.h"
#import "TRConnection.h"
#import "TRAccount.h"
#import "TRTorrent.h"
#import "TRExtTorrent.h"
#import "TRSession.h"
#import "NSString+Base64.h"
#import "Reachability.h"

@interface TRTransmissionClient() {
    /**
     * Transmission server requests tag
     */
    NSUInteger _tag;
}
// private
@property (nonatomic, retain) NSMutableDictionary *connections;
@property (nonatomic, retain) NSString *sessionID;
@property (nonatomic, retain) Reachability *reachability;
@property (nonatomic,retain) NSTimer *updatingTimer;

@end

void (^errorBlock)(NSError *) = ^(NSError *error){
    NSString *str = [NSString stringWithFormat:@"Server connection error: %@", error.localizedDescription];
    [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                message:str
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
};

@implementation TRTransmissionClient

SINGLETON(TRTransmissionClient);

- (instancetype)init {
    if (self=[super init]) {
        self.connections = [NSMutableDictionary dictionary];
        self.files = [NSMutableArray array];
        _tag = 1;
        self.pathes = @[];
        self.trackers = @[];
        
        NSInteger filter = [USER_DEFAULTS integerForKey:TR_DEFAULTS_KEY_FILTER];
        if (filter >= kFilterTorrentsCount) {
            filter = kFilterTorrentsAll;
        }
        _filterPath = [NSIndexPath indexPathForRow:filter inSection:kFilterTorrents];
    }
    return self;
}

- (void)disconnect {
    [self stopUpdateRecentTorrentsLoop];
    [self cancelAllRequests];
    self.torrents =nil;
    self.session = nil;
    NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_DISCONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
}

#pragma mark - properties

- (void)setAccount:(TRAccount *)account {
    _account = account;
    self.sessionID = nil;
    self.reachable = YES;
    if (self.reachability) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kReachabilityChangedNotification
                                                      object:self.reachability];
        self.reachability = nil;
        [self cancelAllRequests];
    }
    // update connection
    [self initSession];
}

- (void)setFilterPath:(NSIndexPath *)filterPath {
    if ( [self.filterPath compare:filterPath] == NSOrderedSame ) {
        return;
    }
    _filterPath = filterPath;
    if (filterPath.row >= kFilterTorrentsCount)
        [USER_DEFAULTS setInteger:kFilterTorrentsAll forKey:TR_DEFAULTS_KEY_FILTER];
    else
        [USER_DEFAULTS setInteger:filterPath.row forKey:TR_DEFAULTS_KEY_FILTER];
    [USER_DEFAULTS synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TR_NOTIFICATION_FILTER_SELECTED object:filterPath userInfo:nil];
}

#pragma mark - filters usage 

- (NSArray*)torrentsWithFilterPath:(NSIndexPath*)filterPath {
    NSMutableArray *marr = [NSMutableArray array];
    if (filterPath.section == kFilterTorrents && filterPath.row == kFilterTorrentsAll) {
        return  self.torrents;
    }
    
    for (TRTorrent *torrent in self.torrents) {
        switch (filterPath.section) {
            case kFilterTorrents:
            {
                switch (filterPath.row) {
                    case kFilterTorrentsActive:
                        if ( torrent.peersConnected > 0 )
                            [marr addObject:torrent];
                        break;
                    case kFilterTorrentsDownloading:
                        if (torrent.status == TR_STATUS_DOWNLOAD)
                            [marr addObject:torrent];
                        break;
                    case kFilterTorrentsSeeding:
                        if (torrent.status == TR_STATUS_SEED)
                            [marr addObject:torrent];
                        break;
                    case kFilterTorrentsPaused:
                        if (torrent.status == TR_STATUS_STOPPED)
                            [marr addObject:torrent];
                        break;
                    default:
                        break;
                }                
            }
                break;
            case kFilterFolders:
                if ([torrent.downloadDir hasSuffix:self.pathes[filterPath.row]]) {
                    [marr addObject:torrent];
                }
                break;
            case kFilterTrackers:
                if ([torrent.tracker hasSuffix:self.trackers[filterPath.row]]) {
                    [marr addObject:torrent];
                }
                break;
            default:
                break;
        }
    }
    return marr;
}

#pragma mark - Notifications

- (void)onReachabilityChanged:(NSNotification*)notif {
    NetworkStatus netStatus = [self.reachability currentReachabilityStatus];
    BOOL reach = (netStatus != NotReachable );
    
    self.reachable = reach;
    
    DLog(@"onReachabilityChanged netStatus:%ld reachable:%d", (long)netStatus, self.reachable);
    
    // cancel all request in any case of connection change (wifi/cellular)
    [self stopUpdateRecentTorrentsLoop];
    [self cancelAllRequests];
    if (self.reachable ){
        // update connection
        [self initSession];
    }
}

#pragma mark - work with updating timer

- (void)startUpdatingTimer {
    DLog(@"start updating timer");
    if (self.updatingTimer) {
        [self.updatingTimer invalidate];
    }
    self.updatingTimer = [NSTimer timerWithTimeInterval:TR_UPDATING_INTERVAL target:self selector:@selector(onUpdatingTimer:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.updatingTimer forMode:NSDefaultRunLoopMode];
}

- (void)onUpdatingTimer:(NSTimer*)timer {
    [self updateRecentTorrents];
}

- (void)stopUpdateRecentTorrentsLoop {
    if (self.updatingTimer) {
        [self.updatingTimer invalidate];
        self.updatingTimer = nil;
    }
}

#pragma mark - connections management

- (void)cancelAllRequests {
    DLog(@"cancelAllRequests");
    for (TRConnection *trcon in [self.connections allValues]) {
        DLog(@"Cancel %@", trcon);
        [trcon cancel];
        trcon.data = nil;
    }
    [self.connections removeAllObjects];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - private common post methods

- (TRConnection*)postRequestWithJSONDictionary:(NSDictionary*)data errorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)(NSDictionary*))successBlock {
    // clean the cache
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.account.connectionString]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPMethod:@"POST"];
    if (self.sessionID) {
        [request setAllHTTPHeaderFields:@{TR_HEADER_SESSIONID: self.sessionID}];
    }
    
#ifdef VM_HTTP_VERBOSE
    DLog(@"POST request: %@", request);
#endif
    if (data) {
        NSAssert([data isKindOfClass:[NSDictionary class]], @"Wrong request data format!");
        if ([NSJSONSerialization isValidJSONObject:data]) {
            // add a tag
            NSMutableDictionary *dic2 = [NSMutableDictionary dictionaryWithDictionary:data];
            [dic2 setValue:@(_tag) forKey:TR_JSON_KEY_TAG];
#ifdef VM_HTTP_VERBOSE
            DLog(@"POST request data: %@", dic2);
#endif
            NSError *error;
            NSData *body = [NSJSONSerialization dataWithJSONObject:dic2 options:NSJSONWritingPrettyPrinted error:&error];
            if (error) {
                errorBlock(error);
            }
            else {
                [request setHTTPBody:body];
            }
        }
        else {
            NSError *newError = [NSError errorWithDomain:NSMachErrorDomain code:TR_ERROR_CODE_JSON_FORMAT userInfo:@{NSLocalizedDescriptionKey:@"JSON format error"}];
            errorBlock(newError);
        }
    }
    
    TRConnection *vmcon = [[TRConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    vmcon.tag = _tag;
    if (vmcon) {
        
        vmcon.errorBlock = ^(NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            // check session_id error
            DLog(@"Request error: %@",error);
            if (error.code == TR_ERROR_CODE_SESSION_ERROR && self.sessionID) {
                // new sessionID saved, requery session
                [self performSelector:@selector(initSession)];
            }
            else
            {
                self.reachable = NO;
                [self cancelAllRequests];
                errorBlock(error);
            }
        };
        vmcon.successBlock = ^(NSData *data){
            self.reachable = YES;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSError *JSONerror;
            id info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&JSONerror];
            if (info && [info isKindOfClass:[NSDictionary class]]) {
#ifdef VM_HTTP_VERBOSE
                DLog(@"POST responce data: %@", info);
#endif
                NSDictionary *respDic = info;
                NSString *str = [respDic objectForKey:TR_JSON_KEY_RESULT];
                if ([TR_JSON_KEY_RESULT_SUCCESS isEqualToString:str] || [TR_JSON_KEY_RESULT_NO_METHOD isEqualToString:str]) {
                    successBlock(info);
                }
                else {
                    NSString *msg = [NSString stringWithFormat:@"Server response:\n%@", str];
                    NSError *newError = [NSError errorWithDomain:NSMachErrorDomain code:TR_ERROR_CODE_SERVER_RESPONSE userInfo:@{NSLocalizedDescriptionKey:msg}];
                    errorBlock(newError);
                }
            } else {
                NSString *resp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *str = [NSString stringWithFormat:@"Wrong server response, cant decode JSON %@ \n%@...", JSONerror.localizedDescription, [resp substringToIndex:(resp.length > 100) ? 100 : resp.length]];
                NSError *newError = [NSError errorWithDomain:NSMachErrorDomain code:TR_ERROR_CODE_SERVER_RESPONSE userInfo:@{NSLocalizedDescriptionKey:str}];
                errorBlock(newError);
            }
        };
        [self.connections setObject:vmcon
                             forKey:@(_tag++)];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [vmcon start];
    }
    return vmcon;
}

#pragma mark - public methods

- (void)initSession {
        if (! self.reachability) {
            self.reachability = [Reachability reachabilityWithHostName:self.account.host];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onReachabilityChanged:)
                                                         name:kReachabilityChangedNotification
                                                       object:self.reachability];
            [self.reachability startNotifier];
        }
    DLog(@"initSession");
        // update session
        [self getSessionWithErrorBlock:errorBlock
                       andSuccessBlock:^(TRSession *session) {
                           [self updateListOfTorrents];
                       }];
}

- (void)getSessionWithErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)(TRSession*))successBlock {
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: @[],
                          TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_SESSION_GET};
    [self postRequestWithJSONDictionary:dic
                             errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *respDic) {
                            
        self.session = [[TRSession alloc] initWithDictionary:respDic];
        NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_SESSION_DATA_UPDATED object:self.session];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
        successBlock(self.session);
    }];
}

- (void)updateListOfTorrents {
    
    if ( ! self.account) {
        return;
    }
    
    NSArray *fields = [TRTorrent requestFields];
    NSDictionary *args = @{TR_JSON_KEY_ARGUMENTS_FIELDS: fields,
                           //                           TR_JSON_KEY_ARGUMENTS_IDS: @[]
                           };
    
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                          TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_TORRENT_GET};
    
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock andSuccessBlock:^(NSDictionary *respDic) {
        
        NSDictionary *args = [respDic objectForKey:TR_JSON_KEY_ARGUMENTS];
        if (args && [args isKindOfClass:[NSDictionary class]]) {
            id obj = [args objectForKey:TR_JSON_KEY_ARGUMENTS_TORRENTS];
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray *arr = obj;
                // create torrents
                NSMutableArray *ma = [NSMutableArray array];
                NSMutableArray *mTrackers = [NSMutableArray array];
                NSMutableArray *mPathes = [NSMutableArray array];
                for (NSDictionary *dic in arr) {
                    TRTorrent *tor = [[TRTorrent alloc] initWithDictionary:dic];
                    if (tor) {
                        [ma addObject:tor];
                        // update pathes
                        BOOL found =NO;
                        for (NSString *path in mPathes) {
                            if ([tor.downloadDir isEqualToString:path]) {
                                found = YES;
                                break;
                            }
                        }
                        if (! found) {
                            [mPathes addObject:tor.downloadDir];
                        }
                        // update torrents
                        found =NO;
                        for (NSString *track in mTrackers) {
                            if ([tor.tracker isEqualToString:track]) {
                                found = YES;
                                break;
                            }
                        }
                        if (! found) {
                            [mTrackers addObject:tor.tracker];
                        }
                    }
                }
                self.torrents = ma;
                self.trackers = mTrackers;
                self.pathes = mPathes;
                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORR_LIST_UPDATED object:self.torrents];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            }
        }
    }];
}

- (void)updateRecentTorrents {
    DLog(@"Update Recent Torrents");
    NSArray *fields = [TRTorrent requestFields];
    
    NSDictionary *args = @{TR_JSON_KEY_ARGUMENTS_FIELDS: fields,
                           TR_JSON_KEY_ARGUMENTS_IDS: @"recently-active"
                           };
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                          TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_TORRENT_GET};
    
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *respDic) {
        
        NSDictionary *args = [respDic objectForKey:TR_JSON_KEY_ARGUMENTS];
        if (args && [args isKindOfClass:[NSDictionary class]]) {
            id obj = [args objectForKey:TR_JSON_KEY_ARGUMENTS_TORRENTS];
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray *arr = obj;
                for (NSDictionary *dic in arr) {
                    // create torrents and compare with exists
                    TRTorrent *tor = [[TRTorrent alloc] initWithDictionary:dic];
                    for (TRTorrent *torrent in self.torrents) {
                        if (tor.ident == torrent.ident) {
                            if ( ! [tor isEqualToTorrent:torrent])  {
                                [torrent fillValuesFromTorrent:tor];
                                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_UPDATED object:torrent];
                                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
                            }
                            break;
                        }
                    }
                }
                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORR_RECENT_UPDATED object:nil];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            }
        }
        // request the next update
        [self startUpdatingTimer];
    }];
}

#pragma mark - individual torrent operations

- (void)updateTorrent:(TRTorrent*)torrent withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)(NSDictionary*))successBlock {
    DLog(@"Update Torrent %@", torrent.name);
    NSArray *fields = [TRTorrent requestTorrentInfoFields];
    
    NSDictionary *args = @{TR_JSON_KEY_ARGUMENTS_FIELDS: fields,
                           TR_JSON_KEY_ARGUMENTS_IDS: @[@(torrent.ident)]
                           };
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                          TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_TORRENT_GET};
    
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *respDic) {
                            
                            NSDictionary *args = [respDic objectForKey:TR_JSON_KEY_ARGUMENTS];
                            if (args && [args isKindOfClass:[NSDictionary class]]) {
                                id obj = [args objectForKey:TR_JSON_KEY_ARGUMENTS_TORRENTS];
                                if ([obj isKindOfClass:[NSArray class]]) {
                                    NSArray *arr = obj;
                                    successBlock([arr firstObject]);
                                }
                            }
                        }];
}

- (void)addTorrent:(TRExtTorrent*)torrent toPath:(NSString*)path paused:(BOOL)paused toTop:(BOOL)toTop withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock {
    
    NSString *metainfo = [NSString base64StringFromData:torrent.externalFileContent length:0]; //[torrent.externalFileContent length]];

    NSMutableDictionary *args = [@{TR_JSON_KEY_ARGUMENTS_PAUSED: [NSNumber numberWithBool:paused],
                                   TR_JSON_KEY_ARGUMENTS_METAINFO:metainfo} mutableCopy];
    if (path) {
        [args setObject:path forKey:TR_JSON_KEY_ARGUMENTS_DOWNLOAD_DIR];
    }
    // check selected files
    if (torrent.selectedFiles) {
        NSMutableArray *marr = [NSMutableArray array];
        for (int i=0; i<torrent.selectedFiles.count; i++) {
            if ([torrent.selectedFiles[i] boolValue]) {
                [marr addObject:[NSNumber numberWithInt:i]];
            }
        }
        if (torrent.selectedFiles.count != marr.count) {
            [args setObject:marr forKey:TR_JSON_KEY_ARGUMENTS_FILES_WANTED];
        }
    }
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                          TR_JSON_KEY_METHOD:TR_JSON_KEY_METHOD_TORRENT_ADD};
    
    [self postRequestWithJSONDictionary:dic
                             errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *respDic) {
        
        NSDictionary *args = [respDic objectForKey:TR_JSON_KEY_ARGUMENTS];
        if (args && [args isKindOfClass:[NSDictionary class]]) {
            id obj = [args objectForKey:TR_JSON_KEY_RESULT_TORRENT_ADDED];
            if (obj) {
                // remove torrent file from array
                [self.files removeObject:torrent];
                
                if (toTop) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        NSInteger newId = [[(NSDictionary*)obj valueForKey:@"id"] integerValue];
                        if (newId) {
                            [self moveTorrentWithId:newId toTopOfQueueWithErrorBlock:errorBlock
                                    andSuccessBlock:
                             ^{
                                 [self updateListOfTorrents];
                             }];
                        }
                    }
                }
                else {
                    [self updateListOfTorrents];
                }

                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_ADDED object:nil];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
                successBlock();
            }
        }
    }];
}

- (void)moveTorrentWithId:(NSInteger)torrentId toTopOfQueueWithErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock {
    NSDictionary *dic =  @{TR_JSON_KEY_ARGUMENTS: @{TR_JSON_KEY_ARGUMENTS_IDS: @(torrentId),
                                                    @"queuePosition":@0},
                           TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_TORRENT_SET};
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *dic) {
                            [self updateListOfTorrents];
                            successBlock();
                        }];
}

- (void)deleteTorrent:(TRTorrent*)torrent withLocalData:(BOOL)deleteLocalData withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock {
    NSDictionary *args = @{TR_JSON_KEY_ARGUMENTS_IDS: @[@(torrent.ident)] ,
                           TR_JSON_KEY_ARGUMENTS_DELETE_LOCAL_DATA: @(deleteLocalData)
                           };
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                          TR_JSON_KEY_METHOD: TR_JSON_KEY_METHOD_TORRENT_REMOVE};
    
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock
                        andSuccessBlock:^(NSDictionary *dic) {
                            [self updateListOfTorrents];
                            successBlock();
                        }];
}

- (void)setAction:(torrentActionsEnum)action forTorrent:(TRTorrent*)torrent withErrorBlock:(void(^)(NSError*))errorBlock andSuccessBlock:(void(^)())successBlock {
    NSDictionary *args;
    if (torrent) {
        args = @{TR_JSON_KEY_ARGUMENTS_IDS: @[@(torrent.ident)]};
    }
    else {
        args = @{TR_JSON_KEY_ARGUMENTS_IDS: @[]};
    }
    NSDictionary *dic = @{TR_JSON_KEY_ARGUMENTS: args,
                TR_JSON_KEY_METHOD: torrentActions[action]};
    
    [self postRequestWithJSONDictionary:dic errorBlock:errorBlock
                        andSuccessBlock:successBlock];
}

#pragma mark - URLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSAssert([connection isKindOfClass:[TRConnection class]], @"Connection is not TRConnection class!");
    NSAssert([response isKindOfClass:[NSHTTPURLResponse class]], @"Responce is not NSHTTPURLResponse!");
    NSHTTPURLResponse *httpresp = (NSHTTPURLResponse*)response;
#ifdef VM_HTTP_VERBOSE
    DLog(@"Responce: %@", httpresp);
#endif
    TRConnection *vmcon = (TRConnection*)connection;
    if (httpresp.statusCode == 200) {
        vmcon.data = [NSMutableData data];
    }
    else {
        NSError *newError;
        if (httpresp.statusCode == TR_ERROR_CODE_SESSION_ERROR) {
            self.sessionID = [httpresp.allHeaderFields objectForKey:TR_HEADER_SESSIONID];
            DLog(@"SessionID updated to: %@", self.sessionID);
            newError = [NSError errorWithDomain:NSMachErrorDomain
                                           code:TR_ERROR_CODE_SESSION_ERROR
                                       userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Session wrong key",nil)}];
        }
        else {
            newError = [NSError errorWithDomain:NSMachErrorDomain
                                                    code:TR_ERROR_CODE_SERVER_RESPONSE
                                                userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"[Wrong server response]",nil)}];
        }
        [connection cancel];
        [self.connections removeObjectForKey:@(vmcon.tag)];
        DLog(@"self.connections: %@", self.connections);
        vmcon.errorBlock(newError);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([connection isKindOfClass:[TRConnection class]]) {
        TRConnection *vmcon = (TRConnection*)connection;
        if (vmcon.errorBlock) {
            vmcon.errorBlock(error);
        }
        [self.connections removeObjectForKey:@(vmcon.tag)];
        DLog(@"self.connections: %@", self.connections);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([connection isKindOfClass:[TRConnection class]]) {
        TRConnection *vmcon = (TRConnection*)connection;
#ifdef VM_HTTP_VERBOSE
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DLog(@"didReceiveData:>> %@", str);
#endif
        [vmcon.data appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([connection isKindOfClass:[TRConnection class]]) {
        TRConnection *vmcon = (TRConnection*)connection;
        // check sessionID
        
        if (vmcon.successBlock) {
            __block NSData *data = vmcon.data;
            vmcon.successBlock(data);
        }
        [self.connections removeObjectForKey:@(vmcon.tag)];
        DLog(@"self.connections: %@", self.connections);
    }
}

@end
