//
//  GetSeedResponseSerializerTests.m
//  PydioSDK
//
//  Created by ME on 25/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "GetSeedResponseSerializer.h"
#import <objc/runtime.h>


#pragma mark - Response from AFHTTPResponseSerializer

static NSData* dataResponse = nil;

static id response(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return dataResponse;
}

#pragma mark - Tests

@interface GetSeedResponseSerializerTests : XCTestCase {
    Method _method;
    IMP _originalIMP;
}
@property (nonatomic,strong) GetSeedResponseSerializer* responseSerializer;
@end

@implementation GetSeedResponseSerializerTests

- (void)setUp
{
    [super setUp];
    _method = class_getInstanceMethod([AFHTTPResponseSerializer class], @selector(responseObjectForResponse:data:error:));
    _originalIMP = method_setImplementation(_method, (IMP)response);
    self.responseSerializer = [[GetSeedResponseSerializer alloc] init];
}

- (void)tearDown
{
    dataResponse = nil;
    method_setImplementation(_method, _originalIMP);
    self.responseSerializer = nil;
    [super tearDown];
}

- (void)testShouldReturnNilWhenNilFromAFNetworking
{
    NSString *seed = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(seed,nilValue());
}

- (void)testShouldReturnSeedWhenSeedReturnedFromAFNetworking
{
    NSString *expectedSeed = @"seed";
    dataResponse = [expectedSeed dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *seed = [self.responseSerializer responseObjectForResponse:nil data:nil error:nil];
    
    assertThat(seed,equalTo(expectedSeed));
}

@end
