//
//  RepositoriesResponseSerializer.m
//  PydioSDK
//
//  Created by ME on 19/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "RepositoriesResponseSerializer.h"
#import "RepositoriesParserDelegate.h"
#import "PydioErrors.h"

@implementation RepositoriesResponseSerializer

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
    RepositoriesParserDelegate * responseParser = [[RepositoriesParserDelegate alloc] init];
    [parser setDelegate:responseParser];
    [parser parse];
    
    if (responseParser.repositories) {
        return [NSArray arrayWithArray:responseParser.repositories];
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue: NSLocalizedStringFromTable(@"Error when parsing get repositories response", nil, @"PydioSDK") forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not extract get repositories result: %@", nil, @"PydioSDK"), responseObject] forKey:NSLocalizedFailureReasonErrorKey];
    if (error) {
        *error = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:userInfo];
    }

    return nil;
}

@end
