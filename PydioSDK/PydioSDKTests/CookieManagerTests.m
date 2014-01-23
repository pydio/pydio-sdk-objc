//
//  CookieManagerTests.m
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

#import "CookieManager.h"
#import <objc/runtime.h>
#import "User.h"


static NSHTTPCookieStorage *mockHTTPCookieStorage = nil;

id mockedSharedStorage(id slf,SEL cmd) {
    return mockHTTPCookieStorage;
}

//AjaXplorer=phh8hhe8ibhrgrc2nuv4ec2sv4

@interface CookieManagerTests : XCTestCase
@property (nonatomic,strong) NSURL* serverURL;
@property (nonatomic,strong) NSArray* arrayWithCookie;
@end

@implementation CookieManagerTests {
    Method _method;
    IMP _originalIMP;
}

- (void)setUp
{
    [super setUp];
    mockHTTPCookieStorage = mock([NSHTTPCookieStorage class]);
    _method = class_getClassMethod([NSHTTPCookieStorage class], @selector(sharedHTTPCookieStorage));
    _originalIMP = method_setImplementation(_method, (IMP)mockedSharedStorage);
    self.serverURL = [NSURL URLWithString:@"http://www.testserver.com/"];
//    NSDictionary *params = @{
//                             NSHTTPCookieOriginURL : @"http://www.testserver.com",
//                             NSHTTPCookieName: @"AjaXplorer",
//                             NSHTTPCookieValue: @"phh8hhe8ibhrgrc2nuv4ec2sv4"
//                             };
//    self.arrayWithCookie = [NSArray arrayWithObject:[NSHTTPCookie cookieWithProperties:params]];
}

- (void)tearDown
{
    self.arrayWithCookie = nil;
    self.serverURL = nil;
    method_setImplementation(_method, _originalIMP);
    mockHTTPCookieStorage = nil;
    [super tearDown];
}

- (void)testInitialization
{
    CookieManager *manager = [CookieManager sharedManager];
    
    assertThat(manager,notNilValue());
}

- (void)testShouldReturnSameInstanceWhenCalled2Times
{
    CookieManager *manager = [CookieManager sharedManager];
    CookieManager *manager2 = [CookieManager sharedManager];
    
    assertThat(manager,sameInstance(manager2));
}

//-(void)testShouldInformAboutExistingOfCookieWhenCookiePresent
//{
//    CookieManager *manager = [CookieManager sharedManager];
//    [given([mockHTTPCookieStorage cookiesForURL:self.serverURL]) willReturn:self.arrayWithCookie];
//
//    BOOL present = [manager isCookieSet:self.serverURL];
//    
//    assertThatBool(present,equalToBool(YES));
//}
//
//-(void)testShouldInformAboutNotExistingOfCookieWhenNoCookiePresent
//{
//    CookieManager *manager = [CookieManager sharedManager];
//    [given([mockHTTPCookieStorage cookiesForURL:self.serverURL]) willReturn:[NSArray array]];
//    
//    BOOL present = [manager isCookieSet:self.serverURL];
//    
//    assertThatBool(present,equalToBool(NO));
//}

-(void)testShouldSetUserForGivenServer
{
    CookieManager *manager = [CookieManager sharedManager];
    User *user = [User userWithId:@"userid" AndPassword:@"userpassword"];
    
    [manager setUser:user ForServer:self.serverURL];
    
    assertThat([manager userForServer:self.serverURL],equalTo(user));
}

-(void)testShouldSetTokenForGivenServer
{
    CookieManager *manager = [CookieManager sharedManager];
    NSString *token = @"faketoken";
    
    [manager setSecureToken:token ForServer:self.serverURL];
    
    assertThat([manager secureTokenForServer:self.serverURL],equalTo(token));
}

-(void)testShouldReturnNilWhenNoUserForGivenServer
{
    CookieManager *manager = [CookieManager sharedManager];
    
    assertThat([manager userForServer:self.serverURL],nilValue());
}

-(void)testShouldReturnNilWhenNoTokenForGivenServer
{
    CookieManager *manager = [CookieManager sharedManager];
    
    assertThat([manager secureTokenForServer:self.serverURL],nilValue());
}

@end
