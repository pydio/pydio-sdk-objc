//
//  AuthorizationClient.m
//  PydioSDK
//
//  Created by ME on 06/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "AuthorizationClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "GetSeedResponseSerializer.h"


static NSString * const PING_ACTION = @"get_action=ping";
static NSString * const GET_SEED_ACTION = @"get_action=get_seed";

@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) AuthorizationState state;
@property (readwrite,nonatomic,assign) BOOL progress;
@property (readwrite,nonatomic,strong) NSError *lastError;
@end

@implementation AuthorizationClient

-(BOOL)ping {
    if (self.progress || self.state != ASNone) {
        return NO;
    }
    self.progress = YES;
    self.state = ASPing;
    
    [self.operationManager GET:PING_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //Ignore result, we just want cookie
        self.progress = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        self.lastError = error;
    }];
    
    return YES;
}

-(BOOL)getSeed {
    if (self.lastError || self.progress || self.state != ASPing) {
        return NO;
    }
    
    self.progress = YES;
    self.state = ASGetSeed;

    self.operationManager.responseSerializer = [[GetSeedResponseSerializer alloc] init];
    [self.operationManager GET:GET_SEED_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.progress = NO;
        //TODO: For now we just want to now about success, later we want to inform caller about receiving seed
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        self.lastError = error;
    }];
    
    return YES;
}

@end
