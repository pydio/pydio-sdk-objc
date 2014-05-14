//
//  DownloadNodesResponseSerializer.m
//  PydioSDK
//
//  Created by Michal Kloczko on 10/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "DownloadNodesResponseSerializer.h"
#import "PydioErrors.h"

static NSString * const CONTENT_TYPE_PART = @"application/force-download";
static NSString * const CONTENT_TRANSFER_ENCODING = @"binary";

#pragma mark - Helper to get headers values

@implementation NSDictionary (HTTPHeaders)

-(NSString*)contentTransferEncoding {
    return [self valueForKey:@"Content-Transfer-Encoding"];
}

-(NSString*)contentType {
    return [self valueForKey:@"Content-Type"];
}

@end

#pragma mark - Helper to compare to String

@implementation NSString (Substring)

-(BOOL)startsWithString:(NSString*)string {
    return [[self substringToIndex:string.length] isEqualToString:string];
}

@end

#pragma mark - Serializer

@implementation DownloadNodesResponseSerializer

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error
{
    BOOL result = [super validateResponse:response data:data error:error];
    if (result && ![self areHeadersCorrect:response.allHeaderFields]) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorNotAZipFileResponse userInfo:nil];
        }
        return NO;
    }
    
    return result;
}

-(BOOL)areHeadersCorrect:(NSDictionary *)headers {
    return
    [[headers contentTransferEncoding] isEqualToString:CONTENT_TRANSFER_ENCODING]
    &&
    [[headers contentType] startsWithString:CONTENT_TYPE_PART];
}

@end
