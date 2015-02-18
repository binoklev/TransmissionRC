//
//  TRTorrentStateFilesViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 29.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TRTorrent;
@interface TRTorrentStateFilesViewController : UITableViewController
@property (nonatomic, retain) NSArray *files;
@property (nonatomic, retain) NSString *name;
@end
