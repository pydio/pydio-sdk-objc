//
//  CookieManager.m
//  PydioSDK
//
//  Created by ME on 12/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "CookieManager.h"

static NSString * const COOKIE_NAME = @"AjaXplorer";
static CookieManager *manager = nil;

@interface CookieManager ()
@property (nonatomic,strong) NSMutableDictionary *users;
@property (nonatomic,strong) NSMutableDictionary *tokens;
@end

@implementation CookieManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.users = [NSMutableDictionary dictionary];
        self.tokens = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+(CookieManager*)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CookieManager alloc] init];
    });
    
    return manager;
}

-(NSArray *)allServerCookies:(NSURL *)server {
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:server];
}

-(void)clearAllCookies:(NSURL *)server {
    NSArray *cookies = [self allServerCookies:server];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

-(BOOL)isCookieSet:(NSURL *)server {
    NSArray *cookies = [self allServerCookies:server];
    for (NSHTTPCookie *cookie in cookies) {
        if ([COOKIE_NAME isEqualToString:cookie.name]) {
            return YES;
        }
    }
    return NO;
}

-(void)setUser:(User*)user ForServer:(NSURL *)server {
    [self.users setValue:user forKey:server.absoluteString];
}

-(User*)userForServer:(NSURL *)server {
    return [self.users valueForKey:server.absoluteString];
}

-(void)setSecureToken:(NSString*)token ForServer:(NSURL *)server {
    [self.tokens setValue:token forKey:server.absoluteString];
}

-(NSString*)secureTokenForServer:(NSURL *)server {
    return [self.tokens valueForKey:server.absoluteString];
}

-(NSArray*)serversList {
    return [self.users allKeys];
}
@end
