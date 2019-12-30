//
//  YHWXManager.h
//  QAQSmooth
//
//  Created by apple on 2019/3/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#if __has_include(<WechatOpenSDK/WXApi.h>)
    #import <WechatOpenSDK/WXApi.h>
#elif __has_include("WXApi.h")
    #import "WXApi.h"
#endif
#import "YHWXAuthResult.h"
#import "YHWXUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 分享类型
 */
typedef NS_ENUM(NSUInteger, YHWXShareType) {
    YHWXShareType_Session,              // 分享至聊天界面
    YHWXShareType_Timeline,             // 分享至朋友圈
};



/**
 * SDK版本:1.8.6.1
 * 微信登录、分享、支付封装(包含支付功能，请确保你的项目有用到微信支付，否则请导入无支付功能的模块)
 * 文档1:https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317853&lang=zh_CN
 */
@class MBProgressHUD;
@interface YHWXManager : NSObject
/// 初始化SDK的appID
@property (nonatomic, copy, nullable, readonly) NSString *appID;
/// 初始化SDK的appSecret
@property (nonatomic, copy, nullable, readonly) NSString *appSecret;
/// 授权获取的code
@property (nonatomic, copy, nullable, readonly) NSString *code;
/// 授权信息
@property (nonatomic, strong, nullable, readonly) YHWXAuthResult *authResult;
/// 用户信息
@property (nonatomic, strong, nullable, readonly) YHWXUserInfo *userInfo;


+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


#pragma mark Init
/// SDK初始化
/// @param appID appID
/// @param appSecret appSecret(当只需要获取code时，appSecret可以为空)
/// @param universalLink Universal Link(根据最新微信SDK，需要`Universal Link`参数)
- (void)initWithAppID:(NSString *)appID
            appSecret:(nullable NSString *)appSecret
        universalLink:(NSString *)universalLink;

/// 处理微信通过URL启动App时传递的数据
/// @param URL URL
- (void)handleOpenURL:(NSURL *)URL;

/// 处理微信通过`Universal Link`启动App时传递的数据
/// @param userActivity 微信启动第三方应用时系统API传递过来的userActivity
- (void)handleOpenUniversalLink:(NSUserActivity *)userActivity;


#pragma mark Auth
/// 获取code（获取code调用的是SDK里面的方法）
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调(是否获取成功，code保存在属性`code`里面)
- (void)authForGetCodeWithShowHUD:(BOOL)showHUD
                  completionBlock:(void(^_Nullable)(BOOL isGetCodeSuccess))completionBlock;

/// 通过code获取AccessToken（获取AccessToken其实是个普通的网络请求）
/// @param appID appID
/// @param appSecret appSecret
/// @param code code
/// @param completionBlock 回调(是否获取成功，授权信息保存在`authResult`里面)
- (void)authForGetAccessTokenWithAppID:(NSString *)appID
                             appSecret:(NSString *)appSecret
                                  code:(NSString *)code
                               showHUD:(BOOL)showHUD
                       completionBlock:(void(^_Nullable)(BOOL isGetAccessTokenSuccess))completionBlock;


#pragma mark Get User Info
/// 获取用户信息（本质上是一个普通的网络请求）
/// @param openID 授权成功后获取到的openID
/// @param accessToken 授权成功后获取到的accessToken
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调（如果获取成功，那么用户信息保存在`userInfo`里面）
- (void)getUserInfoWithOpenID:(NSString *)openID
                  accessToken:(NSString *)accessToken
                      showHUD:(BOOL)showHUD
              completionBlock:(void(^_Nullable)(BOOL isGetUserInfoSuccess))completionBlock;

#pragma mark Share
/**
 微信分享网页
 注意：
 新版本微信SDK分享的时候，即使点击微信分享页面的取消按钮时，也是回调的分享成功。具体请看:https://mp.weixin.qq.com/s?__biz=MjM5NDAwMTA2MA==&mid=2695730124&idx=1&sn=666a448b047d657350de7684798f48d3&chksm=83d74a07b4a0c311569a748f4d11a5ebcce3ba8f6bd5a4b3183a4fea0b3442634a1c71d3cdd0&scene=21#wechat_redirect
 
 @param URL 链接
 @param title 标题
 @param description 描述
 @param thumbImage 缩略图
 @param shareType 分享类型（目前只能分享到朋友圈和聊天界面）
 @param showHUD 是否显示HUD
 @param completionBlock 分享完成后在主线程的回调
 */
- (void)shareWebWithURL:(NSString *)URL
                  title:(nullable NSString *)title
            description:(nullable NSString *)description
             thumbImage:(nullable UIImage *)thumbImage
              shareType:(YHWXShareType)shareType
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;
@end



@interface YHWXManager (Private)
@property (nonatomic, assign) BOOL sdkFlag;
- (MBProgressHUD *)getHUD;
- (void)_hideHUD:(MBProgressHUD *)hud;
- (void)_removeObserve;
- (void)_addObserve;
@end


NS_ASSUME_NONNULL_END
