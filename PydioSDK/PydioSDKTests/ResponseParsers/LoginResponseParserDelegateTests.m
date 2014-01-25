//
//  LoginResponseParserDelegateTests.m
//  PydioSDK
//
//  Created by ME on 23/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "LoginResponseParserDelegate.h"
#import "XCTestCase+XMLFixture.h"


@interface LoginResponseParserDelegateTests : XCTestCase
@property (nonatomic,strong) LoginResponseParserDelegate* responseDelegate;
@end

@implementation LoginResponseParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.responseDelegate = [[LoginResponseParserDelegate alloc] init];
}

- (void)tearDown
{
    self.responseDelegate = nil;
    [super tearDown];
}

- (void)testShouldParseCorrectLoginResult
{
    NSXMLParser *parser = [self parserWithFixture:@"login_response.xml" delegate:self.responseDelegate];
    
    BOOL result = [parser parse];

    assertThatBool(result,equalToBool(YES));
    assertThat(self.responseDelegate.resultValue,equalTo(@"1"));
    assertThat(self.responseDelegate.secureToken,equalTo(@"2w70XYorR6AgEWZaEUggf5NHun4ZZEPj"));
}

@end
