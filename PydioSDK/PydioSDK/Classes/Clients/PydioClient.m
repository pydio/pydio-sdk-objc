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
        self.operationManager = [self createOperationManager:server];
        self.authorizationClient = [self createAuthorizationClient];
        self.operationsClient = [self createOperationsClient];
    }
    
    return self;
}

-(BOOL)listFilesWithSuccess:(void(^)(NSArray* files))success failure:(void(^)(NSError* error))failure {
    if (self.progress) {
        return NO;
    }
    
    [self.operationsClient listFilesWithSuccess:^(NSArray *files){
        success(files);
    } failure:^(NSError *error) {
        if ([self isAuthorizationError:error]) {
            [self.authorizationClient authorizeWithSuccess:^{
                [self.operationsClient listFilesWithSuccess:^(NSArray *files) {
                    success(files);
                } failure:^(NSError *error) {
                    failure(error);
                }];
            } failure:^(NSError *error) {
                failure(error);
            }];
        } else {
            failure(error);
        }
    }];
    
    return YES;
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

-(BOOL)isAuthorizationError:(NSError *)error {
    return [error.domain isEqualToString:PydioErrorDomain] && error.code == PydioErrorUnableToLogin;
}

@end
