//
//  OperationsClient.m
//  PydioSDK
//
//  Created by ME on 14/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "OperationsClient.h"

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@end

@implementation OperationsClient
-(BOOL)listFilesWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure {
    return NO;
}
@end
