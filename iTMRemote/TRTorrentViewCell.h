//
//  TRTorrentViewCell.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 19.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TRTorrent;

@interface TRTorrentViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *commandButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratioLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic,retain) TRTorrent *torrent;
@end
