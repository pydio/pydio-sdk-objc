//
//  BlocksCallResult.m
//  PydioSDK
//
//  Created by ME on 19/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "BlocksCallResult.h"

@implementation BlocksCallResult

+(instancetype)result {
    return [[BlocksCallResult alloc] init];
}

+(instancetype)successWithResponse:(id)response {
    BlocksCallResult *result = [[BlocksCallResult alloc] init];
    result.successBlockCalled = YES;
    result.receivedResponse = response;
    
    return result;
}

+(instancetype)failureWithError:(NSError*)error {
    BlocksCallResult *result = [[BlocksCallResult alloc] init];
    result.failureBlockCalled = YES;
    result.receivedError = error;
    
    return result;
}

-(SuccessBlock)successBlock {
    return ^(id responseObject){
        self.successBlockCalled = YES;
        self.failureBlockCalled = NO;
        self.receivedResponse = responseObject;
        self.receivedError = nil;
    };
}

-(FailureBlock)failureBlock {
    return ^(NSError* error){
        self.successBlockCalled = NO;
        self.failureBlockCalled = YES;
        self.receivedResponse = nil;
        self.receivedError = error;
    };
}

-(BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (![object isKindOfClass:[BlocksCallResult class]]) {
        return NO;
    }
    
    if (self.successBlockCalled != [object successBlockCalled]) {
        return NO;
    }

    if (self.failureBlockCalled != [object failureBlockCalled]) {
        return NO;
    }

    if (self.receivedResponse != [object receivedResponse] && ![self.receivedResponse isEqual:[object receivedResponse]]) {
        return NO;
    }

    if (self.receivedError != [object receivedError] && ![self.receivedError isEqual:[object receivedError]]) {
        return NO;
    }
    
    return YES;
}

-(NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + (self.successBlockCalled)?1231:1237;
    result = prime * result + (self.failureBlockCalled)?1231:1237;
    result = prime * result + [self.receivedResponse hash];
    result = prime * result + [self.receivedError hash];
    
    return result;
}

@end
