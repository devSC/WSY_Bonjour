//
//  AppDelegate.m
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//

#import "AppDelegate.h"
#import "Bonjour.h"
#import "HelpRequest.h"
@interface AppDelegate ()<UIAlertViewDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(helpRequestHandler:)
                                                 name:kHelpRequestedNotification
                                               object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notification Handlers
- (void)helpRequestHandler:(NSNotification*)notification {
    HelpRequest *request = (HelpRequest*)[[notification userInfo] objectForKey:kNotificationResultSet];
    NSString *helpString = [NSString
                            stringWithFormat:@"Help requested in %@ with: %@.",
                            request.location,
                            request.question];
    
    UIAlertView *helpAlert = [[UIAlertView alloc] initWithTitle:@"Help Request"
                                                        message:helpString
                                                       delegate:self
                                              cancelButtonTitle:@"I'm Unavailable"
                                              otherButtonTitles:@"I'll Help", nil];
    helpAlert.tag = 1;
    [helpAlert show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
            // Help Requested
        case 1: {
            
            HelpResponse *response = [[HelpResponse alloc] init];
            // Declined to help
            if (buttonIndex == 0) {
                // associate is currently busy
                // please select another associate
                response.response = NO;
                // Offered to help
            } else if (buttonIndex == 1) {
                // associate will be right there
                response.response = YES;
                
                // stop broadcasting
                [[Bonjour defaultBonjour] stopService];
            }
            
            [[Bonjour defaultBonjour] sendHelpResponse:response];
            
            break;
        }
        default:
            break;
    }
}


@end
