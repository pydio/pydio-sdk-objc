//
//  PydioClient.m
//  PydioSDK
//
//  Created by ME on 04/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "PydioClient.h"
#import "AFNetworking.h"
#import "ServerConfig.h"
#import "NSString+Hash.h"

static NSString const * COOKIE_NAME = @"AjaXplorer";

@interface PydioClient ()
@property (nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property (nonatomic,strong) NSString* secureToken;

-(NSArray *)allServerCookies;
-(void)clearAllCookies;
-(BOOL)isCookieSet;
-(NSURL *)serverURL;

@end

@implementation PydioClient
+(instancetype)pydioClientWithServerConfig:(ServerConfig *)config {
    return [[PydioClient alloc] initWithServerConfig:config];
}

-(instancetype)initWithServerConfig:(ServerConfig *)config {
    self = [super init];
    if (self) {
        _serverConfig = config;
        NSURL *serverURL = [NSURL URLWithString:self.serverConfig.server];
        self.operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:serverURL];
    }
    return self;
}

-(void)login {
    if (self.inProgress) {
        return;
    }
    
    _inProgress = YES;
    [self clearAllCookies];
    self.secureToken = nil;
    _loggedToServer = NO;
    
    
    
}

#pragma mark - Cookies

-(NSArray *)allServerCookies {
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.serverURL];
}

-(void)clearAllCookies {
    NSArray *cookies = [self allServerCookies];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

-(BOOL)isCookieSet {
    NSArray *cookies = [self allServerCookies];
    for (NSHTTPCookie *cookie in cookies) {
        if ([COOKIE_NAME compare:cookie.name] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -

-(NSURL*)serverURL {
    return self.operationManager.baseURL;
}
@end
