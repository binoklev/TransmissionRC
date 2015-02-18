//
//  TRTorrentStateFilesViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 29.08.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentStateFilesViewController.h"
#import "NSString+formats.h"

@interface TRTorrentStateFilesViewController ()

@end

@implementation TRTorrentStateFilesViewController

- (void)setFiles:(NSArray *)files {
    _files = [files sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *name1 = [(NSDictionary*)obj1 objectForKey:@"name"];
        NSString *name2 = [(NSDictionary*)obj2 objectForKey:@"name"];
        return [name1 compare:name2];
    }];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDictionary *dic = [self.files objectAtIndex:indexPath.row];
    NSString *fileName = [dic objectForKey:@"name"];
    NSString *find = [NSString stringWithFormat:@"%@/", self.name];
    if ([fileName hasPrefix:find]) {
        fileName = [fileName substringFromIndex:find.length];
    }
    cell.textLabel.text = fileName;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
//1.57 GB of 1.57 GB (100%)
    long long have = [[dic objectForKey:@"bytesCompleted"] longLongValue];
    long long length = [[dic objectForKey:@"length"] longLongValue];
    NSString *percents = @"";
    if (length)
        percents = [NSString stringWithFormat:@"(%d%%)", (int)(have/(length*0.01))];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ of %@ %@",[NSString bytesFromLong:have],[NSString bytesFromLong:length], percents];
    return cell;
}


@end
