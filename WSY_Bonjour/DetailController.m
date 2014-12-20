//
//  DetailController.m
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//
#import "BonjourBrowser.h"
#import "DetailController.h"

@interface DetailController ()
@property (weak, nonatomic) IBOutlet UITextView *questionTextView;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;

@end

@implementation DetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourConnectStart:)
                                                 name:kConnectStartNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourConnectSuccess:)
                                                 name:kConnectSuccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourConnectError:)
                                                 name:kConnectErrorNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helpRequestedHandler:)
                                                 name:kHelpRequestedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helpResponseHandler:)
                                                 name:kHelpResponseNotification
                                               object:nil];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Notification Handlers
- (void)handleBonjourConnectStart:(NSNotification*)notification {
    NSLog(@"Connection / Resolution process started.");
}

- (void)handleBonjourConnectSuccess:(NSNotification*)notification {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)handleBonjourConnectError:(NSNotification*)notification {
    // enable the cancel button
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    [[[UIAlertView alloc] initWithTitle:@"Connection Error"
                                message:@"Unable to establish connection with associate. Please try again later."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)helpRequestedHandler:(NSNotification*)notification {
    // once they've requested help, let the associate respond
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)helpResponseHandler:(NSNotification*)notification {
    HelpResponse *response = (HelpResponse*)[[notification userInfo] objectForKey:kNotificationResultSet];
    NSString *responseString;
    if (response.response == YES) {
        responseString = @"An associate will be with you shortly.";
    } else {
        responseString = @"The associate is currently assisting another customer. Please try another associate.";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Help Response"
                                message:responseString
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    
    [self dismissModalViewControllerAnimated:YES];
}
- (IBAction)submitButtonPressed:(id)sender {
    [self.questionTextView resignFirstResponder];
    [self.locationTextField resignFirstResponder];
    
    if (_questionTextView.text.length == 0 ||
        _locationTextField.text.length == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Question and Location are required."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    HelpRequest *request = [[HelpRequest alloc] init];
    request.question = _questionTextView.text;
    request.location = _locationTextField.text;
    [[BonjourBrowser sharedBrowser] sendHelpRequest:request];
    
}
- (IBAction)cancleButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
////    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
