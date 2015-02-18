//
//  TRSplitViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 06.09.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRSplitViewController.h"

@interface TRSplitViewController ()

@end

@implementation TRSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    [self setPresentsWithGesture:NO];
}

#pragma mark - Popover window

- (void)hidePopower
{
    if(_popover && _popover.popoverVisible)
        [_popover dismissPopoverAnimated:YES];
}

- (void)showPopower
{
    UINavigationController *rightNC = [self.viewControllers objectAtIndex:1];
    UIViewController *vc = [rightNC.viewControllers lastObject];
    [self.popover presentPopoverFromBarButtonItem:vc.navigationItem.leftBarButtonItem
                         permittedArrowDirections:UIPopoverArrowDirectionDown
                                         animated:YES];
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)sender shouldHideViewController:(UIViewController *)master inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)sender willHideViewController:(UIViewController *)master withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popover
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [barButtonItem setTitle:@"Filter"];
        UINavigationController *rightNC = [self.viewControllers objectAtIndex:1];
        UIViewController *vc = [rightNC.viewControllers objectAtIndex:0];
        [vc.navigationItem setLeftBarButtonItem:barButtonItem];
        self.popover = popover;
    }
}

- (void)splitViewController:(UISplitViewController *)sender willShowViewController:(UIViewController *)master invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UINavigationController *rightNC = [self.viewControllers objectAtIndex:1];
        UIViewController *vc = [rightNC.viewControllers objectAtIndex:0];
        [vc.navigationItem setLeftBarButtonItem:nil];
        self.popover = nil;
    }
}

- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    [pc setPopoverContentSize:CGSizeMake(320.f, 768.f)];
}

@end
