//
//  YHWXAuthResult.h
//  YHThirdManager
//
//  Created by apple on 2019/11/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 获取AccessToken之后相关信息的包装
@interface YHWXAuthResult : NSObject
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *openID;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *expiresIn;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, copy) NSString *scope;
// 原始数据(如果以上信息不能满足开发要求，则可以用此属性)
@property (nonatomic, strong, nullable) NSDictionary *originAuthInfo;
@end

NS_ASSUME_NONNULL_END
