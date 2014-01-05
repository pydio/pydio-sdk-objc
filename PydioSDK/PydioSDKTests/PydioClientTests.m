//
//  PydioClientTests.m
//  PydioSDK
//
//  Created by ME on 05/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "PydioClient.h"
#import "ServerConfig.h"
#import "AFHTTPRequestOperationManager.h"

static AFHTTPRequestOperationManager *operationManager;

AFHTTPRequestOperationManager* getOperationManager(id self, SEL _cmd, NSString* server) {
    return operationManager;
}

@interface PydioClientTests : XCTestCase {
    Method _exchangedMethod;
    IMP _originalIMP;
}
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    
    operationManager = mock([AFHTTPRequestOperationManager class]);
	_exchangedMethod = class_getInstanceMethod([PydioClient class], @selector(createRequestOperationManager:));
    _originalIMP = method_setImplementation(_exchangedMethod, (IMP)getOperationManager);
}

- (void)tearDown
{
    operationManager = nil;
    method_setImplementation(_exchangedMethod, _originalIMP);
    [super tearDown];
}

- (void)testInitialization
{
    ServerConfig *config = [[ServerConfig alloc] init];
    
    PydioClient *client = [[PydioClient alloc] initWithServerConfig:config];
    [verify(operationManager) setRequestSerializer:[client performSelector:@selector(defaultRequestSerializer)]];
    assertThatInt((int)[client performSelector:@selector(processingState)],equalToInt(0));
    
}

@end

#pragma clang diagnostic pop