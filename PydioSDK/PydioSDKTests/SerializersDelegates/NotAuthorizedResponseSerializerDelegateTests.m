//
//  NotAuthorizedResponseSerializerDelegateTests.m
//  PydioSDK
//
//  Created by ME on 26/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "XMLResponseSerializerDelegate.h"
#import "NotAuthorizedResponseParserDelegate.h"
#import "NotAuthorizedResponse.h"

#pragma mark - NotAuthorizedResponseSerializerDelegate Access to private data

@interface NotAuthorizedResponseSerializerDelegate ()
@property (nonatomic,strong) NotAuthorizedResponseParserDelegate* parserDelegate;
@end

#pragma mark - Tests

@interface NotAuthorizedResponseSerializerDelegateTests : XCTestCase
@property (nonatomic,strong) NotAuthorizedResponseSerializerDelegate* serializerDelegate;
@end

@implementation NotAuthorizedResponseSerializerDelegateTests

- (void)setUp
{
    [super setUp];
    self.serializerDelegate = [[NotAuthorizedResponseSerializerDelegate alloc] init];
}

- (void)tearDown
{
    self.serializerDelegate = nil;
    [super tearDown];
}

- (void)testShouldReturnProperXMLParserDelegate
{
    assertThat([self.serializerDelegate xmlParserDelegate],instanceOf([NotAuthorizedResponseParserDelegate class]));
}

-(void)testShouldReturnNotAuthorizedResponseWhenNotLoggedIsYes
{
    NotAuthorizedResponseParserDelegate *parserDelegate = mock([NotAuthorizedResponseParserDelegate class]);
    [given(parserDelegate.notLogged) willReturnBool:YES];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],instanceOf([NotAuthorizedResponse class]));
}

-(void)testShouldReturnNilWhenNotLoggedIsNo
{
    NotAuthorizedResponseParserDelegate *parserDelegate = mock([NotAuthorizedResponseParserDelegate class]);
    [given(parserDelegate.notLogged) willReturnBool:NO];
    self.serializerDelegate.parserDelegate = parserDelegate;
    
    assertThat([self.serializerDelegate parseResult],nilValue());
}

-(void)testErrorUserInfoSholdBeNil
{
    NSObject *object = [[NSObject alloc] init];
    assertThat([self.serializerDelegate errorUserInfo:object],nilValue());
}

@end
