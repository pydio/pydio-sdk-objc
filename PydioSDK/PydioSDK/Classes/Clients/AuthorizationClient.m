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
#import "LoginResponseSerializer.h"
#import "AuthCredentials.h"
#import "NSString+Hash.h"
#import "User.h"

static NSString * const PING_ACTION = @"get_action=ping";
static NSString * const GET_SEED_ACTION = @"get_action=get_seed";
static NSString * const GET_ACTION = @"get_action";
static NSString * const USERID = @"userid";
static NSString * const PASSWORD = @"password";
static NSString * const LOGIN_SEED = @"login_seed";

@interface AuthorizationClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@end

@implementation AuthorizationClient

-(BOOL)authorize:(User*)user success:(void(^)())success failure:(void(^)(NSError *error))failure {
    return NO;
}

-(BOOL)ping:(void(^)())success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    self.progress = YES;
    
    [self.operationManager GET:PING_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //Ignore result, we just want cookie
        self.progress = NO;
        success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        failure(error);
    }];
    
    return YES;
}

-(BOOL)getSeed:(void(^)(NSString *seed))success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    
    self.progress = YES;
    
    self.operationManager.responseSerializer = [[GetSeedResponseSerializer alloc] init];
    [self.operationManager GET:GET_SEED_ACTION parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.progress = NO;
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        failure(error);
    }];
    
    return YES;
}

-(BOOL)loginWithCredentials:(AuthCredentials*)credentials success:(void(^)(LoginResponse *response))success failure:(void(^)(NSError *error))failure {
    if (self.progress) {
        return NO;
    }
    
    self.progress = YES;
        
    [self.operationManager.requestSerializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    self.operationManager.responseSerializer = [[LoginResponseSerializer alloc] init];
    NSDictionary *params = @{GET_ACTION : @"login",
                             USERID : credentials.userid,
                             PASSWORD : [self hashedPass:credentials.password WithSeed:credentials.seed],
                             LOGIN_SEED : credentials.seed
                            };
    
    [self.operationManager POST:@"" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.progress = NO;
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.progress = NO;
        failure(error);
    }];
    return YES;
}

-(NSString *)hashedPass:(NSString*)pass WithSeed:(NSString *)seed {
    return [seed compare:@"-1"] == NSOrderedSame ? pass : [[NSString stringWithFormat:@"%@%@", [pass md5], seed] md5];
}
@end
