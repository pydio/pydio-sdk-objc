//
//  PydioRequestOperationManager.h
//  PydioSDK
//
//  Created by Michal Kloczko on 05/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

typedef void (^OperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@interface PydioRequestOperationManager : AFHTTPRequestOperationManager
@property (nonatomic, copy) OperationProgressBlock downloadProgress;
@property (nonatomic, copy) OperationProgressBlock uploadProgress;
@end
