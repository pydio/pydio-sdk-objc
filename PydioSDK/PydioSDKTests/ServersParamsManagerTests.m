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

#import "ServersParamsManager.h"
#import <objc/runtime.h>
#import "User.h"


static NSHTTPCookieStorage *mockHTTPCookieStorage = nil;

id mockedSharedStorage(id slf,SEL cmd) {
    return mockHTTPCookieStorage;
}

//AjaXplorer=phh8hhe8ibhrgrc2nuv4ec2sv4

@interface ServersParamsManagerTests : XCTestCase
@property (nonatomic,strong) NSURL* serverURL;
@property (nonatomic,strong) NSArray* arrayWithCookie;
@property (nonatomic,strong) ServersParamsManager *manager;
@end

@implementation ServersParamsManagerTests {
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
    self.manager = [[ServersParamsManager alloc] init];
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

//- (void)testInitialization
//{
//    ServersParamsManager *manager = [ServersParamsManager sharedManager];
//    
//    assertThat(manager,notNilValue());
//}
//
//- (void)testShouldReturnSameInstanceWhenCalled2Times
//{
//    ServersParamsManager *manager = [ServersParamsManager sharedManager];
//    ServersParamsManager *manager2 = [ServersParamsManager sharedManager];
//    
//    assertThat(manager,sameInstance(manager2));
//}
//
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

#pragma mark - User

-(void)testShouldSetUserForGivenServer
{
    User *user = [User userWithId:@"userid" AndPassword:@"userpassword"];
    
    [self.manager setUser:user ForServer:self.serverURL];
    
    assertThat([self.manager userForServer:self.serverURL],equalTo(user));
}

-(void)testShouldReturnNilWhenNoUserForGivenServer
{
    assertThat([self.manager userForServer:self.serverURL],nilValue());
}

#pragma mark - Token

-(void)testShouldSetTokenForGivenServer
{
    NSString *token = @"faketoken";
    
    [self.manager setSecureToken:token ForServer:self.serverURL];
    
    assertThat([self.manager secureTokenForServer:self.serverURL],equalTo(token));
}

-(void)test_ShouldClearSecureTokenForServer_WhenClearSecureTokenWasCalled {
    //given
    User *user = [User userWithId:@"userid" AndPassword:@"userpassword"];
    [self.manager setUser:user ForServer:self.serverURL];
    //when
    [self.manager clearSecureToken:self.serverURL];
    //then
    assertThat([self.manager secureTokenForServer:self.serverURL],nilValue());
}

#pragma mark - Seed

-(void)test_shouldSetSeedForGivenServer_whenSetSeedCalled {
    //given
    NSString *seed = @"seed";
    //when
    [self.manager setSeed:seed ForServer:self.serverURL];
    //then
    assertThat([self.manager seedForServer:self.serverURL],equalTo(seed));
}

-(void)test_shouldClearSecureTokenForServer_whenClearSecureTokenWasCalled {
    //given
    NSString *seed = @"seed";
    [self.manager setSeed:seed ForServer:self.serverURL];
    //when
    [self.manager clearSeed:self.serverURL];
    //then
    assertThat([self.manager seedForServer:self.serverURL],nilValue());
}

#pragma mark - list of servers

-(void)test_ShouldReturnListOfServersForAddedUsers_WhenAddedUsersForServers {
    //given
    User *user = [User userWithId:@"userid" AndPassword:@"userpassword"];
    User *user2 = [User userWithId:@"userid1" AndPassword:@"userpassword1"];
    NSURL *serverURL = [NSURL URLWithString:@"http://www.testserver2.com/"];
    [self.manager setUser:user ForServer:self.serverURL];
    [self.manager setUser:user2 ForServer:serverURL];
    NSComparisonResult(^comparator)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 absoluteString] compare:[obj2 absoluteString]];
    };
    NSArray *expectedArray = [@[self.serverURL,serverURL] sortedArrayUsingComparator:comparator];
    //when
    NSArray *array = [[self.manager serversList] sortedArrayUsingComparator:comparator];
    //then    
    assertThat(array,equalTo(expectedArray));
}

@end
