//
//  PydioClient.h
//  PydioSDK
//
//  Created by ME on 09/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ListNodesRequestParams;


@interface PydioClient : NSObject
@property (readonly,nonatomic,strong) NSURL* serverURL;
@property (readonly,nonatomic,assign) BOOL progress;

-(instancetype)initWithServer:(NSString *)server;

-(BOOL)listWorkspacesWithSuccess:(void(^)(NSArray* workspaces))success failure:(void(^)(NSError* error))failure;
-(BOOL)listNodes:(ListNodesRequestParams*)params WithSuccess:(void(^)(NSArray* nodes))success failure:(void(^)(NSError* error))failure;
@end
