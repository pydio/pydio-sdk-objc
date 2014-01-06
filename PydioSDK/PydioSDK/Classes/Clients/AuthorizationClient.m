//
//  AuthorizationClient.m
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "AuthorizationClient.h"
#import "AFHTTPRequestOperationManager.h"

static NSString * const PING_ACTION = @"get_action=ping";

@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) AuthorizationState state;
@property (readwrite,nonatomic,assign) BOOL progress;
@end

@implementation AuthorizationClient

-(BOOL)ping {
    if (self.progress || self.state != ASNone) {
        return NO;
    }
    _progress = YES;
    _state = ASPing;
    
    [self.operationManager GET:PING_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //Ignore result, we just want cookie
        _progress = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _progress = NO;
        _lastError = error;
    }];
    
    return YES;
}
@end
