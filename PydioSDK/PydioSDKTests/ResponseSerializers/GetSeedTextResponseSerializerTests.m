//
//  GetSeedTextResponseSerializerTests.m
//  PydioSDK
//
//  Created by Michal Kloczko on 02/03/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "GetSeedTextResponseSerializer.h"
#import "SeedResponse.h"

#pragma mark - Response from AFHTTPResponseSerializer

static id dataResponse = nil;

static id response(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return dataResponse;
}

#pragma mark - Tests

@interface GetSeedTextResponseSerializerTests : XCTestCase {
    Method _method;
    IMP _originalIMP;
}
@property (nonatomic,strong) GetSeedTextResponseSerializer* responseSerializer;
@end

@implementation GetSeedTextResponseSerializerTests

- (void)setUp
{
    [super setUp];
    _method = class_getInstanceMethod([AFHTTPResponseSerializer class], @selector(responseObjectForResponse:data:error:));
    _originalIMP = method_setImplementation(_method, (IMP)response);
    self.responseSerializer = [[GetSeedTextResponseSerializer alloc] init];
}

- (void)tearDown
{
    self.responseSerializer = nil;
    dataResponse = nil;
    method_setImplementation(_method, _originalIMP);
    [super tearDown];
}

- (void)test_shouldReturnNil_whenNilFromAFNetworking
{
    NSString *seed = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(seed,nilValue());
}

- (void)test_ShouldReturnSeed_WhenSeedReturnedFromAFNetworking
{
    SeedResponse *expectedSeed = [SeedResponse seed:@"seed"];
    dataResponse = [@"seed" dataUsingEncoding:NSUTF8StringEncoding];

    SeedResponse *seed = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];

    assertThat(seed,equalTo(expectedSeed));
}

@end
