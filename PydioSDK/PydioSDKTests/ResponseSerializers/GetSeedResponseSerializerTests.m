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
#import "GetSeedTextResponseSerializer.h"
#import "GetSeedJSONResponseSerializer.h"
#import <objc/runtime.h>
#import "SeedResponse.h"


#pragma mark - Response from AFHTTPResponseSerializer

static id dataResponse = nil;

static id response(id self, SEL _cmd, NSURLResponse * response, NSData *data, NSError *__autoreleasing *error) {
    return dataResponse;
}

#pragma mark - Tests

@interface GetSeedResponseSerializerTests : XCTestCase {
    Method _method;
    IMP _originalIMP;
}
@property (nonatomic,strong) GetSeedResponseSerializer* mainResponseSerializer;
@property (nonatomic,strong) GetSeedTextResponseSerializer* textResponseSerializer;
@property (nonatomic,strong) GetSeedJSONResponseSerializer* jsonResponseSerializer;
@end

@implementation GetSeedResponseSerializerTests

- (void)setUp
{
    [super setUp];
    _method = class_getInstanceMethod([AFHTTPResponseSerializer class], @selector(responseObjectForResponse:data:error:));
    _originalIMP = method_setImplementation(_method, (IMP)response);
    self.textResponseSerializer = [[GetSeedTextResponseSerializer alloc] init];
    self.jsonResponseSerializer = [[GetSeedJSONResponseSerializer alloc] init];
    self.mainResponseSerializer = [[GetSeedResponseSerializer alloc] init];
}

- (void)tearDown
{
    dataResponse = nil;
    method_setImplementation(_method, _originalIMP);
    self.mainResponseSerializer = nil;
    self.jsonResponseSerializer = nil;
    self.textResponseSerializer = nil;
    [super tearDown];
}

-(void)test_ShouldSetupMainResponseSerializer {
    
    assertThatUnsignedInteger(self.mainResponseSerializer.responseSerializers.count,equalToUnsignedInteger(2));
    assertThat([self.mainResponseSerializer.responseSerializers objectAtIndex:0],instanceOf([GetSeedTextResponseSerializer class]));
    assertThat([self.mainResponseSerializer.responseSerializers objectAtIndex:1],instanceOf([GetSeedJSONResponseSerializer class]));
}

//TODO: Separate tests

//- (void)testShouldReturnNilWhenNilFromAFNetworking
//{
//    NSString *seed = [self.mainResponseSerializer responseObjectForResponse:nil data:nil error:nil];
//    
//    assertThat(seed,nilValue());
//}
//
//- (void)test_ShouldReturnSeed_WhenSeedReturnedFromAFNetworking
//{
//    SeedResponse *expectedSeed = [SeedResponse seed:@"seed"];
//    dataResponse = [@"seed" dataUsingEncoding:NSUTF8StringEncoding];
//    
//    SeedResponse *seed = [self.mainResponseSerializer responseObjectForResponse:nil data:nil error:nil];
//    
//    assertThat(seed,equalTo(expectedSeed));
//}
//
//- (void)test_ShouldReturnSeedWithCaptcha_WhenSeedReturnedFromAFNetworking
//{
//    SeedResponse *expectedSeed = [SeedResponse seedWithCaptcha:@"seed"];
//    dataResponse = @{ @"seed" : @"seed", @"captcha":[NSNumber numberWithBool:YES]};
//    
//    SeedResponse *seed = [self.mainResponseSerializer responseObjectForResponse:nil data:nil error:nil];
//    
//    assertThat(seed,equalTo(expectedSeed));
//}

@end
