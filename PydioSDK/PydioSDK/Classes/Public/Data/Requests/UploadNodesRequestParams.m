//
//  UploadNodesRequestParams.m
//  PydioSDK
//
//  Created by Michal Kloczko on 11/05/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import "UploadNodesRequestParams.h"

@implementation UploadNodesRequestParams

-(NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:self.workspaceId forKey:@"tmp_repository_id"];
    [params setValue:self.node forKey:@"node"];
    [params setValue:self.fileName forKey:@"urlencoded_filename"];
    [params setValue:self.data forKey:self.fileName];
    
    for (NSString *key in [self.additional allKeys]) {
        [params setValue:[self.additional valueForKey:key] forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:params];
}

@end
