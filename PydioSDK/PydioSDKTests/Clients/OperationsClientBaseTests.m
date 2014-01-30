//
//  OperationsClientBaseTests.m
//  PydioSDK
//
//  Created by ME on 30/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "OperationsClientBaseTests.h"
#import "AFHTTPRequestOperationManager.h"
#import "CookieManager.h"
#import "OperationsClient.h"
#import "XMLResponseSerializer.h"

static CookieManager *cookieManager = nil;

CookieManager* getCookieManager() {
    return cookieManager;
}

id mockedCookieManager(id self, SEL _cmd) {
    return cookieManager;
}

@implementation OperationsClientBaseTests

-(NSDictionary*)defaultRequestParams {
    return @{
             @"Accept-Encoding": @"gzip, deflate",
             @"Accept": @"*/*",
             @"Accept-Language": @"en-us",
             @"Connection": @"keep-alive",
             @"Ajxp-Force-Login": @"true",
             @"User-Agent": @"ajaxplorer-ios-client/1.0"
            };
}

- (void)setUp
{
    [super setUp];
    _methodToExchange = class_getClassMethod([CookieManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedCookieManager);
    cookieManager = mock([CookieManager class]);
    self.operationManager = mock([AFHTTPRequestOperationManager class]);
    self.client = [[OperationsClient alloc] init];
    self.client.operationManager = self.operationManager;
}

- (void)tearDown
{
    self.client = nil;
    self.operationManager = nil;
    cookieManager = nil;
    method_setImplementation(_methodToExchange, _originalIMP);
    _originalIMP = nil;
    _methodToExchange = nil;
    [super tearDown];
}

#pragma mark -

-(id<XMLResponseSerializerDelegate>)xmlResponseSerializerFrom:(AFCompoundResponseSerializer*)compound AtIndex:(NSUInteger)index {
    return ((XMLResponseSerializer*)[compound.responseSerializers objectAtIndex:index]).serializerDelegate;
}


@end
