//
//  PydioRequestOperationManager.m
//  PydioSDK
//
//  Created by Michal Kloczko on 05/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "PydioRequestOperationManager.h"

@implementation PydioRequestOperationManager

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [super HTTPRequestOperationWithRequest:request success:success failure:failure];
    [operation setDownloadProgressBlock:self.downloadProgress];
    [operation setUploadProgressBlock:self.uploadProgress];
    
    return operation;
}

@end
