//
//  TRAppDelegate.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRAppDelegate.h"
#import "TRTransmissionClient.h"
#import "TRTorrentParser.h"
#import "TRExtTorrent.h"
#import "TRTorrentInfoViewController.h"

@implementation TRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TRTransmissionClient sharedTRTransmissionClient];
    [[UINavigationBar appearance] setTintColor:TR_TINT_COLOR];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    DLog(@"fileUrl: %@", url);
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data) {
        
        TRTorrentParser *parser = [[TRTorrentParser alloc] init];
        NSDictionary *dic = [parser parseBuffer:data];
        if (dic) {
            TRExtTorrent *etor = [[TRExtTorrent alloc] initWithDictionary:dic];
            // save URL to delete from incoming array after successfully adding
            etor.externalFileUrl = url;
            // save file content to ExtTorrent for feather transmit to server
            etor.externalFileContent = data;
            // add file to collection
            TRTransmissionClient *client = [TRTransmissionClient sharedTRTransmissionClient];
            [client.files addObject:etor];
            if (client.account) {
                NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_FILE_PARSED object:nil];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            }
            else {
                [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                            message:@"Torrent file parsed"
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
            return YES;
        }
        else {
            [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                        message:@"Wrong file format"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
