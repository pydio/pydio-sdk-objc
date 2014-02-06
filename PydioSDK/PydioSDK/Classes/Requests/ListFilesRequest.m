//
//  ListFilesRequest.m
//  PydioSDK
//
//  Created by ME on 06/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "ListFilesRequest.h"

@implementation ListFilesRequest

-(NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *params = [NSMutableDictionary
                                   dictionaryWithDictionary:@{
                                                              @"tmp_repository_id": self.workspaceId,
                                                              @"dir" : self.path,
                                                              @"options" : @"al"
                                                             }];

    for (NSString *key in [self.additional allKeys]) {
        [params setValue:[self.additional valueForKey:key] forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:params];
}

@end
