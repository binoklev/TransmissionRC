//
//  TRTorrentViewCell.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 19.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentViewCell.h"
#import "TRTorrent.h"
#import "transmission.h"
#import "TRTransmissionClient.h"
#import "NSString+formats.h"

@implementation TRTorrentViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    self.commandButton.layer.borderColor = [[UIColor blackColor] CGColor];
//    self.commandButton.layer.borderWidth = 1.f;
//    self.commandButton.layer.cornerRadius = 15.f;
    [self updateFields];
}

- (void)setTorrent:(TRTorrent *)torrent {
    if (_torrent != torrent) {
        _torrent = torrent;
        if (_torrent) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:TR_NOTIFICATION_TORRENT_UPDATED object:_torrent];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTorrentUpdated:) name:TR_NOTIFICATION_TORRENT_UPDATED object:torrent];
        self.titleLabel.text = torrent.name;
        [self updateFields];
    }
}

- (void)updateFields {
    self.ratioLabel.text = [NSString stringWithFormat:@"%@, uploaded %@ (Ratio %4.2f)", [NSString bytesFromLong:self.torrent.totalSize], [NSString bytesFromLong:self.torrent.uploadedEver], self.torrent.uploadRatio];
    
    NSString *status;
    if (self.torrent.status>=0 && self.torrent.status<7) {
        status = torrentStatusStings[self.torrent.status];
    }
    switch (self.torrent.status) {
            
        case TR_STATUS_STOPPED:     /* Torrent is stopped */
        {
            self.progressView.progressTintColor = TR_TINT_COLOR;
            float progress = self.torrent.downloadedEver/(self.torrent.totalSize*1.0);
            if (progress < 1.0) {
                self.ratioLabel.text = [NSString stringWithFormat:@"%@ of %@ (%3.1f%%)", [NSString bytesFromLong:self.torrent.downloadedEver], [NSString bytesFromLong:self.torrent.totalSize], progress*100];
//                status = [NSString stringWithFormat:@"Paused. Downloaded %@ of %@", [self gbFromLong:self.torrent.downloadedEver],[self gbFromLong:self.torrent.totalSize]];
            }
            else {
                self.ratioLabel.text = [NSString stringWithFormat:@"%@, uploaded %@ (Ratio %4.2f)", [NSString bytesFromLong:self.torrent.totalSize], [NSString bytesFromLong:self.torrent.uploadedEver], self.torrent.uploadRatio];
            }
            [self.commandButton setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
        }
            break;
        case TR_STATUS_DOWNLOAD:    /* Downloading */
        {
            float progress = self.torrent.downloadedEver/(self.torrent.totalSize*1.0);
            self.progressView.progress = progress < 1.0 ? progress : 1.0;
            self.progressView.progressTintColor = [UIColor blueColor];
            status = [NSString stringWithFormat:@"Downloading from %lld of %lld peers - %@", self.torrent.peersSendingToUs, self.torrent.peersConnected, [NSString bytesSecFromLong:self.torrent.rateDownload]];
            
            NSString *remString;
            if (self.torrent.rateDownload > 0) {
                float remains = (self.torrent.totalSize - self.torrent.downloadedEver)/(self.torrent.rateDownload*1.f);
                remString = [NSString stringWithFormat:@"remaining:%@", [NSString secondsFromTInterval:remains]];
            }
            else {
                remString = @"remaining time unknown";
            }
            
            self.ratioLabel.text = [NSString stringWithFormat:@"%@ of %@ (%3.1f%%) - %@", [NSString bytesFromLong:self.torrent.downloadedEver], [NSString bytesFromLong:self.torrent.totalSize], progress*100, remString];
            [self.commandButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        }
            break;
        case TR_STATUS_SEED:        /* Seeding */
            self.progressView.progress = 1.0;
            self.progressView.progressTintColor = [UIColor greenColor];
            status = [NSString stringWithFormat:@"Seeding to %lld of %lld peers - %@", self.torrent.peersGettingFromUs, self.torrent.peersConnected, [NSString bytesSecFromLong:self.torrent.rateUpload]];
            [self.commandButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            break;
        case TR_STATUS_CHECK:   /* Checking files */
            [self.commandButton setImage:[UIImage imageNamed:@"clock"] forState:UIControlStateNormal];
            status = @"Check files...";
            self.ratioLabel.text = @"";
            break;
            
        case TR_STATUS_CHECK_WAIT:  /* Queued to check files */
            [self.commandButton setImage:[UIImage imageNamed:@"clock"] forState:UIControlStateNormal];
            status = @"Waiting for Check";
            self.ratioLabel.text = @"";
            break;
        case TR_STATUS_DOWNLOAD_WAIT:  /* Queued to download */
            [self.commandButton setImage:[UIImage imageNamed:@"clock"] forState:UIControlStateNormal];
            status = @"Waiting for Download";
            self.ratioLabel.text = @"";
            break;
        case TR_STATUS_SEED_WAIT:   /* Queued to seed */
            [self.commandButton setImage:[UIImage imageNamed:@"clock"] forState:UIControlStateNormal];
            status = @"Waiting for Seeding";
            self.ratioLabel.text = @"";
            break;
            
        default:
            break;
    }
    self.statusLabel.text = status;
    [self setNeedsDisplay];
}

#pragma mark - actions

- (IBAction)onButton:(UIButton *)sender {
    
    TRTransmissionClient *client = [TRTransmissionClient sharedTRTransmissionClient];
    
    if ( ! client.reachable) {
        return;
    }
    
    switch (self.torrent.status) {
            
        case TR_STATUS_STOPPED:     /* Torrent is stopped */
        {
            [client setAction:kTorrentStart forTorrent:self.torrent withErrorBlock:^(NSError *error) {
                NSString *str = [NSString stringWithFormat:@"Error start torrent: %@", error.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                            message:str
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } andSuccessBlock:^{
                if (self.torrent.downloadedEver < self.torrent.totalSize)
                    self.torrent.status = TR_STATUS_DOWNLOAD_WAIT;
                else
                    self.torrent.status = TR_STATUS_SEED_WAIT;
                [self setNeedsLayout];
                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_STATUS_CHANGED object:self.torrent];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            }];
        }
            break;
        case TR_STATUS_CHECK_WAIT:  /* Queued to check files */
            
            break;
        case TR_STATUS_CHECK:   /* Checking files */
            
            break;
        case TR_STATUS_DOWNLOAD_WAIT:  /* Queued to download */
            
            break;
        case TR_STATUS_SEED_WAIT:   /* Queued to seed */
            
            break;
        case TR_STATUS_DOWNLOAD:    /* Downloading */
        case TR_STATUS_SEED:        /* Seeding */
        {
            [client setAction:kTorrentStop forTorrent:self.torrent withErrorBlock:^(NSError *error) {
                NSString *str = [NSString stringWithFormat:@"Error pause torrent: %@", error.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                            message:str
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } andSuccessBlock:^{
                self.torrent.status = TR_STATUS_STOPPED;
                [self setNeedsLayout];
                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_STATUS_CHANGED object:self.torrent];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            }];
        }
        default:
            break;
    }
}

#pragma mark - notification

- (void)onTorrentUpdated:(NSNotification*)notif {
    [self updateFields];
    [self setNeedsLayout];
}

@end
