//
//  WBAuthorizeResponse+YHSinaDescription.m
//  YHThirdManager
//
//  Created by apple on 2019/5/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "WBAuthorizeResponse+YHSinaDescription.h"

@implementation WBAuthorizeResponse (YHSinaDescription)

- (NSString *)description{
    NSDictionary *dic = @{@"userID":self.userID ? self.userID : [NSNull null],
                          @"accessToken":self.accessToken ? self.accessToken : [NSNull null],
                          @"expirationDate":self.expirationDate ? self.expirationDate : [NSNull null],
                          @"refreshToken":self.refreshToken ? self.refreshToken : [NSNull null],
                          @"requestUserInfo":self.requestUserInfo ? self.requestUserInfo : [NSNull null],
                          @"statusCode":@(self.statusCode),
                          @"userInfo":self.userInfo ? self.userInfo : [NSNull null],
                          @"sdkVersion":self.sdkVersion ? self.sdkVersion : [NSNull null],
                          @"shouldOpenWeiboAppInstallPageIfNotInstalled":@(self.shouldOpenWeiboAppInstallPageIfNotInstalled)
                          };
    return [NSString stringWithFormat:@"%@", dic];
}

@end
