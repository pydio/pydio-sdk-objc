//
//  PydioConnector.h
//  PydioSDK
//
//  Created by MINI on 22.12.2013.
//  Copyright (c) 2013 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PydioConnector : NSObject

@property (readonly, nonatomic) NSString* server;
@property (readonly, nonatomic) NSString* secure_token;
@property (readonly, nonatomic) NSString* seed;
@property (readonly, nonatomic) BOOL requestInProgress;
@property (readonly, nonatomic) BOOL loggedIn;

//-(BOOL)requestSecureToken:(void (^)(BOOL success, NSString *error))resultBlock;
-(BOOL)requestSeed:(void (^)(BOOL success, NSString *error))resultBlock;
-(BOOL)requestLoginWithUserName:(NSString *)username password:(NSString *)password resultBlock:(void (^)(BOOL success, NSString *error))resultBlock;
@end
