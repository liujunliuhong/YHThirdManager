//
//  YHQQManager.h
//  QAQSmooth
//
//  Created by apple on 2019/3/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>

// 分享类型
typedef NS_ENUM(NSUInteger, YHQQShareType) {
    YHQQShareType_QQ,            // 分享到QQ
    YHQQShareType_QZone,         // 分享到QQ空间
};

// 分享到哪儿
typedef NS_ENUM(NSUInteger, YHQQShareDestType) {
    YHQQShareDestType_QQ,        // 分享到QQ
    YHQQShareDestType_TIM,       // 分享到TIM
};

NS_ASSUME_NONNULL_BEGIN


@interface YHQQLoginResult : NSObject
// Access Token凭证，用于后续访问各开放接口
@property (nonatomic, copy) NSString *access_token;
// 用户授权登录后对该用户的唯一标识
@property (nonatomic, copy) NSString *openid;
// Access Token的失效期
@property (nonatomic, copy) NSString *expires_in;
// 昵称
@property (nonatomic, copy, nullable) NSString *nickname;
// 性别   1:男  2:女
@property (nonatomic, assign) int sex;
// 省份
@property (nonatomic, copy, nullable) NSString *province;
// 城市
@property (nonatomic, copy, nullable) NSString *city;
// 头像
@property (nonatomic, copy, nullable) NSString *headimgurl;
// unionid
// 如果开发者拥有多个移动应用、网站应用，可通过获取用户的unionid来区分用户的唯一性，因为只要是同 一个QQ互联平台帐号下的移动应用、网站应用，用户的unionid是唯一的。换句话说，同一用户，对 同一个QQ互联平台下的不同应用，unionid是相同的
@property (nonatomic, copy) NSString *unionid;

@end


/**
 * QQ登录、分享功能的封装(文档:http://wiki.connect.qq.com/)
 * 不包含QQ支付功能，QQ支付和分享是不同的SDK
 * 吐槽一下QQ的SDK：在sdkdef.h文件里，定义了log等级，但是并没有提供关闭日志的方法，导致每次QQ登录的时候，控制台一堆的log
 */
@interface YHQQManager : NSObject


@property (nonatomic, strong, readonly) TencentOAuth *oauth;


+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 QQ SDK初始化

 @param appID appID
 */
- (void)initWithAppID:(NSString *)appID;


/**
 QQ登录

 @param showHUD 是否显示HUD
 @param completionBlock 登录完成回调。如果成功获取到用户信息，result不为nil
 */
- (void)loginWithShowHUD:(BOOL)showHUD
         completionBlock:(void(^_Nullable)(YHQQLoginResult *_Nullable result))completionBlock;


- (void)authWithShowHUD:(BOOL)showHUD completionBlock:(void(^_Nullable)(void))completionBlock;


/**
 QQ网页分享

 @param URL 分享链接
 @param title 分享标题
 @param description 分享描述
 @param thumbImageURL 分享的缩略图链接
 @param shareTye 分享类型
 @param shareDestType 分享到哪儿
 @param showHUD 是否显示HUD
 @param completionBlock 分享完成回调
 */
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
          thumbImageURL:(NSString *)thumbImageURL
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


/**
 handleOpenURL

 @param URL URL
 */
- (void)handleOpenURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
