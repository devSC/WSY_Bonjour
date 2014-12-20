//
//  Bonjour.h
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpResponse.h"
#define kNotificationResultSet              @"NotificationObject"
#define kPublishBonjourStartNotification    @"PublishStartNotification"
#define kPublishBonjourErrorNotification    @"PublishErrorNotification"
#define kPublishBonjourSuccessNotification  @"PublishSuccessNotification"
#define kStopBonjourSuccessNotification     @"StopSuccessNotification"
#define kHelpRequestedNotification          @"HelpRequestedNotification"

@interface Bonjour : NSObject

+ (Bonjour *)defaultBonjour;

- (BOOL)publishServiceWithName:(NSString*)name;

- (void)stopService;

- (void)sendHelpResponse:(HelpResponse*)response;


@end
