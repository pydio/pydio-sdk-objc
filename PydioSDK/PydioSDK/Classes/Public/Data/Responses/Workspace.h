//
//  Repository.h
//  PydioSDK
//
//  Created by ME on 20/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Workspace : NSObject
@property (readonly,nonatomic,strong) NSString* workspaceId;
@property (readonly,nonatomic,strong) NSString* label;
@property (readonly,nonatomic,strong) NSString* description;

-(instancetype)initWithId:(NSString*)repoId AndLabel:(NSString *)label AndDescription:(NSString*)description;
@end
