//
//  OperationsClientTests.m
//  PydioSDK
//
//  Created by ME on 19/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#import "OperationsClient.h"
#import <objc/runtime.h>
#import "CookieManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "BlocksCallResult.h"
#import "PydioErrors.h"
#import "PydioErrorResponse.h"
#import "NotAuthorizedResponse.h"
#import "XMLResponseSerializer.h"
#import "XMLResponseSerializerDelegate.h"
#import "FailingResponseSerializer.h"


#pragma mark - Helpers

static const NSString * const TEST_TOKEN = @"j9tJRcVJYjKyfphibjRX47YgyVN1eoIv";
static const NSString * const GET_ACTION_BASE = @"index.php?get_action=";

static CookieManager *cookieManager = nil;

static id mockedCookieManager(id self, SEL _cmd) {
    return cookieManager;
}

#pragma mark - Exposing private members of tested class for test purposes

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@property (nonatomic,copy) void(^successBlock)(id response);
@property (nonatomic,copy) void(^failureBlock)(NSError* error);
@property (nonatomic,copy) void(^successResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
@property (nonatomic,copy) void(^failureResponseBlock)(AFHTTPRequestOperation *operation, NSError *error);

-(void)setupResponseBlocks;
-(NSString*)actionWithTokenIfNeeded:(NSString*)action;
@end

#pragma mark - Test class

@interface OperationsClientTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic,strong) OperationsClient *client;

@end

@implementation OperationsClientTests

#pragma mark - Helpers

-(void)setupClientForBlockResponse:(BlocksCallResult*)result {
    self.client.progress = YES;
    self.client.successBlock = [result successBlock];
    self.client.failureBlock = [result failureBlock];
    [self.client setupResponseBlocks];
}

-(void)assertClientCleanStateAfterBlockCall {
    assertThatBool(self.client.progress,equalToBool(NO));
    assertThat(self.client.successBlock,nilValue());
    assertThat(self.client.failureBlock,nilValue());
    assertThat(self.client.successResponseBlock,nilValue());
    assertThat(self.client.failureResponseBlock,nilValue());
}

-(NSString*)workspacesURL {
    return [NSString stringWithFormat:@"%@%@",GET_ACTION_BASE,@"get_xml_registry&xPath=user/repositories"];
}

-(NSString*)listFilesURL {
    return [NSString stringWithFormat:@"%@%@",GET_ACTION_BASE,@"ls"];
}

-(NSDictionary*)defaultRequestParams {
    return @{
             @"Accept-Encoding": @"gzip, deflate",
             @"Accept": @"*/*",
             @"Accept-Language": @"en-us",
             @"Connection": @"keep-alive",
             @"Ajxp-Force-Login": @"true",
             @"User-Agent": @"ajaxplorer-ios-client/1.0"
             };
}

-(void) assertOperationManagerHasDefaultRequestSerializerSet {
    MKTArgumentCaptor *requestSerializerCaptor = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setRequestSerializer:[requestSerializerCaptor capture]];
    assertThat(((AFHTTPRequestSerializer*)[requestSerializerCaptor value]).HTTPRequestHeaders,equalTo(self.defaultRequestParams));
}

-(id<XMLResponseSerializerDelegate>)xmlResponseSerializerFrom:(AFCompoundResponseSerializer*)compound AtIndex:(NSUInteger)index {
    return ((XMLResponseSerializer*)[compound.responseSerializers objectAtIndex:index]).serializerDelegate;
}

-(AFCompoundResponseSerializer*)compundResponseSerializer {
    MKTArgumentCaptor *responseSerializer = [[MKTArgumentCaptor alloc] init];
    [verify(self.operationManager) setResponseSerializer:[responseSerializer capture]];
    return (AFCompoundResponseSerializer*)[responseSerializer value];
}

-(void)assertDefaultResponseSerializer:(AFCompoundResponseSerializer*)serializer {
    assertThatUnsignedInteger(serializer.responseSerializers.count,equalToUnsignedInteger(4));
    assertThat([serializer.responseSerializers objectAtIndex:0],instanceOf([XMLResponseSerializer class]));
    assertThat([serializer.responseSerializers objectAtIndex:1],instanceOf([XMLResponseSerializer class]));
    assertThat([serializer.responseSerializers objectAtIndex:3],instanceOf([FailingResponseSerializer class]));
    
    assertThat([self xmlResponseSerializerFrom:serializer AtIndex:0],instanceOf([NotAuthorizedResponseSerializerDelegate class]));
    assertThat([self xmlResponseSerializerFrom:serializer AtIndex:1],instanceOf([ErrorResponseSerializerDelegate class]));
}

-(void)assertResponseSerializer:(AFCompoundResponseSerializer*)serializer AtResponsePositionHas:(Class)class {
    assertThat([serializer.responseSerializers objectAtIndex:2],instanceOf([XMLResponseSerializer class]));
    assertThat([self xmlResponseSerializerFrom:serializer AtIndex:2],instanceOf(class));
}

-(void)assertDefaultResponseSerializerWithClass:(Class)class {
    AFCompoundResponseSerializer *compound = [self compundResponseSerializer];
    [self assertDefaultResponseSerializer:compound];
    [self assertResponseSerializer:compound AtResponsePositionHas:class];
}

-(void)assertClientBlocksSuccess:(SuccessBlock)success AndFailure:(FailureBlock)failure {
    assertThat(self.client.successBlock,sameInstance(success));
    assertThat(self.client.successBlock,notNilValue());
    assertThat(self.client.failureBlock,sameInstance(failure));
    assertThat(self.client.failureBlock,notNilValue());
}

#pragma mark - Tests setup

- (void)setUp
{
    [super setUp];
    _methodToExchange = class_getClassMethod([CookieManager class], @selector(sharedManager));
    _originalIMP = method_setImplementation(_methodToExchange, (IMP)mockedCookieManager);
    cookieManager = mock([CookieManager class]);
    self.operationManager = mock([AFHTTPRequestOperationManager class]);
    self.client = [[OperationsClient alloc] init];
    self.client.operationManager = self.operationManager;
}

- (void)tearDown
{
    self.client = nil;
    self.operationManager = nil;
    cookieManager = nil;
    method_setImplementation(_methodToExchange, _originalIMP);
    _originalIMP = nil;
    _methodToExchange = nil;
    [super tearDown];
}

#pragma mark - Tests

- (void)test_shouldReturnActionWithAccessToken_whenAccessTokenIsPresentInCookieManager
{
    NSString *action = @"action";
    NSString *expectedFormedAction = [NSString stringWithFormat:@"%@%@&secure_token=%@",GET_ACTION_BASE,action,TEST_TOKEN];
    [given([cookieManager secureTokenForServer:anything()]) willReturn:TEST_TOKEN];
    
    NSString* formedAction = [self.client actionWithTokenIfNeeded:@"action"];
    
    assertThat(formedAction,equalTo(expectedFormedAction));
}

- (void)test_shouldReturnActionWithoutAccessToken_whenAccessTokenNotPresentInCookieManager
{
    NSString *action = @"action";
    NSString *expectedFormedAction = [NSString stringWithFormat:@"%@%@",GET_ACTION_BASE,action];
    
    NSString* formedAction = [self.client actionWithTokenIfNeeded:@"action"];
    
    assertThat(formedAction,equalTo(expectedFormedAction));
}

-(void)test_shouldFailureWithUnableToLoginError_whenResponseFromAFNetworkingIsNotAuthorizedResponse
{
    NotAuthorizedResponse *response = [[NotAuthorizedResponse alloc] init];
    BlocksCallResult *expectedResult = [BlocksCallResult failureWithError:[NSError errorWithDomain:PydioErrorDomain code:PydioErrorUnableToLogin userInfo:nil]];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    
    self.client.successResponseBlock(nil,response);
    
    assertThat(result,equalTo(expectedResult));
    [self assertClientCleanStateAfterBlockCall];
}

-(void)test_shouldFailureWithPydioErrorResponse_whenResponseFromAFNetworkingIsXMLErrorResponse
{
    NSString *errorMessage = @"Error message";
    PydioErrorResponse *response = [PydioErrorResponse errorResponseWithString:errorMessage];
    BlocksCallResult *expectedResult = [BlocksCallResult failureWithError:
                                        [NSError errorWithDomain:PydioErrorDomain code:PydioErrorErrorResponse userInfo:@{NSLocalizedFailureReasonErrorKey: errorMessage}]
                                        ];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    
    self.client.successResponseBlock(nil,response);
    
    assertThat(result,equalTo(expectedResult));
    [self assertClientCleanStateAfterBlockCall];
}

-(void)test_shouldSuccessWithCorrectResponse_whenResponseFromAFNetworkingIsExtractedObject
{
    NSObject *response = [[NSObject alloc] init];
    BlocksCallResult *expectedResult = [BlocksCallResult successWithResponse:response];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    
    self.client.successResponseBlock(nil,response);
    
    assertThat(result,equalTo(expectedResult));
    [self assertClientCleanStateAfterBlockCall];
}

-(void)test_shouldFailureWithReceivedError_whenResponseFromAFNetwrokingIsError
{
    NSError *response = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    BlocksCallResult *expectedResult = [BlocksCallResult failureWithError:response];
    BlocksCallResult *result = [BlocksCallResult result];
    [self setupClientForBlockResponse:result];
    
    self.client.failureResponseBlock(nil,response);
    
    assertThat(result,equalTo(expectedResult));
    [self assertClientCleanStateAfterBlockCall];
}

#pragma mark - Test not starting operation when in progress

-(void)test_shouldNotStartListWorkspaces_whenOtherOperationIsInProgress
{
    self.client.progress = YES;
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount([self operationManager], never()) GET:anything() parameters:anything() success:anything() failure:anything()];
}

-(void)test_shouldNotStartListNodes_whenOtherOperationIsInProgress
{
    self.client.progress = YES;
    
    BOOL startResult = [self.client listFiles:@{} WithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount([self operationManager], never()) GET:anything() parameters:anything() success:anything() failure:anything()];
}

-(void)test_shouldNotStartMkdir_whenOtherOperationIsInProgress
{
    self.client.progress = YES;
    
    BOOL startResult = [self.client mkdir:@{} WithSuccess:nil failure:nil];
    
    assertThatBool(startResult,equalToBool(NO));
    [verifyCount([self operationManager], never()) POST:anything() parameters:anything() success:anything() failure:anything()];
}

#pragma mark - Test starting when operations client is not in progress

-(void)test_shouldStartListWorkspaces_whenNoOperationIsInProgress
{
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client listWorkspacesWithSuccess:successBlock failure:failureBlock];
    
    assertThatBool(startResult,equalToBool(YES));
    [verify([self operationManager]) GET:[self workspacesURL] parameters:nil success:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertOperationManagerHasDefaultRequestSerializerSet];
    [self assertDefaultResponseSerializerWithClass:[WorkspacesResponseSerializerDelegate class]];
    [self assertClientBlocksSuccess:successBlock AndFailure:failureBlock];
}

-(void)test_shouldStartListNodes_whenNoOperationIsInProgress
{
    NSDictionary *params = @{};
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client listFiles:params WithSuccess:successBlock failure:failureBlock];
    
    assertThatBool(startResult,equalToBool(YES));
    [verify([self operationManager]) GET:[self listFilesURL] parameters:params success:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertOperationManagerHasDefaultRequestSerializerSet];
    [self assertDefaultResponseSerializerWithClass:[ListFilesResponseSerializerDelegate class]];
    [self assertClientBlocksSuccess:successBlock AndFailure:failureBlock];
}

-(void)test_shouldStartMkdir_whenNoOperationIsInProgress
{
    NSDictionary *params = @{};
    BlocksCallResult *result = [BlocksCallResult result];
    SuccessBlock successBlock = [result successBlock];
    FailureBlock failureBlock = [result failureBlock];
    
    BOOL startResult = [self.client mkdir:params WithSuccess:successBlock failure:failureBlock];
    
    assertThatBool(startResult,equalToBool(YES));
    [verify([self operationManager]) POST:@"" parameters:params success:self.client.successResponseBlock failure:self.client.failureResponseBlock];
    [self assertOperationManagerHasDefaultRequestSerializerSet];
    [self assertDefaultResponseSerializerWithClass:[MkdirResponseSerializerDelegate class]];
    [self assertClientBlocksSuccess:successBlock AndFailure:failureBlock];
}

@end
