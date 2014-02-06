//
//  FailingResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 06/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "FailingResponseSerializer.h"
#import "PydioErrors.h"


@interface FailingResponseSerializerTests : XCTestCase
@property (nonatomic,strong) FailingResponseSerializer* responseSerializer;
@end

@implementation FailingResponseSerializerTests

- (void)setUp
{
    [super setUp];
    self.responseSerializer = [[FailingResponseSerializer alloc] init];
}

- (void)tearDown
{
    self.responseSerializer = nil;
    [super tearDown];
}

- (void)testShouldNotValidateAnyAnswer
{
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://test.org"] statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:[NSDictionary dictionary]];
    NSData *data = [NSData data];
    
    NSError *error = nil;
    BOOL result = [self.responseSerializer validateResponse:urlResponse data:data error:&error];
    
    assertThatBool(result,equalToBool(NO));
    assertThatInteger(error.code,equalToInteger(PydioErrorReceivedNotExpectedAnswer));
    assertThat(error.domain,equalTo(PydioErrorDomain));
}

@end
