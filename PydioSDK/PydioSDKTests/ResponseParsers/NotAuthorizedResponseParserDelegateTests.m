//
//  NotAuthorizedResponseParserTests.m
//  PydioSDK
//
//  Created by ME on 25/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND 
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHOTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "NotAuthorizedResponseParserDelegate.h"
#import "XCTestCase+XMLFixture.h"

@interface NotAuthorizedResponseParserDelegateTests : XCTestCase
@property(nonatomic,strong) NotAuthorizedResponseParserDelegate *parserDelegate;
@end

@implementation NotAuthorizedResponseParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.parserDelegate = [[NotAuthorizedResponseParserDelegate alloc] init];
}

- (void)tearDown
{
    self.parserDelegate = nil;
    [super tearDown];
}

- (void)testInitialization
{
    assertThatBool(self.parserDelegate.notLogged,equalToBool(NO));
}


- (void)testShouldParseCorrectNotAuthorizedResponse
{
    NSXMLParser *parser = [self parserWithFixture:@"unathorized_response.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThatBool(self.parserDelegate.notLogged,equalToBool(YES));
}

- (void)testShouldParseCorrectNotAuthorizedResponseWhenEmptyXmlListWithRegisters
{
    NSXMLParser *parser = [self parserWithFixture:@"unathorized_response2.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];

    assertThatBool(result,equalToBool(YES));
    assertThatBool(self.parserDelegate.notLogged,equalToBool(YES));
}

-(void)testShouldNotRecognizeOtherResponsesAsNotLogged
{
    NSArray *responses = @[
                           @"login_response.xml",
                           @"get_registers_response.xml",
                           @"ls_response2.xml",
                           @"error_response.xml",
                           @"mkdir_success_response.xml"
                          ];
    
    for (NSString *file in responses) {
        self.parserDelegate = [[NotAuthorizedResponseParserDelegate alloc] init];
        NSXMLParser *parser = [self parserWithFixture:file delegate:self.parserDelegate];
        
        BOOL result = [parser parse];
        
        assertThatBool(result,equalToBool(NO));
        XCTAssertFalse(self.parserDelegate.notLogged, @"File: %@ should not be recognized as unathorized response",file);
        self.parserDelegate = nil;
    }
}

@end
