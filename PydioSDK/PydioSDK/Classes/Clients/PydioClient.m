//
//  PydioClient.m
//  PydioSDK
//
//  Created by ME on 09/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "PydioClient.h"
#import "AFHTTPRequestOperationManager.h"
#import "CookieManager.h"
#import "User.h"
#import "AuthorizationClient.h"
#import "OperationsClient.h"
#import "PydioErrors.h"


@interface PydioClient ()
@property(nonatomic,assign) NSInteger authorizationFailures;
@property(nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property(nonatomic,strong) AuthorizationClient* authorizationClient;
@property(nonatomic,strong) OperationsClient* operationsClient;

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server;
-(AuthorizationClient*)createAuthorizationClient;
-(OperationsClient*)createOperationsClient;
@end


@implementation PydioClient

-(NSURL*)serverURL {
    return self.operationManager.baseURL;
}

-(BOOL)progress {
    return self.authorizationClient.progress || self.operationsClient.progress;
}

-(instancetype)initWithServer:(NSString *)server {
    self = [super init];
    if (self) {
        self.authorizationFailures = 0;
        self.operationManager = [self createOperationManager:server];
        self.authorizationClient = [self createAuthorizationClient];
        self.operationsClient = [self operationsClient];
    }
    
    return self;
}

-(BOOL)listFiles {
    if (self.progress) {
        return NO;
    }
    
    [self.operationsClient listFilesWithSuccess:^{
        //Success, call success block
    } failure:^(NSError *error) {
        if ([error.domain isEqualToString:PydioErrorDomain] && error.code == PydioErrorUnableToLogin && self.authorizationFailures == 0) {
            self.authorizationFailures++;
            [self.authorizationClient authorizeWithSuccess:^{
                self.authorizationFailures = 0;
                [self listFiles];
            } failure:^(NSError *error) {
                //Failure, call failure block
            }];
        } else {
            //Failure, call failure block
        }
    }];
    
//    CookieManager *manager = [CookieManager sharedManager];
//    if ([manager isCookieSet:self.serverURL]) {
//        self.progress = YES;
//        [self.operationClient listFiles];
//    } else {
//        User *user = [manager userForServer:self.serverURL];
//        if (user == nil) {
//            return NO;
//        }
//        BOOL authorizationStart = [self.authorizationClient authorize:user success:^{
//            [self.operationClient listFiles];
//        } failure:^(NSError *error) {
//            self.progress = NO;
//        }];
//        
//        if (authorizationStart == NO) {
//            return NO;
//        }
//        self.progress = YES;
//    }
    
    return YES;
}

-(void)performListFiles {
    
}

#pragma mark -

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server {
    return [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:server]];
}

-(AuthorizationClient*)createAuthorizationClient {
    AuthorizationClient *client = [[AuthorizationClient alloc] init];
    client.operationManager = self.operationManager;
    
    return client;
}

-(OperationsClient*)createOperationsClient {
    OperationsClient *client = [[OperationsClient alloc] init];
    client.operationManager = self.operationManager;
    
    return client;
}

@end
