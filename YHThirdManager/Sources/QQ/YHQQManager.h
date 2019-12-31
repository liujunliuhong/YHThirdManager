//
//  YHQQManager.h
//  QAQSmooth
//
//  Created by apple on 2019/3/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<TencentOpenAPI/TencentOAuth.h>) && __has_include(<TencentOpenAPI/QQApiInterface.h>)
    #import <TencentOpenAPI/TencentOAuth.h>
    #import <TencentOpenAPI/QQApiInterface.h>
#endif

#import "YHQQUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

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


/**
 * SDK版本：3.3.7
 * QQ登录、分享功能的封装(文档:http://wiki.connect.qq.com/)
 * 不包含QQ支付功能，QQ支付和分享是不同的SDK
 * 吐槽一下QQ的SDK：在sdkdef.h文件里，定义了log等级，但是并没有提供关闭日志的方法，导致每次QQ登录的时候，控制台一堆的log
 */
@class MBProgressHUD;
@interface YHQQManager : NSObject
#if __has_include(<TencentOpenAPI/TencentOAuth.h>) && __has_include(<TencentOpenAPI/QQApiInterface.h>)
/// 初始化SDK的appID
@property (nonatomic, copy, readonly) NSString *appID;
/// 授权成功后的信息保存在此对象里面，需要什么信息自己去拿
@property (nonatomic, strong, readonly, nullable) TencentOAuth *oauth;
/// QQ登录获取的个人信息
@property (nonatomic, strong, readonly, nullable) YHQQUserInfo *userInfo;
#endif

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#if __has_include(<TencentOpenAPI/TencentOAuth.h>) && __has_include(<TencentOpenAPI/QQApiInterface.h>)
#pragma mark Init
/// QQ SDK初始化
/// @param appID appID
/// @param universalLink 可以为空，根据目前QQ SDK里面提供的初始化方法，universalLink是可选的
- (void)initWithAppID:(NSString *)appID
        universalLink:(nullable NSString *)universalLink;

/// handleOpenURL
/// @param URL URL
- (void)handleOpenURL:(NSURL *)URL;

/// handleUniversalLink
/// @param universalLink universalLink
- (void)handleUniversalLink:(NSURL *)universalLink;

#pragma mark Auth
/// QQ授权
/// @param showHUD 是否显示hUD
/// @param completionBlock  回调(如果isSuccess为YES，代表授权成功，授权信息保存在oauth对象里面)
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

#pragma mark Get User Info
/// QQ获取用户信息
/// @param accessToken accessToken(可通过oauth获得)
/// @param appID appID(可通过oauth获得)
/// @param openId openId(可通过oauth获得)
/// @param showHUD 是否显示HUD
/// @param completionBlock 登录完成回调(信息保存在userInfo里面)
- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                             appID:(NSString *)appID
                            openId:(NSString *)openId
                         isShowHUD:(BOOL)showHUD
                   completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

#pragma mark Share
/// 网页分享(缩略图为URL)
/// @param URL URL
/// @param title 标题
/// @param description 描述
/// @param thumbImageURL 分享的缩略图片链接
/// @param shareTye 分享类型
/// @param shareDestType 分享到哪儿
/// @param showHUD 是否显示HUD
/// @param completionBlock 分享完成回调（是否分享成功）
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
          thumbImageURL:(nullable NSString *)thumbImageURL
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

/// 网页分享(缩略图为NSData)
/// @param URL URL
/// @param title 标题
/// @param description 描述
/// @param thumbImageData 分享的缩略图片NSData(根据QQ SDK，预览图像最大为1M)
/// @param shareTye 分享类型
/// @param shareDestType 分享到哪儿
/// @param showHUD 是否显示HUD
/// @param completionBlock 分享完成回调（是否分享成功）
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
         thumbImageData:(nullable NSData *)thumbImageData
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

/// 图片分享(根据QQ SDK，只能分享到QQ好友)
/// @param data 图片数据(根据QQ SDK，预览图像最大为5M)
/// @param thumbImageData 缩略图片NSData(根据QQ SDK，预览图像最大为1M)
/// @param title 标题
/// @param description 描述
/// @param shareDestType 分享到哪儿
/// @param showHUD 是否显示HUD
/// @param completionBlock 分享完成回调（是否分享成功）
- (void)shareImageWithData:(NSData *)data
            thumbImageData:(nullable NSData *)thumbImageData
                     title:(nullable NSString *)title
               description:(nullable NSString *)description
             shareDestType:(YHQQShareDestType)shareDestType
                   showHUD:(BOOL)showHUD
           completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;
#endif
@end




@interface YHQQManager (Private)
- (void)_addObserve;
- (void)_removeObserve;
- (MBProgressHUD *)getHUD;
- (void)_hideHUD:(MBProgressHUD *)hud;
@end
NS_ASSUME_NONNULL_END
