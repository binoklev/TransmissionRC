//
//  TRTorrentStateStatisticViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 04.09.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentStateStatisticViewController.h"

#define TR_TIER_TAG 100

@implementation TRTorrentStateStatisticViewController

- (void)setStatistic:(NSArray *)statistic {
    _statistic = [statistic sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger tier1 = [[(NSDictionary*)obj1 valueForKey:@"tier"] integerValue];
        NSInteger tier2 = [[(NSDictionary*)obj2 valueForKey:@"tier"] integerValue];
        if (tier1 > tier2)
            return NSOrderedAscending;
        else if (tier2 > tier1)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.statistic.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"statisticCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSDictionary *dic = self.statistic[indexPath.row];
    for (UIView *view in cell.contentView.subviews) {
        if (view.tag >= TR_TIER_TAG) {
            UILabel *lbl = (UILabel*)view;
            switch (view.tag) {
                case TR_TIER_TAG:
                    lbl.text = [NSString stringWithFormat:@"%d",indexPath.row];
                    break;
                case TR_TIER_TAG + 1:
                {
                    NSString *str = [dic objectForKey:@"host"];
                    if (str)
                        lbl.text = str;
                    else
                        lbl.text = @"N/A";
                }
                    break;
                    
                case TR_TIER_TAG + 12: // Last Announce title
                {
                    NSString *str = [dic objectForKey:@"lastAnnounceResult"];
                    if (![str isEqualToString:@"Success"]) {
                        lbl.text = @"Announce error:";
                    }
                }
                    break;
                case TR_TIER_TAG + 2: // Last Announce
                {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dic valueForKey:@"lastAnnounceTime"] floatValue]];
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    df.dateFormat = @"dd.MM.yy hh:mm:ss";
                    NSString *timeStr = [df stringFromDate:date];
                    
                    NSString *str = [dic objectForKey:@"lastAnnounceResult"];
                    if ([str isEqualToString:@"Success"]) {
                        NSInteger peers = [[dic valueForKey:@"lastAnnouncePeerCount"] integerValue];
                        lbl.text = [NSString stringWithFormat:@"%@ (got %ld peers)", timeStr, (long)peers];
                    }
                    else {
                        lbl.text = [NSString stringWithFormat:@"%@ - %@",str, timeStr];
                    }
                }
                    break;
                case TR_TIER_TAG + 3: // Next announce in
                {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dic valueForKey:@"nextAnnounceTime"] floatValue]];
                    long mins = (long)[date timeIntervalSinceNow]/60;
                    if (mins < 60) {
                        lbl.text = [NSString stringWithFormat:@"%ld minutes", mins];
                    }
                    else {
                        long hours = (long)(mins/60.0);
                        mins = mins%60;
                        lbl.text = [NSString stringWithFormat:@"%ld hours %ld minutes", hours, mins];
                    }
                }
                    break;
                case TR_TIER_TAG + 14: // Last Announce title
                {
                    NSNumber *suxObj = [dic valueForKey:@"lastScrapeSucceeded"];
                    if (suxObj) {
                        if( ! [suxObj boolValue] )
                            lbl.text = @"Scrape error:";
                    }
                    else
                    {
                        NSString *str = [dic objectForKey:@"lastScrapeResult"];
                        if( ! [str isEqualToString:@"Success"]) {
                            lbl.text = @"Scrape error:";
                        }
                    }
                }
                    break;
                case TR_TIER_TAG + 4: // Last scrape:
                {
                    float nextTime = [[dic valueForKey:@"lastScrapeTime"] floatValue];
                    if (nextTime == 0) {
                        lbl.text = @"Scrape error";
                        break;
                    }
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dic valueForKey:@"lastScrapeTime"] floatValue]];
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    df.dateFormat = @"dd.MM.yy hh:mm:ss";
                    NSString *timeStr = [df stringFromDate:date];
                    
                    NSNumber *suxObj = [dic valueForKey:@"lastScrapeSucceeded"];
                    NSString *str = [dic objectForKey:@"lastScrapeResult"];
                    if ( (suxObj && [suxObj boolValue]) || [str isEqualToString:@"Success"] ) {
                        lbl.text = [NSString stringWithFormat:@"%@", timeStr];
                    }
                    else {
                        lbl.text = [NSString stringWithFormat:@"%@ - %@",str, timeStr];
                    }
                }
                    break;
                case TR_TIER_TAG + 5: // Seeders
                {
                    long count = [[dic objectForKey:@"seederCount"] longValue];
                    if (count >= 0)
                        lbl.text = [NSString stringWithFormat:@"%ld",count];
                    else
                        lbl.text = @"N/A";
                }
                    break;
                case TR_TIER_TAG + 6: // Leechers
                {
                    long count = [[dic objectForKey:@"leecherCount"] longValue];
                    if (count >= 0)
                        lbl.text = [NSString stringWithFormat:@"%ld",count];
                    else
                        lbl.text = @"N/A";
                }
                    break;
                case TR_TIER_TAG + 7: // Downloads
                {
                    long count = [[dic objectForKey:@"downloadCount"] longValue];
                    if (count >= 0)
                        lbl.text = [NSString stringWithFormat:@"%ld",count];
                    else
                        lbl.text = @"N/A";
                }
                    break;
                default:
                    break;
            }
        }
    }
    
    return cell;
}

/*
 
 {
 "announce": "udp://tracker.publicbt.com:80/announce",
 "announceState": 1,
 "downloadCount": 10,
 "hasAnnounced": true,
 "hasScraped": true,
 "host": "udp://tracker.publicbt.com:80",
 "id": 2,
 "isBackup": false,
 "lastAnnouncePeerCount": 66,
 "lastAnnounceResult": "Success",
 "lastAnnounceStartTime": 1410019882,
 "lastAnnounceSucceeded": true,
 "lastAnnounceTime": 1410019882,
 "lastAnnounceTimedOut": false,
 "lastScrapeResult": "Could not connect to tracker",
 "lastScrapeStartTime": 1410021590,
 "lastScrapeSucceeded": true,
 "lastScrapeTime": 1410021593,
 "lastScrapeTimedOut": 0,
 "leecherCount": 14,
 "nextAnnounceTime": 1410021808,
 "nextScrapeTime": 1410023400,
 "scrape": "udp://tracker.publicbt.com:80/scrape",
 "scrapeState": 1,
 "seederCount": 52,
 "tier": 2
 },
 {
 "announce": "udp://tracker.ccc.de:80/announce",
 "announceState": 1,
 "downloadCount": -1,
 "hasAnnounced": true,
 "hasScraped": true,
 "host": "udp://tracker.ccc.de:80",
 "id": 3,
 "isBackup": false,
 "lastAnnouncePeerCount": 0,
 "lastAnnounceResult": "Connection failed",
 "lastAnnounceStartTime": 0,
 "lastAnnounceSucceeded": false,
 "lastAnnounceTime": 1410018242,
 "lastAnnounceTimedOut": false,
 "lastScrapeResult": "Could not connect to tracker",
 "lastScrapeStartTime": 0,
 "lastScrapeSucceeded": false,
 "lastScrapeTime": 1410016365,
 "lastScrapeTimedOut": 1,
 "leecherCount": -1,
 "nextAnnounceTime": 1410025444,
 "nextScrapeTime": 1410023600,
 "scrape": "udp://tracker.ccc.de:80/scrape",
 "scrapeState": 1,
 "seederCount": -1,
 "tier": 3
 },
 {
 "announce": "udp://tracker.ipv6tracker.org:80/announce",
 "announceState": 0,
 "downloadCount": -1,
 "hasAnnounced": false,
 "hasScraped": false,
 "host": "udp://tracker.ipv6tracker.org:80",
 "id": 4,
 "isBackup": true,
 "lastAnnouncePeerCount": 0,
 "lastAnnounceResult": "",
 "lastAnnounceStartTime": 0,
 "lastAnnounceSucceeded": false,
 "lastAnnounceTime": 0,
 "lastAnnounceTimedOut": false,
 "lastScrapeResult": "",
 "lastScrapeStartTime": 0,
 "lastScrapeSucceeded": false,
 "lastScrapeTime": 0,
 "lastScrapeTimedOut": 0,
 "leecherCount": -1,
 "nextAnnounceTime": 0,
 "nextScrapeTime": 0,
 "scrape": "udp://tracker.ipv6tracker.org:80/scrape",
 "scrapeState": 0,
 "seederCount": -1,
 "tier": 4
 }, */

@end
