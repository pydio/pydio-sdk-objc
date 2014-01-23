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
    NSData * xmlData = [self loadFixture:@"proper_login_response.xml"];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    parser.delegate = self.responseDelegate;
    
    BOOL result = [parser parse];

    assertThatBool(result,equalToBool(YES));
    assertThat(self.responseDelegate.resultValue,equalTo(@"1"));
    assertThat(self.responseDelegate.secureToken,equalTo(@"2w70XYorR6AgEWZaEUggf5NHun4ZZEPj"));
}

#pragma mark -

-(NSData*)loadFixture:(NSString*)name {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:name ofType:nil];
    
    return [[NSData alloc] initWithContentsOfFile:path];
}

@end
