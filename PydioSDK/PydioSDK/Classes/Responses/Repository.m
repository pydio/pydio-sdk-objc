//
//  Repository.m
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "Repository.h"

@implementation Repository

-(instancetype)initWithId:(NSString*)repoId AndLabel:(NSString *)label AndDescription:(NSString*)description {
    self = [super init];
    if (self) {
        _repoId = repoId;
        _label = label;
        _description = description;
    }
    
    return self;
}

@end