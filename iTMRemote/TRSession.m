//
//  TRSession.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 01.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRSession.h"
/*
{
 "alt-speed-down": 50,
 "alt-speed-enabled": false,
 "alt-speed-time-begin": 540,
 "alt-speed-time-day": 127,
 "alt-speed-time-enabled": false,
 "alt-speed-time-end": 1020,
 "alt-speed-up": 50,
 "blocklist-enabled": false,
 "blocklist-size": 0,
 "blocklist-url": "http://www.example.com/blocklist",
 "cache-size-mb": 4,
 "config-dir": "/var/lib/transmission-daemon/info",
 "dht-enabled": true,
 "download-dir": "/opt/public",
 "download-dir-free-space": 91171364864,
 "download-queue-enabled": true,
 "download-queue-size": 5,
 "encryption": "preferred",
 "idle-seeding-limit": 30,
 "idle-seeding-limit-enabled": false,
 "incomplete-dir": "/home/igor/Downloads",
 "incomplete-dir-enabled": false,
 "lpd-enabled": false,
 "peer-limit-global": 240,
 "peer-limit-per-torrent": 60,
 "peer-port": 51413,
 "peer-port-random-on-start": false,
 "pex-enabled": true,
 "port-forwarding-enabled": false,
 "queue-stalled-enabled": true,
 "queue-stalled-minutes": 30,
 "rename-partial-files": true,
 "rpc-version": 14,
 "rpc-version-minimum": 1,
 "script-torrent-done-enabled": false,
 "script-torrent-done-filename": "",
 "seed-queue-enabled": false,
 "seed-queue-size": 10,
 "seedRatioLimit": 2,
 "seedRatioLimited": false,
 "speed-limit-down": 100,
 "speed-limit-down-enabled": false,
 "speed-limit-up": 100,
 "speed-limit-up-enabled": false,
 "start-added-torrents": true,
 "trash-original-torrent-files": false,
 "units":
 {
 "memory-bytes": 1024,
 "memory-units":
 [
 "KiB",
 "MiB",
 "GiB",
 "TiB"
 ],
 "size-bytes": 1000,
 "size-units":
 [
 "kB",
 "MB",
 "GB",
 "TB"
 ],
 "speed-bytes": 1000,
 "speed-units":
 [
 "kB/s",
 "MB/s",
 "GB/s",
 "TB/s"
 ]
 },
 "utp-enabled": true,
 "version": "2.51 (13280)"
 }
*/

@interface TRSession()
@property (nonatomic, retain) NSDictionary *inDictionary;
@end

@implementation TRSession
- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    if (self=[super init]) {
        self.inDictionary = [dictionary objectForKey:TR_JSON_KEY_ARGUMENTS];
        _downloadDir = [self.inDictionary objectForKey:@"download-dir"];
        _freeSpace = [[self.inDictionary valueForKey:@"download-dir-free-space"] longLongValue];
    }
    return self;
}
@end
