//
//  TRTorrentFilesViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TRExtTorrent;
@interface TRTorrentFilesViewController : UITableViewController
@property (nonatomic,retain) TRExtTorrent *torrent;
@end
