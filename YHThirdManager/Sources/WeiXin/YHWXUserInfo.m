//
//  YHWXUserInfo.m
//  YHThirdManager
//
//  Created by apple on 2019/12/30.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXUserInfo.h"

@implementation YHWXUserInfo
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.nickName = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.country = @"";
        self.headImgURL = @"";
        self.unionID = @"";
        self.originInfo = nil;
    }
    return self;
}
@end
