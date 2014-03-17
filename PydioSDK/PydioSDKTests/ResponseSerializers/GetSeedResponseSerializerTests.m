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


#pragma mark - Tests

@interface GetSeedResponseSerializerTests : XCTestCase 
@property (nonatomic,strong) GetSeedResponseSerializer* responseSerializer;
@end

@implementation GetSeedResponseSerializerTests

- (void)setUp
{
    [super setUp];
    self.responseSerializer = [[GetSeedResponseSerializer alloc] init];
}

- (void)tearDown
{
    self.responseSerializer = nil;
    [super tearDown];
}

-(void)test_ShouldSetupMainResponseSerializer {
    assertThatUnsignedInteger(self.responseSerializer.responseSerializers.count,equalToUnsignedInteger(2));
    assertThat([self.responseSerializer.responseSerializers objectAtIndex:0],instanceOf([GetSeedJSONResponseSerializer class]));
    assertThat([self.responseSerializer.responseSerializers objectAtIndex:1],instanceOf([GetSeedTextResponseSerializer class]));
}

@end
