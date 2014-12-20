//
//  AssociateController.m
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//

#import "AssociateController.h"
#import "Bonjour.h"

@interface AssociateController ()<UITextFieldDelegate>{
    UITextField *serviceNameField;
    NSIndexPath *availabilityCellPath;
    BOOL        available;
}
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *avaliableButton;

@end

@implementation AssociateController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishStart:)
                                                 name:kPublishBonjourStartNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishSuccess:)
                                                 name:kPublishBonjourSuccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourPublishError:)
                                                 name:kPublishBonjourErrorNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourStopSuccess:)
                                                 name:kStopBonjourSuccessNotification
                                               object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Bonjour Notifications
- (void)handleBonjourPublishStart:(NSNotification*)notification {
    NSLog(@"Started publishing");
}

- (void)handleBonjourPublishSuccess:(NSNotification*)notification {
    available = YES;
    
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:availabilityCellPath]
//                          withRowAnimation:UITableViewRowAnimationNone];
    [self.avaliableButton setTitle:@"No Longer Available" forState:UIControlStateNormal];
}

- (void)handleBonjourPublishError:(NSNotification*)notification {
    NSLog(@"Error publishing");
}

- (void)handleBonjourStopSuccess:(NSNotification*)notification {
    available = NO;
    [self.avaliableButton setTitle:@"I'm Available" forState:UIControlStateNormal];
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:availabilityCellPath]
//                          withRowAnimation:UITableViewRowAnimationNone];
}



#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}
- (IBAction)avialiableButtonPressed:(id)sender {
    
    [self.textField resignFirstResponder];
    
    if (available == YES) {
        [[Bonjour defaultBonjour] stopService];
        available = NO;
        
        // become available
    } else {
        
        // validate that department name has been specified
        if (self.textField.text == nil) {
            [[[UIAlertView alloc]
              initWithTitle:@"Error"
              message:@"Department name is required."
              delegate:nil
              cancelButtonTitle:@"OK"
              otherButtonTitles:nil] show];
            return;
        }
        
        BOOL serviceRslt =
        [[Bonjour defaultBonjour] publishServiceWithName:_textField.text];
        
        if (serviceRslt == NO) {
            NSString *errorMsg =
            @"Unable to publish your services at this time. Please try again.";
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:errorMsg
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
}

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
