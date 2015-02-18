//
//  TRAddViewController.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 18.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#ifdef LITE
    #import <iAd/iAd.h>
#endif
#import "TRSettingsViewController.h"
#import "TRTorrentsViewController.h"

#import "TRAccount.h"
#import "TRTransmissionClient.h"

#define GTS_ADD_VIEW_SAVE_INDEX_PATH [NSIndexPath indexPathForRow:4 inSection:0]

typedef enum : NSUInteger {
    kNotLoading = 0,
    kAutoLoad,
    kManualLoad
} torrentsViewControllerLoadyngType;

@interface TRSettingsViewController () {
    torrentsViewControllerLoadyngType loadingType;
}

@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sslSwitch;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UITextField *directoryTextField;
@property (weak, nonatomic) IBOutlet UILabel *saveLabel;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSURLConnection *testingConnection;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (nonatomic, assign) __block BOOL accountExists;
@property (nonatomic, assign) __block BOOL changed;
@property (nonatomic, assign) __block BOOL saved;

@property (nonatomic, strong) UIBarButtonItem *leftBarButton;

@end

@implementation TRSettingsViewController

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
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    //    self.activityIndicator.color = GTS_COLOR;
    self.activityIndicator.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
    
    self.saveLabel.layer.borderColor = [TR_COLOR CGColor];
    self.saveLabel.layer.borderWidth = 1.0;
    self.saveLabel.layer.cornerRadius = 4.f;
    
//    [self.infoButton addTarget:self action:@selector(onInfoButton:) forControlEvents:UIControlEventTouchUpInside];
    
    TRAccount *account = [[TRTransmissionClient sharedTRTransmissionClient] account];
    if (account) { // for iPhone
        //[[TRTransmissionClient sharedTRTransmissionClient] disconnect];
    }
    else {
        account = [TRAccount savedAccount];
    }
    if (account) {
        self.accountExists = YES;
        self.account = account;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.activityIndicator.frame = self.view.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self cancelRequest];
    if (loadingType)
        loadingType = kNotLoading;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    TRAccount *clientAccount = [[TRTransmissionClient sharedTRTransmissionClient] account];
    if ( ! self.account) {
        self.account = [[TRAccount alloc] init];
    }
    else {
        if (clientAccount == nil) {
            // start testing connection from saved
            loadingType = kAutoLoad;
            [self onSave:nil];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupFields {
    
    self.hostTextField.text = self.account.host;
    [self.sslSwitch setOn:self.account.ssl];
    if (self.account.port) {
        self.portTextField.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.account.port];
    }
    
    self.directoryTextField.text = self.account.directory;
    
    [self.tableView reloadData];
}

#pragma mark - properties

- (void)setAccount:(TRAccount *)account {
    _account = account;
    // set flag that account exists yet
    [self setupFields];
}

- (void)setChanged:(BOOL)changed {
    if (_changed == changed) {
        return;
    }
    _changed = changed;
}

#pragma mark - navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
#ifdef LITE
    if ([segue.destinationViewController respondsToSelector:@selector(interstitialPresentationPolicy)]) {
        [segue.destinationViewController setInterstitialPresentationPolicy:ADInterstitialPresentationPolicyAutomatic];
    }
#endif
}


#pragma mark - actions

- (void)onSave:(id)sender {
    // check fields
    if ([[self.hostTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        [[[UIAlertView alloc] initWithTitle:TR_APP_NAME
                                    message:NSLocalizedString(@"[Server must have IP-address or DNS name]",nil)
                                   delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    [self.view endEditing:YES];
    
    if (self.changed) {
        self.account.host = [self.hostTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        self.account.ssl = [self.sslSwitch isOn];
        self.account.port = [self.portTextField.text integerValue];
        self.account.directory = [self.directoryTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    else {
        if (loadingType == kNotLoading) {
            loadingType = kManualLoad;
        }
    }
    // check server connection in any case
    DLog(@"Connection string: %@", self.account.connectionString);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:self.account.connectionString]];
    self.testingConnection = [NSURLConnection connectionWithRequest:req delegate:self];
    if (self.testingConnection) {
        [self lockScreen];
    } else {
        [[[UIAlertView alloc] initWithTitle:TR_APP_NAME message:NSLocalizedString(@"Server connection error", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (IBAction)onEditDidBegin:(UITextField *)sender {
    UIView *view = sender;
    while (view && ! [view isKindOfClass:[UITableViewCell class]]) {
        view = [view superview];
    }
    if (view) {
        NSIndexPath *path = [self.tableView indexPathForCell:(UITableViewCell*)view];
        [self.tableView scrollToRowAtIndexPath:path
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
    }

}

- (IBAction)onTextChanged:(UITextField *)sender {
    self.changed = YES;
}

- (IBAction)onSwitchChanged:(UISwitch *)sender {
    self.changed = YES;
    self.account.ssl = sender.isOn;
}

- (void)onInfoButton:(id)sender {
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"inctructionViewController"];
    if (vc) {
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - utility

- (void)lockScreen {
    self.activityIndicator.frame = self.view.bounds;
    [self.activityIndicator startAnimating];
    self.leftBarButton = self.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelRequest)];
}

- (void)unlockScreen {
    [self.activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem = self.leftBarButton;
    self.leftBarButton = nil;
}

- (void)cancelRequest {
    if (self.testingConnection) {
        [self.testingConnection cancel];
        self.testingConnection = nil;
        DLog(@"Cancel testingConnection");
        
    }
    [self unlockScreen];
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath isEqual:GTS_ADD_VIEW_SAVE_INDEX_PATH]) {
        [self onSave:nil];
    }
}

#pragma mark - scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.activityIndicator isAnimating]) {
        self.activityIndicator.frame = self.view.bounds;
    }
}

#pragma mark - text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.hostTextField) {
        [self.portTextField becomeFirstResponder];
    } else if (textField == self.portTextField) {
        [self.directoryTextField becomeFirstResponder];
    } else if (textField == self.directoryTextField) {
        [self.view endEditing:YES];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.changed = YES;
    return YES;
}

#pragma mark - URLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.testingConnection = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self unlockScreen];
    });
    
    NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
    if(statusCode == 200 || statusCode == TR_ERROR_CODE_SESSION_ERROR ) {
        [self.account saveAccount];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[TRTransmissionClient sharedTRTransmissionClient] setAccount:self.account];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                if ([TRTransmissionClient sharedTRTransmissionClient].files.count > 0) {
                    NSNotification *note = [NSNotification notificationWithName:TR_NOTIFICATION_TORRENT_FILE_PARSED object:nil];
                    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
                }
            }];
        });
        
    } else {
        NSString *msg = [NSString stringWithFormat:@"%@, HTTP error code %ld",NSLocalizedString(@"Server connection error", nil), (long)statusCode];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:TR_APP_NAME message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:TR_APP_NAME message:[NSString stringWithFormat:@"%@:\n%@",NSLocalizedString(@"Server connection error", nil), error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    
    [self performSelectorOnMainThread:@selector(unlockScreen) withObject:nil waitUntilDone:NO];
    self.testingConnection = nil;
    loadingType = kNotLoading;
}

@end
