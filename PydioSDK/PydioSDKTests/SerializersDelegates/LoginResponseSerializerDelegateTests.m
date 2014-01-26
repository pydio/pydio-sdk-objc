//
//  LoginResponseSerializerDelegateTests.m
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
#import "LoginResponseParserDelegate.h"
#import "LoginResponse.h"

#pragma mark - LoginResponseSerializerDelegate Access to private data

@interface LoginResponseSerializerDelegate ()
@property (nonatomic,strong) LoginResponseParserDelegate* parserDelegate;
@end

#pragma mark - Tests

@interface LoginResponseSerializerDelegateTests : XCTestCase
@property (nonatomic,strong) LoginResponseSerializerDelegate* serializerDelegate;
@end

@implementation LoginResponseSerializerDelegateTests

- (void)setUp
{
    [super setUp];
    self.serializerDelegate = [[LoginResponseSerializerDelegate alloc] init];
}

- (void)tearDown
{
    self.serializerDelegate = nil;
    [super tearDown];
}

- (void)testShouldReturnProperXMLParserDelegate
{
    assertThat([self.serializerDelegate xmlParserDelegate],instanceOf([LoginResponseParserDelegate class]));
}

-(void)testShouldReturnLoginResponseWhenResultIsPresent
{
    LoginResponseParserDelegate *parserDelegate = mock([LoginResponseParserDelegate class]);
    [given(parserDelegate.resultValue) willReturn:@"1"];
    [given(parserDelegate.secureToken) willReturn:@"secure_token"];
    self.serializerDelegate.parserDelegate = parserDelegate;
    LoginResponse *expectedResponse = [[LoginResponse alloc] initWithValue:@"1" AndToken:@"secure_token"];
    
    assertThat([self.serializerDelegate parseResult],equalTo(expectedResponse));
}

-(void)testShouldReturnNilWhenLoginResponseIsNotPresent
{
    assertThat([self.serializerDelegate parseResult],nilValue());
}

-(void)testErrorUserInfoSholdBeNotNil
{
    NSObject *object = [[NSObject alloc] init];
    assertThat([self.serializerDelegate errorUserInfo:object],notNilValue());
}

@end
