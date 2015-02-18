//
//  TRMainViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentsViewController.h"
#import "TRTorrentViewCell.h"
#import "TRSettingsViewController.h"
#import "TRTorrentInfoViewController.h"
#import "TRFiltersViewController.h"

#import "TRTransmissionClient.h"
#import "TRAccount.h"
#import "TRTorrent.h"

#define TR_LABEL_HEIGHT 30.f
#define TR_HEADER_HEIGHT 27.f

enum {
    kSortReversed = 0,
    kSortByQueueOrder,
    kSortByActivity,
    kSortByAge,
    kSortByName,
    kSortByProgress,
    kSortByRatio,
    kSortBySize,
    kSortByState
} enumSortOrder;

enum {
    kSelectFilter = 0,
    kSelectSort
} enumButton;

static NSString *sortStrings[9] = {@"Reversed",@"Queue Order",@"Activity",@"Age",@"Name",@"Progress",@"Ratio",@"Size",@"State"};
static NSString *reachable = @"reachable";

@interface TRTorrentsViewController ()
@property (nonatomic,retain) NSArray *torrents;
@property (nonatomic,retain) NSArray *visibleTorrents;

@property (nonatomic,retain) TRTransmissionClient *client;
@property (nonatomic, assign) NSInteger sortOrder;
@property (nonatomic, assign) BOOL sortReversed;
@property (nonatomic, strong) UILabel *infoLabel;

@property (nonatomic,strong) UIPopoverController *popover;
@end

@implementation TRTorrentsViewController

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
    self.torrents = [NSArray array];
    
    self.sortOrder = [USER_DEFAULTS integerForKey:TR_DEFAULTS_KEY_SORT_ORDER];
    if (self.sortOrder == 0) { //if not set
        self.sortOrder = kSortByQueueOrder;
    }
    self.sortReversed = [USER_DEFAULTS boolForKey:TR_DEFAULTS_KEY_SORT_REVERSED];
    
    self.client = [TRTransmissionClient sharedTRTransmissionClient];
    [self.client addObserver:self forKeyPath:@"reachable" options:NSKeyValueObservingOptionNew context:nil];
    if (IDIOM == IPHONE) {
        UIBarButtonItem *sortBtn = self.navigationItem.rightBarButtonItem;
        UIBarButtonItem *filterBtn = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(onFilter:)];
        self.navigationItem.rightBarButtonItems = @[sortBtn,filterBtn];
    }
    else {
        [self.client addObserver:self forKeyPath:@"account" options:NSKeyValueObservingOptionNew context:nil];
    }
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 0, 200.f, TR_LABEL_HEIGHT)];
    self.infoLabel.textColor = [UIColor redColor];
    self.infoLabel.backgroundColor = [UIColor clearColor];
    self.infoLabel.textAlignment = NSTextAlignmentLeft;
    self.infoLabel.adjustsFontSizeToFitWidth = YES;
    self.infoLabel.hidden = NO;
    self.infoLabel.text = @"No connection to server!";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setNotificationsHandlers];
    
    if ( self.client.account) {        
        [self.client updateListOfTorrents];
        self.navigationItem.title = self.client.account.host;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ( self.client.session) {
        if (self.client.files.count > 0) {
            [self onTorrentFileParsed:nil];
        }
    }
    else {
        [self showSettingsAnimated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.client stopUpdateRecentTorrentsLoop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}

- (void)showSettingsAnimated:(BOOL)animated {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    TRSettingsViewController *vc = (id)[mainStoryboard instantiateViewControllerWithIdentifier:@"addViewController"];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    if (IDIOM==IPAD) {
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    [self presentViewController:nc animated:animated completion:nil];
}

- (void)applyFilters {
    
    NSArray *filtered = [self.client torrentsWithFilterPath:self.client.filterPath];
    
    self.visibleTorrents = [filtered sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        TRTorrent *tr1 = self.sortReversed ? obj1 : obj2;
        TRTorrent *tr2 = self.sortReversed ? obj2 : obj1;
        switch (self.sortOrder) {
            case kSortByQueueOrder:
                if (tr1.queuePosition > tr2.queuePosition )
                    return NSOrderedAscending;
                else if (tr1.queuePosition < tr2.queuePosition)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
                break;
            case kSortByActivity:
                if (tr2.activityDate > tr1.activityDate)
                    return NSOrderedAscending;
                else if (tr2.activityDate < tr1.activityDate)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
                break;
            case kSortByAge:
                if (tr2.addedDate > tr1.addedDate )
                    return NSOrderedAscending;
                else if (tr2.addedDate < tr1.addedDate)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
                break;
            case kSortByName:
                return [tr2.name compare:tr1.name];
                break;
            case kSortByProgress:
                if (tr2.downloadedEver/tr2.totalSize > tr1.downloadedEver/tr1.totalSize )
                    return NSOrderedAscending;
                else if (tr2.downloadedEver/tr2.totalSize < tr1.downloadedEver/tr1.totalSize)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
                break;
            case kSortByRatio:
                if (tr2.uploadRatio > tr1.uploadRatio )
                    return NSOrderedDescending;
                else if (tr2.uploadRatio < tr1.uploadRatio)
                    return NSOrderedAscending;
                else
                    return NSOrderedSame;
                break;
            case kSortBySize:
                if (tr2.totalSize > tr1.totalSize )
                    return NSOrderedDescending;
                else if (tr2.totalSize < tr1.totalSize)
                    return NSOrderedAscending;
                else
                    return NSOrderedSame;
                break;
            case kSortByState:
                if (tr2.status > tr1.status )
                    return NSOrderedDescending;
                else if (tr2.status < tr1.status)
                    return NSOrderedAscending;
                else
                    return NSOrderedSame;
                break;
            default:
                return NSOrderedAscending;
        }
    }];
    [self.tableView reloadData];
}

#pragma mark - actions

- (IBAction)onDisconnect:(id)sender {
    [self.client disconnect];
//    [self showSettingsAnimated:YES];
}

- (void)onFilter:(UIBarButtonItem *)sender {
    TRFiltersViewController *fv = [[TRFiltersViewController alloc] initWithStyle:UITableViewStyleGrouped];
    fv.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:fv action:@selector(onClose:)];
    fv.navigationItem.title = @"Filters";
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fv];
    [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)onSort:(UIBarButtonItem*)sender {
    UIActionSheet *ash = [[UIActionSheet alloc] initWithTitle:@"Torrents Filter"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                       destructiveButtonTitle:self.sortReversed ? @"Normal Order" : @"Reverse Order"
                                            otherButtonTitles:@"Queue Order",@"Activity",@"Age",@"Name",@"Progress",@"Ratio",@"Size",@"State",nil];
    ash.tag = kSelectSort;
    if (IDIOM == IPHONE) {
        [ash showInView:self.view];
    }
    else {
        [ash showInView:ROOT_VC_VIEW];
    }
}

#pragma mark - key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.client) {
        if ([@"reachable" isEqualToString:keyPath]) {
            self.infoLabel.hidden = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
            [self.tableView reloadData];
        }
        if ([@"account" isEqualToString:keyPath]) {
            self.navigationItem.title = self.client.account.host;
        }
    }
}

#pragma mark - notifications

- (void)setNotificationsHandlers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(onAppDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(onTorrentListUpdated:) name:TR_NOTIFICATION_TORR_LIST_UPDATED object:nil];
    [nc addObserver:self selector:@selector(onTorrentFileParsed:) name:TR_NOTIFICATION_TORRENT_FILE_PARSED object:nil];
    [nc addObserver:self selector:@selector(onTorrentAdded:) name:TR_NOTIFICATION_TORRENT_ADDED object:nil];
    [nc addObserver:self selector:@selector(applyFilters) name:TR_NOTIFICATION_TORRENT_STATUS_CHANGED object:nil];
    [nc addObserver:self selector:@selector(applyFilters) name:TR_NOTIFICATION_TORR_RECENT_UPDATED object:nil];
    [nc addObserver:self selector:@selector(onFilterSelected:) name:TR_NOTIFICATION_FILTER_SELECTED object:nil];
    [nc addObserver:self selector:@selector(onDisconnectNotif:) name:TR_NOTIFICATION_DISCONNECTED object:nil];
}

- (void)onAppDidBecomeActiveNotification:(NSNotification*)note {
    [self.client updateListOfTorrents];
}

- (void)onTorrentListUpdated:(NSNotification*)note {
    self.torrents = note.object;
    // select filterd torrents
    [self applyFilters];
    DLog(@"onTorrentsListUpdated!!!");
    // start update loop
    [self.client startUpdatingTimer];
}

- (void)onTorrentAdded:(NSNotification*)note {
    [self.tableView scrollsToTop];
}

- (void)onTorrentFileParsed:(NSNotification*)note {
    if ( self.client.session && self.client.files.count > 0) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        TRTorrentInfoViewController *vc = (id)[mainStoryboard instantiateViewControllerWithIdentifier:extTorrentVCident];
        vc.torrent = [self.client.files firstObject];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        if (IDIOM == IPAD) {
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self presentViewController:nc animated:YES completion:nil];        
    }
}

- (void)onFilterSelected:(NSNotification*)note {
   [self applyFilters];
}

- (void)onDisconnectNotif:(NSNotification*)note {
    if (IDIOM == IPAD) {
        self.torrents = self.client.torrents;
        [self applyFilters];
    }
    [self showSettingsAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.visibleTorrents.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"torrentCellIdent" forIndexPath:indexPath];
    
    TRTorrent *torrent = [self.visibleTorrents objectAtIndex:indexPath.row];
    TRTorrentViewCell *tCell = (id)cell;
    tCell.torrent = torrent;
    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *headerIdent = @"tableHeaderIdent";
    UIView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdent];
    UILabel *lbl;
    if (view)
        lbl = (id)view;
    else {
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), TR_HEADER_HEIGHT)];
        lbl.textColor = [UIColor whiteColor];
        lbl.backgroundColor = TR_TINT_COLOR; //[UIColor grayColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.adjustsFontSizeToFitWidth = YES;
    }
    
    NSString *str = @"";
    switch (self.client.filterPath.section) {
        case kFilterTorrents:
            str = filterStrings[self.client.filterPath.row];
            break;
        case kFilterFolders:
            str = self.client.pathes[self.client.filterPath.row];
            break;
        case kFilterTrackers:
            str = self.client.trackers[self.client.filterPath.row];
        default:
            break;
    }
    NSMutableString *mstr = [NSMutableString stringWithFormat:@"FILTER: %@(%d)   SORT: %@", str, self.visibleTorrents.count, sortStrings[self.sortOrder]];
    if (self.sortReversed) {
        [mstr appendString:@" Reversed"];
    }
    lbl.text = mstr;
    return lbl;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    static NSString *headerIdent = @"tableFooterIdent";
    UIView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdent];
    if (!view) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), TR_LABEL_HEIGHT)];
        view.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.8];
        view.layer.borderColor = [[UIColor redColor] CGColor];
        view.layer.borderWidth = 1.f;
        [view addSubview:self.infoLabel];
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return TR_HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (self.client.reachable) {
        return 0;
    }
    return TR_LABEL_HEIGHT;
    
}

#pragma mark - Table view delegate

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                                     message:@"Do you want to remove torrent and delete local files or remove only the torrent?"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Torrent Only", @"Torrent and local files", nil];
        av.tag = indexPath.row;
        [av show];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    BOOL deleteAll = (buttonIndex == alertView.cancelButtonIndex + 2);
    
    if (alertView.tag < self.visibleTorrents.count) {
        TRTorrent *torrent = [self.visibleTorrents objectAtIndex:alertView.tag];
        [self.client deleteTorrent:torrent withLocalData:deleteAll withErrorBlock:^(NSError *error) {
            NSString *str = [NSString stringWithFormat:@"Error delete torrent: %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                        message:str
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        } andSuccessBlock:^{
            NSMutableArray *marr = [self.torrents mutableCopy];
            [marr removeObject:torrent];
            self.torrents = marr;
            [self applyFilters];
        }];
    }
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([@"segueShowInspector" isEqualToString:identifier] && ! self.client.reachable )
        return NO;
    else
        return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"segueShowInspector" isEqualToString:segue.identifier] &&
        [sender isKindOfClass:[TRTorrentViewCell class]]) {
        TRTorrentViewCell *tcell = sender;
        UIViewController *vc = segue.destinationViewController;
        if ([vc respondsToSelector:@selector(setTorrent:)]) {
            [vc performSelector:@selector(setTorrent:) withObject:tcell.torrent];
        }
    }
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (actionSheet.tag == kSelectSort) {
            if (buttonIndex == kSortReversed)
                self.sortReversed = ! self.sortReversed;
            else
                self.sortOrder = buttonIndex;
        }
        else {
            NSIndexPath *filterPath;
            if (buttonIndex < kFilterTorrentsCount) {
                filterPath = [NSIndexPath indexPathForRow:buttonIndex inSection:kFilterTorrents];
            }
            else if (buttonIndex - kFilterTorrentsCount < self.client.pathes.count) {
                filterPath = [NSIndexPath indexPathForRow:buttonIndex - kFilterTorrentsCount inSection:kFilterFolders];
            }
            else if (buttonIndex - kFilterTorrentsCount - self.client.pathes.count < self.client.trackers.count) {
                filterPath = [NSIndexPath indexPathForRow:buttonIndex - kFilterTorrentsCount - self.client.pathes.count inSection:kFilterTorrents];
            } else {
                filterPath = [NSIndexPath indexPathForRow:kFilterTorrentsAll inSection:kFilterTorrents];
            }
            self.client.filterPath = filterPath;
        }
        [USER_DEFAULTS setInteger:self.sortOrder forKey:TR_DEFAULTS_KEY_SORT_ORDER];
        [USER_DEFAULTS setBool:self.sortReversed forKey:TR_DEFAULTS_KEY_SORT_REVERSED];
        [USER_DEFAULTS synchronize];
    }
}

@end
