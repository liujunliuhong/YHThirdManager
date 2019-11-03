//
//  YHSinaUserInfo.h
//  YHThirdManager
//
//  Created by 银河 on 2019/11/3.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YHSinaUserInfo : NSObject
// 昵称
@property (nonatomic, copy) NSString *nickName;
// 性别  0:未知  1:男  2:女
@property (nonatomic, assign) int sex;
// 省份    用户所在省级ID
@property (nonatomic, copy) NSString *province;
// 城市    用户所在城市ID
@property (nonatomic, copy) NSString *city;
// 头像
@property (nonatomic, copy) NSString *headImgURL;
// 原始数据(如果以上信息不能满足开发要求，则可以用此属性)
@property (nonatomic, strong, nullable) NSDictionary *originInfo;
@end

NS_ASSUME_NONNULL_END
