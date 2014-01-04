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
#import "BootConfResponseSerializer.h"
#import "RequestSeedResponseSerializer.h"
#import "LoginResponseSerializer.h"
#import "LoginResponse.h"


static NSString * const COOKIE_NAME = @"AjaXplorer";
static NSString * const GET_BOOT_CONF = @"index.php?get_action=get_boot_conf";
static NSString * const GET_SEED = @"index.php?get_action=get_seed";
static NSString * const LOGIN = @"index.php";


typedef enum {
    PSNone,
    PSBootConfig,
    PSRequestSeed,
    PSLogin,
    PSLogged
} ProcessingState;

@interface PydioClient ()
@property (nonatomic,strong) AFHTTPRequestOperationManager* operationManager;
@property (nonatomic,assign) ProcessingState processingState;
@property (nonatomic,strong) NSString* bootConfSsecureToken;
@property (nonatomic,strong) NSString* seed;
@property (nonatomic,strong) NSString* loginSecureTooken;

-(AFHTTPRequestSerializer*)getRequestSerializer;
-(NSArray *)allServerCookies;
-(void)clearAllCookies;
-(BOOL)isCookieSet;
-(NSURL *)serverURL;
-(void)requestSecureToken;
-(void)requestSeed;
-(void)requestLogin;
-(NSDictionary*)loginParameters;
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
        self.operationManager.requestSerializer = [self getRequestSerializer];
        self.processingState = PSNone;
    }
    return self;
}

-(AFHTTPRequestSerializer*)getRequestSerializer
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [serializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [serializer setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
    [serializer setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [serializer setValue:@"true" forHTTPHeaderField:@"Ajxp-Force-Login"];
    [serializer setValue:@"ajaxplorer-ios-client/1.0" forHTTPHeaderField:@"User-Agent"];
    
    return serializer;
}

#pragma mark -

-(void)login {
    if (self.inProgress) {
        return;
    }
    
    [self markRequestInProgres];
    [self clearAllCookies];
    self.bootConfSsecureToken = nil;
    _loggedToServer = NO;
    
    [self requestSecureToken];
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

#pragma mark - requests

-(void)markRequestInProgres {
    _inProgress = YES;
}

-(void)markRequestNotInProgres {
    _inProgress = NO;
}

-(void)requestSecureToken {
    self.processingState = PSBootConfig;
    self.bootConfSsecureToken = nil;
    
    self.operationManager.responseSerializer = [[BootConfResponseSerializer alloc] init];
    [self.operationManager GET:GET_BOOT_CONF parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.bootConfSsecureToken = responseObject;
        [self requestSeed];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self markRequestNotInProgres];
        _lastError = error;
    }];
}

-(void)requestSeed {
    self.processingState = PSRequestSeed;
    self.bootConfSsecureToken = nil;
    
    self.operationManager.responseSerializer = [RequestSeedResponseSerializer serializer];
    [self.operationManager GET:GET_SEED parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.seed = responseObject;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _lastError = error;
    }];
    
}

-(void)requestLogin {
    self.processingState = PSLogin;
    self.loginSecureTooken = nil;
    
    self.operationManager.responseSerializer = [LoginResponseSerializer serializer];
    NSDictionary *params = [self loginParameters];
    
    [self.operationManager POST:LOGIN parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.loginSecureTooken = responseObject;
        [self markRequestNotInProgres];
        LoginResponse *loginResponse = (LoginResponse *)responseObject;
        if (loginResponse) {
            self.loginSecureTooken = loginResponse.secureToken;
        }
        
        self.processingState = PSLogged;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self markRequestNotInProgres];
    }];
}

-(NSDictionary*)loginParameters {
    return @{
             @"get_action": @"login",
             @"userid": self.serverConfig.userid,
             @"password": [[NSString stringWithFormat:@"%@%@", [self.serverConfig.password md5], self.seed] md5],
             @"login_seed": self.seed
             };
}
@end
