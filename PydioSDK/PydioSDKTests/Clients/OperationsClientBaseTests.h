//
//  OperationsClientBaseTests.h
//  PydioSDK
//
//  Created by ME on 30/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "OperationsClient.h"


@class AFHTTPRequestOperationManager;
@class AFHTTPRequestOperation;
@class OperationsClient;
@class CookieManager;
@protocol XMLResponseSerializerDelegate;
@class AFCompoundResponseSerializer;


CookieManager* getCookieManager();
id mockedCookieManager(id self, SEL _cmd);

typedef void (^SuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^FailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

static const NSString * const SECURE_TOKEN_PART = @"&secure_token=";
static const NSString * const TEST_TOKEN = @"j9tJRcVJYjKyfphibjRX47YgyVN1eoIv";
static NSString * const TEST_SERVER = @"http://www.testserver.com";

@interface OperationsClientBaseTests : XCTestCase {
    Method _methodToExchange;
    IMP _originalIMP;
}
@property (nonatomic,strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic,strong) OperationsClient *client;
@property (nonatomic, strong) NSDictionary *defaultRequestParams;

-(id<XMLResponseSerializerDelegate>)xmlResponseSerializerFrom:(AFCompoundResponseSerializer*)compound AtIndex:(NSUInteger)index;
@end

@interface OperationsClient ()
@property (readwrite,nonatomic,assign) BOOL progress;
@end