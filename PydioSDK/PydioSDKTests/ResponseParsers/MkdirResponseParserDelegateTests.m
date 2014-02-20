//
//  MkdirResponseParserDelegateTests.m
//  PydioSDK
//
//  Created by Michal Kloczko on 20/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "MkdirResponseParserDelegate.h"
#import "XCTestCase+XMLFixture.h"


@interface MkdirResponseParserDelegateTests : XCTestCase
@property (nonatomic,strong) MkdirResponseParserDelegate* parserDelegate;
@end

@implementation MkdirResponseParserDelegateTests

- (void)setUp
{
    [super setUp];
    self.parserDelegate = [[MkdirResponseParserDelegate alloc] init];
}

- (void)tearDown
{
    self.parserDelegate = nil;
    [super tearDown];
}

- (void)test_shouldRecognizeXMLSuccessResponseAsSuccess
{
    NSXMLParser *parser = [self parserWithFixture:@"mkdir_success_response.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(YES));
    assertThatBool(self.parserDelegate.success,equalToBool(YES));
}

- (void)test_shouldNotRecognizeXMLErrorResponseAsSuccess
{
    NSXMLParser *parser = [self parserWithFixture:@"error_response.xml" delegate:self.parserDelegate];
    
    BOOL result = [parser parse];
    
    assertThatBool(result,equalToBool(NO));
    assertThatBool(self.parserDelegate.success,equalToBool(NO));
}

@end
