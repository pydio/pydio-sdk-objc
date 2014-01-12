//
//  CookieManager.h
//  PydioSDK
//
//  Created by ME on 12/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CookieManager : NSObject
+(CookieManager*)sharedManager;

-(NSArray *)allServerCookies:(NSURL *)server;
-(void)clearAllCookies:(NSURL *)server;
-(BOOL)isCookieSet:(NSURL *)server;

@end
