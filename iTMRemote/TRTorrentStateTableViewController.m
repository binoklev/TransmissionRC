//
//  TRTorrentStateTableViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 06.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentStateTableViewController.h"
#import "TRTorrentStateFilesViewController.h"

#import "TRTransmissionClient.h"
#import "TRTorrent.h"
#import "NSString+formats.h"

@interface TRTorrentStateTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *haveLabel;
@property (weak, nonatomic) IBOutlet UILabel *avilabilityLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *runninTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastActivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *hashLabel;
@property (weak, nonatomic) IBOutlet UILabel *privacyLabel;
@property (weak, nonatomic) IBOutlet UILabel *originLabel;
@property (weak, nonatomic) IBOutlet UILabel *commenLabel;

@property (nonatomic,retain) NSTimer *updatingTimer;
@property (nonatomic, retain) NSArray *files;
@property (nonatomic, retain) NSArray *statistic;

@end

@implementation TRTorrentStateTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.torrent && ! self.updatingTimer ) {
        [self startUpdatingTimer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.updatingTimer) {
        [self.updatingTimer invalidate];
        self.updatingTimer = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTorrent:(TRTorrent *)torrent {
    if (torrent != _torrent) {
        _torrent = torrent;
        self.navigationItem.title = torrent.name;
        [self onUpdatingTimer:nil];
    }
}

#pragma mark - work with update timer

- (void)startUpdatingTimer {
    if (self.updatingTimer) {
        [self.updatingTimer invalidate];
        self.updatingTimer = nil;
    }
    if (self.torrent && [[TRTransmissionClient sharedTRTransmissionClient] reachable]) {
        self.updatingTimer = [NSTimer timerWithTimeInterval:TR_UPDATING_INTERVAL target:self selector:@selector(onUpdatingTimer:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.updatingTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)onUpdatingTimer:(NSTimer*)timer {
    [[TRTransmissionClient sharedTRTransmissionClient] updateTorrent:self.torrent withErrorBlock:^(NSError *error) {
        
        NSString *str = [NSString stringWithFormat:@"Error update torrent info: %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                    message:str
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        
    } andSuccessBlock:^(NSDictionary *dic) {
        // parce the dictionary
        
        long long havevalid = [[dic valueForKey:@"haveValid"] longLongValue];
        float avail = 100.0;
        if (self.torrent.totalSize > havevalid) {
            long long unverif = [[dic valueForKey:@"haveUnchecked"] longLongValue];
            avail = havevalid/(self.torrent.totalSize*0.01);
            self.haveLabel.text = [NSString stringWithFormat:@"%@ of %@ (%3.1f%%), %@ Unverified", [NSString bytesFromLong:havevalid], [NSString bytesFromLong:self.torrent.totalSize], avail, [NSString bytesFromLong:unverif]];
        }
        else
            self.haveLabel.text = [NSString bytesFromLong:havevalid];
        self.avilabilityLabel.text = [NSString stringWithFormat:@"%3.1f%%", avail];
        self.downloadedLabel.text = [NSString bytesFromLong:[[dic valueForKey:@"downloadedEver"] longLongValue]];
        self.uploadedLabel.text = [NSString stringWithFormat:@"%@ (Ratio:%3.1f)", [NSString bytesFromLong:self.torrent.uploadedEver], self.torrent.uploadRatio];
        if (self.torrent.status >=0 && self.torrent.status < 7) {
            self.stateLabel.text =  torrentStatusStings[self.torrent.status];
        }
        else {
            self.stateLabel.text = @"Unknown";
        }
        if (self.torrent.status == TR_STATUS_DOWNLOAD || self.torrent.status == TR_STATUS_SEED ) {
            NSTimeInterval running = [[NSDate date] timeIntervalSince1970] - [[dic valueForKey:@"startDate"] floatValue];
            self.runninTimeLabel.text = [NSString secondsFromTInterval:running];
        }
        else
            self.runninTimeLabel.text = self.stateLabel.text;

        if (self.torrent.rateDownload > 0) {
            float remains = (self.torrent.totalSize - self.torrent.downloadedEver)/(self.torrent.rateDownload*1.f);
            self.remainingTimeLabel.text = [NSString stringWithFormat:@"remaining:%@", [NSString secondsFromTInterval:remains]];
        }
        else
            self.remainingTimeLabel.text = @"Unknown";        
        NSTimeInterval running = [[NSDate date] timeIntervalSince1970] - [[dic valueForKey:@"activityDate"] floatValue];
        self.lastActivityLabel.text = [NSString stringWithFormat:@"%@ ago", [NSString secondsFromTInterval:running]];
        self.errorLabel.text = @"None";
        
        self.sizeLabel.text = [NSString stringWithFormat:@"%@ (%ld pieces)",[NSString bytesFromLong:self.torrent.totalSize], [[dic valueForKey:@"pieceCount"] longValue] ];
        self.locationLabel.text = [dic objectForKey:@"downloadDir"];
        self.hashLabel.text = [dic objectForKey:@"hashString"];
        self.privacyLabel.text = ([[dic valueForKey:@"isPrivate"] boolValue]) ? @"Private torrent" : @"Public torrent";
        self.originLabel.text = [NSString stringWithFormat:@"Created by %@ on %@", [dic objectForKey:@"creator"], [[NSDate dateWithTimeIntervalSince1970:[[dic valueForKey:@"dateCreated"] floatValue]] description]];
        self.commenLabel.text = [dic objectForKey:@"comment"];
        
        self.files = [dic objectForKey:@"files"];
        self.statistic = [dic objectForKey:@"trackerStats"];
        
        [self startUpdatingTimer];
        [self.tableView reloadData];
        /*
        {
         activityDate = 1407334123;
         comment = "http://rutracker.org/forum/viewtopic.php?t=4056600";
         corruptEver = 0;
         creator = "uTorrent/2000";
         dateCreated = 1336814119;
         desiredAvailable = 0;
         downloadDir = "/opt/public/Video";
         downloadedEver = 1576438883;
         fileStats =     (
             {
                 bytesCompleted = 1573126144;
                 priority = 0;
                 wanted = 1;
             }
         );
         files =     (
             {
                 bytesCompleted = 1573126144;
                 length = 1573126144;
                 name = "007.Licence to Kill.1989.HDRip.XviD.1400MB. rip by [Assassin's Creed].avi";
             }
         );
         hashString = e9ec6c1b58504a32323dffe24d7d075e1c0475f0;
         haveUnchecked = 0;
         haveValid = 1573126144;
         id = 23;
         isPrivate = 0;
         peers =     (
         );
         pieceCount = 751;
         pieceSize = 2097152;
         startDate = 1407245312;
         trackerStats =     (
             {
                 announce = "http://bt4.rutracker.org/ann?uk=ggDeLxtE1I";
                 announceState = 1;
                 downloadCount = "-1";
                 hasAnnounced = 1;
                 hasScraped = 0;
                 host = "http://bt4.rutracker.org:80";
                 id = 0;
                 isBackup = 0;
                 lastAnnouncePeerCount = 40;
                 lastAnnounceResult = Success;
                 lastAnnounceStartTime = 1407335531;
                 lastAnnounceSucceeded = 1;
                 lastAnnounceTime = 1407335531;
                 lastAnnounceTimedOut = 0;
                 lastScrapeResult = "";
                 lastScrapeStartTime = 0;
                 lastScrapeSucceeded = 0;
                 lastScrapeTime = 0;
                 lastScrapeTimedOut = 0;
                 leecherCount = "-1";
                 nextAnnounceTime = 1407338932;
                 nextScrapeTime = 0;
                 scrape = "";
                 scrapeState = 2;
                 seederCount = "-1";
                 tier = 0;
             },
             {
                 announce = "http://retracker.local/announce";
                 announceState = 1;
                 downloadCount = 9;
                 hasAnnounced = 1;
                 hasScraped = 1;
                 host = "http://retracker.local:80";
                 id = 1;
                 isBackup = 0;
                 lastAnnouncePeerCount = 0;
                 lastAnnounceResult = Success;
                 lastAnnounceStartTime = 1407337146;
                 lastAnnounceSucceeded = 1;
                 lastAnnounceTime = 1407337147;
                 lastAnnounceTimedOut = 0;
                 lastScrapeResult = "Could not connect to tracker";
                 lastScrapeStartTime = 1407336820;
                 lastScrapeSucceeded = 1;
                 lastScrapeTime = 1407336821;
                 lastScrapeTimedOut = 0;
                 leecherCount = 0;
                 nextAnnounceTime = 1407338947;
                 nextScrapeTime = 1407338630;
                 scrape = "http://retracker.local/scrape";
                 scrapeState = 1;
                 seederCount = 3;
                 tier = 1;
             }
         );
         webseedsSendingToUs = 0;
        }
         */
        
    }];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *vc = [segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"seguePushStateFiles"]) {
        if ([vc respondsToSelector:@selector(setFiles:)]) {
            [vc performSelector:@selector(setFiles:) withObject:self.files];
        }
        if ([vc respondsToSelector:@selector(setName:)]) {
            [vc performSelector:@selector(setName:) withObject:self.torrent.name];
        }
    }
   
    if ([segue.identifier isEqualToString:@"seguePushTrackersStatistic"]) {
        if ([vc respondsToSelector:@selector(setStatistic:)]) {
            [vc performSelector:@selector(setStatistic:) withObject:self.statistic];
        }
        vc.navigationItem.title = self.torrent.name;
    }
    
}


@end
