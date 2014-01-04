//
//  LoginResponseSerializer.m
//  PydioSDK
//
//  Created by ME on 04/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "LoginResponseSerializer.h"

@implementation LoginResponseSerializer

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id responseObject = [super responseObjectForResponse:response data:data error:error];
    if (responseObject) {
        return [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];;
    }
    
    return nil;
}

@end
