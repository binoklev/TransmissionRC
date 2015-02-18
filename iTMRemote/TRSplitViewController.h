//
//  TRSplitViewController.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 06.09.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TRSplitViewController : UISplitViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) UIPopoverController   *popover;

- (void)hidePopower;

@end
