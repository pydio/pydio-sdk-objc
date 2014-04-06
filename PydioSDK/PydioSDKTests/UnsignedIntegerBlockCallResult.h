//
//  UnsignedIntegerBlockCallResult.h
//  PydioSDK
//
//  Created by Michal Kloczko on 06/04/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnsignedIntegerBlockCallResult : NSObject
@property(nonatomic,assign) BOOL blockCalled;
@property(nonatomic,assign) NSUInteger argument;

+(UnsignedIntegerBlockCallResult*)blockCalledWith:(NSUInteger)argument;
-(void(^)(NSUInteger argument))block;
@end
