//
//  YHWXAuthResult.m
//  YHThirdManager
//
//  Created by apple on 2019/11/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXAuthResult.h"

@implementation YHWXAuthResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.openID = @"";
        self.accessToken = @"";
        self.refreshToken = @"";
        self.scope = @"";
        self.expiresIn = @"";
        self.originAuthInfo = nil;
    }
    return self;
}

@end
