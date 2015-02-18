//
//  TRTorrentPathViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol setDownloadPathProtocol <NSObject>
- (void)onSetDownloadPath:(NSString*)downloadPath;
@end

@interface TRTorrentPathViewController : UIViewController
@property (nonatomic,retain) NSString *downloadPath;
@property (nonatomic,retain) id <setDownloadPathProtocol> delegate;
@end
