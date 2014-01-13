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


@interface PydioClient ()
@property(nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property(nonatomic,strong) AuthorizationClient* authorizationClient;
@property (readwrite,nonatomic,assign) BOOL progress;

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server;
-(AuthorizationClient*)createAuthorizationClient;
@end



@implementation PydioClient

-(NSURL*)serverURL {
    return self.operationManager.baseURL;
}

-(instancetype)initWithServer:(NSString *)server {
    self = [super init];
    if (self) {
        self.operationManager = [self createOperationManager:server];
        self.authorizationClient = [self createAuthorizationClient];
    }
    
    return self;
}

-(BOOL)listFiles {
    if (self.progress) {
        return NO;
    }
    
    CookieManager *manager = [CookieManager sharedManager];
    if ([manager isCookieSet:self.serverURL]) {
        self.progress = YES;
//        performListFiles
    } else {
        User *user = [manager userForServer:self.serverURL];
        if (user == nil) {
            return NO;
        }
        self.progress = YES;
        [self.authorizationClient authorize:user];
        //        performListFiles after succesful login
    }
    
    return YES;
}

#pragma mark -

-(AFHTTPRequestOperationManager*)createOperationManager:(NSString*)server {
    return [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:server]];
}

-(AuthorizationClient*)createAuthorizationClient {//TODO: with operational manager
    return [[AuthorizationClient alloc] init];
}

@end
