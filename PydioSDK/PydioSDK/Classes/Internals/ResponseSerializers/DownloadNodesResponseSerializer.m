//
//  DownloadNodesResponseSerializer.m
//  PydioSDK
//
//  Created by Michal Kloczko on 10/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "DownloadNodesResponseSerializer.h"
#import "PydioErrors.h"

@implementation DownloadNodesResponseSerializer

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error
{
    BOOL result = [super validateResponse:response data:data error:error];
    if (result && ![[response.allHeaderFields valueForKey:@"Content-Type"] isEqualToString:@"application/force-download; name=\"Files.zip\""]) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorNotAZipFileResponse userInfo:nil];
        }
        return NO;
    }
    
    return result;
}

@end
