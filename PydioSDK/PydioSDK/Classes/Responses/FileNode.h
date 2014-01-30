//
//  File.h
//  PydioSDK
//
//  Created by ME on 02/02/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileNode : NSObject
@property (nonatomic,weak) FileNode* parent;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,assign) BOOL isFile;
@property (nonatomic,strong) NSString* path;
@property (nonatomic,assign) NSInteger size;
@property (nonatomic,strong) NSDate* modificationTime;
@property (nonatomic,strong) NSArray *children;

-(BOOL)isTreeEqual:(FileNode*)node;
-(BOOL)isValuesEqual:(FileNode*)other;
@end
