//
//  PydioClientTests.m
//  PydioSDK
//
//  Created by ME on 09/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "PydioClient.h"
#import "AuthorizationClient.h"
#import "CookieManager.h"
#import <objc/runtime.h>

static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";
static CookieManager *cookieManager = nil;

id mockedSharedManager(id self, SEL _cmd) {
    return cookieManager;
}

#pragma mark - Tested derived object



#pragma mark -

@interface PydioClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) PydioClient* client;
@property (nonatomic,strong) AuthorizationClient* authorizationClient;
@end


@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    _methodToExchange = class_getClassMethod([CookieManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedSharedManager);
    cookieManager = mock([CookieManager class]);
    self.authorizationClient = mock([AuthorizationClient class]);
    
    self.client = [[PydioClient alloc] initWithServer:TEST_SERVER_ADDRESS];
}

- (void)tearDown
{
    method_setImplementation(_methodToExchange, _originalIMP);
    cookieManager = nil;
    self.authorizationClient = nil;
    self.client = nil;
    [super tearDown];
}

#pragma mark - Tests

- (void)testInitialization
{
    assertThat(self.client.server, equalTo(TEST_SERVER_ADDRESS));
}

-(void)testShouldAuthorizeWhenNoCookie
{
    //given
    
    //when
    [self.client listFiles];
    
    //then
    //Should check if cookie is present
    [verify(cookieManager) isCookieSet:equalTo([self testServerURL])];
    //Should call ping
    //Should call getSeed
    //Should call login
}

-(void)testShouldAuthorizeWhenReceivedNotAuthorizedResponse
{
    
    //when
}

-(NSURL*)testServerURL {
    return [NSURL URLWithString:TEST_SERVER_ADDRESS];
}

@end
