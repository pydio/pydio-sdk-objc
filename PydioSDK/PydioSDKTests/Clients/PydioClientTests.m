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


static NSString * const TEST_SERVER_ADDRESS = @"http://www.testserver.com/";


@interface PydioClientTests : XCTestCase
@property (nonatomic,strong) PydioClient* client;
@property (nonatomic,strong) AuthorizationClient* authorizationClient;
@end

@implementation PydioClientTests

- (void)setUp
{
    [super setUp];
    self.client = [[PydioClient alloc] initWithServer:TEST_SERVER_ADDRESS];
    self.authorizationClient = mock([AuthorizationClient class]);
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testInitialization
{
    assertThat(self.client.server,equalTo(TEST_SERVER_ADDRESS));
}

-(void)testShouldAuthorizeWhenNoCookie
{
    //given
    
    //when
    [self.client listFiles];
    
    //then
    //Should check if cookie is present,
    //Should call ping
    //Should call getSeed
    //Should call login
}

-(void)testShouldAuthorizeWhenReceivedNotAuthorizedResponse
{
    
    //when
    
    
    
}
@end
