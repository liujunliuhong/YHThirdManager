//
//  TencentOAuth+YHQQDescription.m
//  YHThirdManager
//
//  Created by apple on 2019/5/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "TencentOAuth+YHQQDescription.h"

@implementation TencentOAuth (YHQQDescription)

- (NSString *)description{
    NSDictionary *dic = @{@"accessToken":self.accessToken ? self.accessToken : [NSNull null],
                          @"expirationDate":self.expirationDate ? self.expirationDate : [NSNull null],
                          @"sessionDelegate":self.sessionDelegate,
                          @"localAppId":self.localAppId ? self.localAppId : [NSNull null],
                          @"openId":self.openId ? self.openId : [NSNull null],
                          @"redirectURI":self.redirectURI ? self.redirectURI : [NSNull null],
                          @"appId":self.appId ? self.appId : [NSNull null],
                          @"uin":self.uin ? self.uin : [NSNull null],
                          @"skey":self.skey ? self.skey : [NSNull null],
                          @"passData":self.passData ? self.passData : [NSNull null],
                          @"authMode":@(self.authMode),
                          @"unionid":self.unionid ? self.unionid : [NSNull null],
                          @"authShareType":@(self.authShareType)};
    return [NSString stringWithFormat:@"%@", dic];
}

@end
