//
//  TRAddViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TRAccount;

@interface TRSettingsViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDelegate>
@property (nonatomic,retain) __block TRAccount *account;
@end
