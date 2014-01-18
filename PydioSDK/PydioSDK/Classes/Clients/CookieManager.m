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

@implementation CookieManager

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
        if ([COOKIE_NAME compare:cookie.name] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

-(User*)userForServer:(NSURL *)server {
    return nil;
}

-(NSString*)secureTokenForServer:(NSURL *)server {
    return nil;
}
@end
