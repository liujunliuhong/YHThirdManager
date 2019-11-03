//
//  YHQQUserInfo.m
//  YHThirdManager
//
//  Created by 银河 on 2019/11/3.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHQQUserInfo.h"

@implementation YHQQUserInfo
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nickName = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.headImgURL = @"";
        self.originInfo = nil;
    }
    return self;
}

@end
