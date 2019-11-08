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

- (NSString *)description{
    NSDictionary *dic = @{@"openID":self.openID ? self.openID : [NSNull null],
                          @"accessToken":self.accessToken ? self.accessToken : [NSNull null],
                          @"expiresIn":self.expiresIn ? self.expiresIn : [NSNull null],
                          @"refreshToken":self.refreshToken ? self.refreshToken : [NSNull null],
                          @"scope":self.scope ? self.scope : [NSNull null],
                          @"originAuthInfo":self.originAuthInfo ? self.originAuthInfo : [NSNull null]};
    return [NSString stringWithFormat:@"%@", dic];
}

@end
