//
//  TRTorrentInfoViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTorrentPathViewController.h"

#define extTorrentVCident @"torrentInfoViewController"

@class TRExtTorrent;
@interface TRTorrentInfoViewController : UITableViewController <setDownloadPathProtocol>
@property (nonatomic,retain) TRExtTorrent *torrent;
@end
