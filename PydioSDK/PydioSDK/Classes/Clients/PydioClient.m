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
#import "ListFilesRequest.h"
#import "AuthorizationClient.h"
#import "OperationsClient.h"
#import "PydioErrors.h"


static const int AUTHORIZATION_TRIES_COUNT = 1;

@interface PydioClient ()
@property(nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property(nonatomic,strong) AuthorizationClient* authorizationClient;
@property(nonatomic,strong) OperationsClient* operationsClient;
@property(nonatomic,copy) void(^operationBlock)();
@property(nonatomic,copy) void(^failureBlock)(NSError* error);
@property(nonatomic,assign) int authorizationsTriesCount;

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server;
-(AuthorizationClient*)createAuthorizationClient;
-(OperationsClient*)createOperationsClient;
-(void)performAuthorizationAndOperation;
-(void)handleOperationFailure:(NSError*)error;
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

-(BOOL)listWorkspacesWithSuccess:(void(^)(NSArray* files))success failure:(void(^)(NSError* error))failure {
    if (self.progress) {
        return NO;
    }
    
    [self resetAuthorizationTriesCount];
    self.failureBlock = failure;
    
    typeof(self) strongSelf = self;
    self.operationBlock = ^{
        [strongSelf.operationsClient listWorkspacesWithSuccess:^(NSArray *files){
            success(files);
            strongSelf.operationBlock = nil;
            strongSelf.failureBlock = nil;
        } failure:^(NSError *error) {
            [strongSelf handleOperationFailure:error];
        }];
    };
    
    self.operationBlock();
    
    return YES;
}

-(BOOL)listFiles:(ListFilesRequest *)request WithSuccess:(void(^)(NSArray* files))success failure:(void(^)(NSError* error))failure {
    if (self.progress) {
        return NO;
    }
    
    [self resetAuthorizationTriesCount];
    self.failureBlock = failure;
    
    typeof(self) strongSelf = self;
    self.operationBlock = ^{
        [strongSelf.operationsClient listFiles:[request dictionaryRepresentation] WithSuccess:^(NSArray *files){
            success(files);
            strongSelf.operationBlock = nil;
            strongSelf.failureBlock = nil;
        } failure:^(NSError *error) {
            [strongSelf handleOperationFailure:error];
        }];
    };
    
    self.operationBlock();

    
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

-(void)performAuthorizationAndOperation {
    self.authorizationsTriesCount--;
    [self.authorizationClient authorizeWithSuccess:^{
        self.operationBlock();
    } failure:^(NSError *error) {
        self.failureBlock(error);
        self.operationBlock = nil;
        self.failureBlock = nil;
    }];
}

-(void)handleOperationFailure:(NSError*)error {
    if ([self isAuthorizationError:error] && self.authorizationsTriesCount > 0) {
        [self performAuthorizationAndOperation];
    } else {
        self.failureBlock(error);
        self.operationBlock = nil;
        self.failureBlock = nil;
    }
}

-(BOOL)isAuthorizationError:(NSError *)error {
    return [error.domain isEqualToString:PydioErrorDomain] && error.code == PydioErrorUnableToLogin;
}

-(void)resetAuthorizationTriesCount {
    self.authorizationsTriesCount = AUTHORIZATION_TRIES_COUNT;
}

@end
