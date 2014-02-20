//
//  ErrorResponseParserDelegateTests.m
//  PydioSDK
//
//  Created by ME on 10/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "ErrorResponseParserDelegate.h"
#import "XCTestCase+XMLFixture.h"


@interface ErrorResponseParserDelegateTests : XCTestCase
@property (nonatomic,strong) ErrorResponseParserDelegate* parserDelegate;
@end

@implementation ErrorResponseParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.parserDelegate = [[ErrorResponseParserDelegate alloc] init];
}

- (void)tearDown
{
    self.parserDelegate = nil;
    [super tearDown];
}

- (void)testShouldParseErrorMessage
{
    NSXMLParser *parser = [self parserWithFixture:@"error_response.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThat(self.parserDelegate.errorMessage,equalTo(@"Example error message!"));
}

-(void)testShouldNotRecognizeOtherResponsesAsErrorResponse
{
    NSArray *responses = @[
                           @"login_response.xml",
                           @"get_registers_response.xml",
                           @"ls_response2.xml",
                           @"mkdir_success_response.xml"
                           ];
    
    for (NSString *file in responses) {
        self.parserDelegate = [[ErrorResponseParserDelegate alloc] init];
        NSXMLParser *parser = [self parserWithFixture:file delegate:self.parserDelegate];
        
        BOOL result = [parser parse];
        
        assertThatBool(result,equalToBool(NO));
        XCTAssertNil(self.parserDelegate.errorMessage, @"File: %@ should not be recognized as error response",file);
        self.parserDelegate = nil;
    }
}

@end
