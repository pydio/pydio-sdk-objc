//
//  PydioErrors.h
//  PydioSDK
//
//  Created by ME on 15/01/14.
//  Copyright (c) 2014 MINI. All rights reserved.
//

#ifndef PydioSDK_PydioErrors_h
#define PydioSDK_PydioErrors_h

extern NSString * const PydioErrorDomain;

enum {
    PydioErrorUnableToParseAnswer = 1,
    PydioErrorUnableToLogin = 2, //TODO: Rename to Authorization error
    PydioErrorReceivedNotExpectedAnswer    
};

#endif
