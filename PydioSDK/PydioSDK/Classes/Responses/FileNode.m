//
//  File.m
//  PydioSDK
//
//  Created by ME on 02/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "FileNode.h"

@implementation FileNode

-(BOOL)isTreeEqual:(FileNode*)other {
    BOOL result = [self isValuesEqual:other];
    result = self.children.count == other.children.count;
    
    NSUInteger i = 0;
    while (result && i < self.children.count) {
        FileNode *myChild = [self.children objectAtIndex:i];
        FileNode *otherChild = [other.children objectAtIndex:i];
        
        result = [myChild isTreeEqual:otherChild];
        ++i;
    }
    
    return result;
}

-(BOOL)isValuesEqual:(FileNode*)other {
    if (self == other) {
        return YES;
    }

    if (self.name != other.name && ![self.name isEqualToString:other.name]) {
        return NO;
    }
    
    if (self.isFile != other.isFile) {
        return NO;
    }
    
    if (self.path != other.path && ![self.path isEqualToString:other.path]) {
        return NO;
    }
    
    if (self.size != other.size) {
        return NO;
    }
    
    if (self.modificationTime != other.modificationTime && ![self.modificationTime isEqual:other.modificationTime]) {
        return NO;
    }

    return YES;
}

@end
