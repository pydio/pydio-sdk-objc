//
//  File.m
//  PydioSDK
//
//  Created by ME on 02/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "Node.h"

@implementation Node

-(BOOL)isTreeEqual:(Node*)other {
    BOOL result = [self isValuesEqual:other];
    result = self.children.count == other.children.count;
    
    NSUInteger i = 0;
    while (result && i < self.children.count) {
        Node *myChild = [self.children objectAtIndex:i];
        Node *otherChild = [other.children objectAtIndex:i];
        
        result = [myChild isTreeEqual:otherChild];
        ++i;
    }
    
    return result;
}

-(BOOL)isValuesEqual:(Node*)other {
    if (self == other) {
        return YES;
    }

    if (self.name != other.name && ![self.name isEqualToString:other.name]) {
        return NO;
    }
    
    if (self.isLeaf != other.isLeaf) {
        return NO;
    }
    
    if (self.path != other.path && ![self.path isEqualToString:other.path]) {
        return NO;
    }
    
    if (self.size != other.size) {
        return NO;
    }
    
    if (self.mTime != other.mTime && ![self.mTime isEqual:other.mTime]) {
        return NO;
    }

    return YES;
}

@end
