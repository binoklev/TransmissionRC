//
//  TRTorrentStateTableViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 06.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TRTorrent;
@interface TRTorrentStateTableViewController : UITableViewController
@property (nonatomic,retain) TRTorrent *torrent;
@end
