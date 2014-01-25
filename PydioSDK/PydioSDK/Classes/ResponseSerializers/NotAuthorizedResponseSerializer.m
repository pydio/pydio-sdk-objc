//
//  NotAuthorizedResponseSerializer.m
//  PydioSDK
//
//  Created by ME on 19/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "NotAuthorizedResponseSerializer.h"
#import "NotAuthorizedResponseParserDelegate.h"
#import "NotAuthorizedResponse.h"


@implementation NotAuthorizedResponseSerializer

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id responseObject = [super responseObjectForResponse:response data:data error:error];
    if (!responseObject) {
        return nil;
    }
    
    NSXMLParser *parser = (NSXMLParser *)responseObject;
    NotAuthorizedResponseParserDelegate *notAuthorizedXMLResponseParser = [[NotAuthorizedResponseParserDelegate alloc] init];
    [parser setDelegate:notAuthorizedXMLResponseParser];
    
    if (notAuthorizedXMLResponseParser.notLogged) {
        return [[NotAuthorizedResponse alloc] init];
    }

    return nil;
}

@end
