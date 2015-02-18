//
//  TRTorrentInfoViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentInfoViewController.h"
#import "TRExtTorrent.h"
#import "TRTransmissionClient.h"
#import "TRSession.h"
#import "TRAccount.h"
#import "NSString+formats.h"

@interface TRTorrentInfoViewController ()
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UILabel *freeSpaceLabel;
@property (weak, nonatomic) IBOutlet UISwitch *startTorrentSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *addToTopSwitch;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectFilesLabel;

@end

@implementation TRTorrentInfoViewController

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
    TRTransmissionClient *client = [TRTransmissionClient sharedTRTransmissionClient];
    self.pathLabel.text = ([client.account.lastDownloadPath length]) ? client.account.lastDownloadPath : client.session.downloadDir;
    self.freeSpaceLabel.text = [NSString stringWithFormat:@"Free space: %@",[NSString bytesFromLong:client.session.freeSpace]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionDataUpdated:) name:TR_NOTIFICATION_SESSION_DATA_UPDATED object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.torrent) {
        self.nameLabel.text = self.torrent.name;
        self.commentLabel.text = self.torrent.comment;
        self.sizeLabel.text = [NSString bytesFromLong:self.torrent.totalSize];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateStyle = NSDateFormatterShortStyle;
        df.timeStyle = NSDateFormatterShortStyle;
        self.dateLabel.text = [df stringFromDate:self.torrent.creationDate];
        
        if ([self.torrent.files count]) {
            // config selected files row
            NSUInteger selected = 0;
            for (NSNumber *numb in self.torrent.selectedFiles) {
                if ( [numb boolValue]) {
                    selected++;
                }
            }
            if (selected == self.torrent.selectedFiles.count)
                self.selectFilesLabel.text = @"Selected Files (All)";
            else
                self.selectFilesLabel.text = [NSString stringWithFormat:@"Selected Files (%lu of %lu)", (unsigned long)selected, (unsigned long)self.torrent.files.count];
        }
        [self.tableView reloadData];
    }
}

- (void)setTorrent:(TRExtTorrent *)torrent {
    if (_torrent == torrent) {
        return;
    }
    _torrent = torrent;
    self.nameLabel.text = torrent.name;
    self.commentLabel.text = torrent.comment;
    self.sizeLabel.text = [NSString bytesFromLong:torrent.totalSize];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterShortStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    self.dateLabel.text = [df stringFromDate:torrent.creationDate];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notifications

- (void)onSessionDataUpdated:(NSNotification*)notif {
    TRSession *session = notif.object;
    self.pathLabel.text = session.downloadDir;
    self.freeSpaceLabel.text = [NSString bytesFromLong:session.freeSpace];
}

#pragma mark - Actions

- (IBAction)onCancel:(id)sender {
    // remove torrent from array
    [[[TRTransmissionClient sharedTRTransmissionClient] files] removeObject:self.torrent];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onAdd:(id)sender {
    [[TRTransmissionClient sharedTRTransmissionClient]
     addTorrent:self.torrent
     toPath:self.pathLabel.text
     paused:(!self.startTorrentSwitch.isOn)
     toTop:self.addToTopSwitch.isOn
     withErrorBlock:^(NSError *error) {
         
         NSString *msg = [NSString stringWithFormat:@"Error adding torrent. %@", error.localizedDescription];
         [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                     message:msg
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] show];
     } andSuccessBlock:^{
         TRTransmissionClient *client = [TRTransmissionClient sharedTRTransmissionClient];
         client.account.lastDownloadPath = self.pathLabel.text;
         [self.navigationController dismissViewControllerAnimated:YES completion:^(){
             // save after animation
             [client.account saveAccount];
         }];
     }];
}

- (IBAction)onStartTorrentChanged:(UISwitch*)sender {
}

- (IBAction)onAddToTopChanged:(UISwitch *)sender {
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
        case 1:
            if (self.torrent.files)
                return 5;
            else
                return 4;
            break;
        case 2:
            return 1;
        default:
            break;
    }
    return 0;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==2) {
        [self onAdd:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *vc = [segue destinationViewController];
    if ([vc respondsToSelector:@selector(setTorrent:)]) {
        [vc performSelector:@selector(setTorrent:) withObject:self.torrent];
    }
    if ([vc isKindOfClass:[TRTorrentPathViewController class]]) {
        TRTorrentPathViewController *tpvc = (id)vc;
        tpvc.delegate = self;
        tpvc.downloadPath = self.pathLabel.text;
    }
}

#pragma mark - setDownloadPathProtocol
- (void)onSetDownloadPath:(NSString*)downloadPath {
    self.pathLabel.text = downloadPath;
}

@end
