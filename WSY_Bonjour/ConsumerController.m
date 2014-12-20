//
//  ConsumerController.m
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//
#import "ConsumerController.h"
#import "BonjourBrowser.h"

@interface ConsumerController (){
    BOOL loading;
}

@end

@implementation ConsumerController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[BonjourBrowser sharedBrowser] browseForHelp];
    [self.tableView reloadData];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    loading = NO;
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseStart:)
                                                 name:kBrowseStartNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseSuccess:)
                                                 name:kBrowseSuccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBonjourBrowseError:)
                                                 name:kBrowseErrorNotification
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
- (void)handleBonjourBrowseStart:(NSNotification*)notification {
    loading = YES;
    [self.tableView reloadData];
}

- (void)handleBonjourBrowseSuccess:(NSNotification*)notification {
    loading = NO;
    [self.tableView reloadData];
}

- (void)handleBonjourBrowseError:(NSNotification*)notification {
    [[[UIAlertView alloc] initWithTitle:@"Browse Error"
                                message:@"Oops, we are unable to browse for help at the moment."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)handleBonjourRemoveService:(NSNotification*)notification {
#warning test if this fixes the issue where services weren't updated
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (loading == NO) {
        return [[[BonjourBrowser sharedBrowser] availableServices] count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (loading == NO) {
        NSNetService *service = [[[BonjourBrowser sharedBrowser] availableServices] objectAtIndex:indexPath.row];
        cell.textLabel.text = service.name;
        cell.textLabel.textAlignment = UITextAlignmentLeft;
    } else {
        cell.textLabel.text = @"loading...";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNetService *service = [[[BonjourBrowser sharedBrowser] availableServices] objectAtIndex:indexPath.row];
    [[BonjourBrowser sharedBrowser] connectToService:service];
    
//    HelpRequestTableViewController *hrtvc = [[HelpRequestTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
//    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:hrtvc];
    
//    [self presentModalViewController:nc animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailController"]) {
        
    }

}
//
//#pragma mark - Table view data source
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
