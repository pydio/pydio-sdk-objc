//
//  LoginResponseSerializer.m
//  PydioSDK
//
//  Created by ME on 04/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "LoginResponseSerializer.h"
#import "LoginResponseParserDelegate.h"
#import "LoginResponse.h"
#import "PydioErrors.h"


@implementation LoginResponseSerializer

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
    LoginResponseParserDelegate *loginXMLResponse = [self createResponseParserDelegate];
    [parser setDelegate:loginXMLResponse];
    [parser parse];
    
    if (loginXMLResponse.resultValue) {
        return [[LoginResponse alloc] initWithValue:loginXMLResponse.resultValue AndToken:loginXMLResponse.secureToken];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue: NSLocalizedStringFromTable(@"Error when parsing login response", nil, @"PydioSDK") forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not extract login result value from: %@", nil, @"PydioSDK"), responseObject] forKey:NSLocalizedFailureReasonErrorKey];
    if (error) {
        *error = [[NSError alloc] initWithDomain:PydioErrorDomain code:PydioErrorUnableToParseAnswer userInfo:userInfo];
    }
    
    return nil;
}

-(LoginResponseParserDelegate*)createResponseParserDelegate
{
    return [[LoginResponseParserDelegate alloc] init];
}
@end
