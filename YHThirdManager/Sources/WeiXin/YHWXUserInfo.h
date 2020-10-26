//
//  YHWXUserInfo.h
//  YHThirdManager
//
//  Created by apple on 2019/12/30.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 用户信息的包装
@interface YHWXUserInfo : NSObject
// 普通用户昵称
@property (nonatomic, copy) NSString *nickName;
// 普通用户性别  0:未知  1:男性    2:女性
@property (nonatomic, assign) int sex;
// 普通用户个人资料填写的省份
@property (nonatomic, copy) NSString *province;
// 普通用户个人资料填写的城市
@property (nonatomic, copy) NSString *city;
// 国家，如中国为CN
@property (nonatomic, copy) NSString *country;
// 用户头像，最后一个数值代表正方形头像大小（有0、46、64、96、132数值可选，0代表640*640正方形头像），用户没有头像时该项为空
@property (nonatomic, copy) NSString *headImgURL;
// 用户统一标识。针对一个微信开放平台帐号下的应用，同一用户的unionid是唯一的。
@property (nonatomic, copy) NSString *unionID;
// 原始数据(如果以上信息不能满足开发要求，则可以用此属性)
@property (nonatomic, strong, nullable) NSDictionary *originInfo;
@end

NS_ASSUME_NONNULL_END
