//
//  TRFiltersViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 01.09.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRFiltersViewController.h"

#import "TRTransmissionClient.h"

@interface TRFiltersViewController ()
@property (nonatomic,retain) TRTransmissionClient *client;
@end

@implementation TRFiltersViewController

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
    self.client = [TRTransmissionClient sharedTRTransmissionClient];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTorrentListUpdated:) name:TR_NOTIFICATION_TORR_LIST_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTorrentListUpdated:) name:TR_NOTIFICATION_TORR_RECENT_UPDATED object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDisconnect:(UIBarButtonItem *)sender {
    [self.client disconnect];
}

- (void)onClose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - notifications

- (void)onTorrentListUpdated:(NSNotification*)note {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kFiltersCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kFilterTorrents:
            return kFilterTorrentsCount;
        case kFilterFolders:
            return self.client.pathes.count;
        case kFilterTrackers:
            return self.client.trackers.count;
        default:
            break;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kFilterTorrents:
            return @"Torrents";
        case kFilterFolders:
            return @"Pathes";
        case kFilterTrackers:
            return @"Trackers";
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdent = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdent];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdent];
    }
    NSUInteger count;
    NSString *str;
    switch (indexPath.section) {
        case kFilterTorrents:
            str = filterStrings[indexPath.row];
            break;
        case kFilterFolders:
            str = self.client.pathes[indexPath.row];
            break;
        case kFilterTrackers:
            str = self.client.trackers[indexPath.row];
            break;
        default:
            break;
    }
    count = [[self.client torrentsWithFilterPath:indexPath] count];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", str, count];
    if ([self.client.filterPath isEqual:indexPath])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark - TableView navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.client.filterPath = [indexPath copy];
    if (IDIOM == IPHONE)
        [self onClose:nil];
    else
        [self.tableView reloadData];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
