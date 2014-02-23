//
//  PydioClient.h
//  PydioSDK
//
//  Created by ME on 09/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ListNodesRequestParams;
@class MkDirRequestParams;
@class DeleteNodesRequestParams;


@interface PydioClient : NSObject
@property (readonly,nonatomic,strong) NSURL* serverURL;
@property (readonly,nonatomic,assign) BOOL progress;

-(instancetype)initWithServer:(NSString *)server;

-(BOOL)authorizeWithSuccess:(void(^)())success failure:(void(^)(NSError* error))failure;
-(BOOL)listWorkspacesWithSuccess:(void(^)(NSArray* workspaces))success failure:(void(^)(NSError* error))failure;
-(BOOL)listNodes:(ListNodesRequestParams*)params WithSuccess:(void(^)(NSArray* nodes))success failure:(void(^)(NSError* error))failure;
-(BOOL)mkdir:(MkDirRequestParams*)params WithSuccess:(void(^)())success failure:(void(^)(NSError* error))failure;
-(BOOL)deleteNodes:(DeleteNodesRequestParams*)params WithSuccess:(void(^)())success failure:(void(^)(NSError* error))failure;
@end
