//
//  TRTorrentFilesViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 31.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentFilesViewController.h"
#import "TRExtTorrent.h"

@interface TRTorrentFilesViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectBarButton;
@end

@implementation TRTorrentFilesViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)onSelectBarButton:(UIBarButtonItem *)sender {
    NSMutableArray *marr = [self.torrent.selectedFiles mutableCopy];
    BOOL val = [@"Select All" isEqualToString:self.selectBarButton.title];
    for (NSUInteger i=0; i < marr.count; i++) {
        marr[i] = [NSNumber numberWithBool:val];
    }
    self.torrent.selectedFiles = marr;
    [self.tableView reloadData];
    self.selectBarButton.title = val ? @"Deselect All" : @"Select All";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.torrent.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ident = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident];
    }
    cell.textLabel.text = [self.torrent.files objectAtIndex:indexPath.row];
    if ([[self.torrent.selectedFiles objectAtIndex:indexPath.row] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *marr = [self.torrent.selectedFiles mutableCopy];
    NSNumber *numb = [self.torrent.selectedFiles objectAtIndex:indexPath.row];
    marr[indexPath.row] = [NSNumber numberWithBool:( ! [numb boolValue] )];
    self.torrent.selectedFiles = marr;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = ( [numb boolValue] ) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // config button
    for (NSNumber *numb in self.torrent.selectedFiles) {
        if ( ! [numb boolValue]) {
            self.selectBarButton.title = @"Select All";
            return;
        }
        self.selectBarButton.title = @"Deselect All";
    }
}

@end
