//
//  UnsignedIntegerBlockCallResult.m
//  PydioSDK
//
//  Created by Michal Kloczko on 06/04/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "UnsignedIntegerBlockCallResult.h"

@implementation UnsignedIntegerBlockCallResult

+(UnsignedIntegerBlockCallResult*)blockCalledWith:(NSUInteger)argument {
    UnsignedIntegerBlockCallResult *blockCallResult = [[UnsignedIntegerBlockCallResult alloc] init];
    blockCallResult.blockCalled = YES;
    blockCallResult.argument = argument;
    
    return blockCallResult;
}

-(void(^)(NSUInteger argument))block {
    return ^(NSUInteger argument) {
        self.blockCalled = YES;
        self.argument = argument;
    };
}

-(BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (![object isKindOfClass:[UnsignedIntegerBlockCallResult class]]) {
        return NO;
    }
        
    return self.blockCalled == [object blockCalled] && self.argument == [object argument];
}

-(NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + (self.blockCalled)?1231:1237;
    result = prime * result + (self.argument);
    
    return result;
}

@end
