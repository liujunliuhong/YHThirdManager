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

NS_ASSUME_NONNULL_BEGIN

/**
 * 分享类型
 */
typedef NS_ENUM(NSUInteger, YHWXShareType) {
    YHWXShareType_Session,              // 分享至聊天界面
    YHWXShareType_Timeline,             // 分享至朋友圈
};


@interface YHWXUserInfoResult : NSObject
// 普通用户昵称
@property (nonatomic, copy, nullable) NSString *nickName;
// 普通用户性别  0:未知  1:男性    2:女性
@property (nonatomic, assign) int sex;
// 普通用户个人资料填写的省份
@property (nonatomic, copy, nullable) NSString *province;
// 普通用户个人资料填写的城市
@property (nonatomic, copy, nullable) NSString *city;
// 国家，如中国为CN
@property (nonatomic, copy, nullable) NSString *country;
// 用户头像，最后一个数值代表正方形头像大小（有0、46、64、96、132数值可选，0代表640*640正方形头像），用户没有头像时该项为空
@property (nonatomic, copy, nullable) NSString *headImgURL;
// 用户统一标识。针对一个微信开放平台帐号下的应用，同一用户的unionid是唯一的。
@property (nonatomic, copy) NSString *unionID;
// 原始数据(如果以上信息不能满足开发要求，则可以用此属性)
@property (nonatomic, strong, nullable) NSDictionary *originUserInfo;
@end



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


/**
 * 微信登录、分享、支付封装(包含支付功能，请确保你的项目有用到微信支付，否则请导入无支付功能的模块)
 * 文档1:https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317853&lang=zh_CN
 * 文档2:https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317851&token=&lang=zh_CN
 * 集成方式有pod和手动导入，pod集成的是包含支付功能的，如果你的项目不包含支付功能，请用手动的方式集成    pod 'WechatOpenSDK'
 */
@interface YHWXManager : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


/**
 SDK初始化

 @param appID appID
 @param appSecret appSecret(当只需要获取code时，appSecret可以为空)
 */
- (void)initWithAppID:(NSString *)appID
            appSecret:(nullable NSString *)appSecret;


/**
 openURL
 
 @param URL URL
 */
- (void)handleOpenURL:(NSURL *)URL;


/**
 微信授权(把获取code和获取accessToken结合在了一起)

 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(YHWXAuthResult *_Nullable authResult))completionBlock;

/**
 获取code
 
 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)authForGetCodeWithShowHUD:(BOOL)showHUD
                  completionBlock:(void(^_Nullable)(NSString *_Nullable code))completionBlock;

/**
 获取用户信息(需要先授权)

 @param openID 授权成功后获取到的openID
 @param accessToken 授权成功后获取到的accessToken
 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)getUserInfoWithOpenID:(NSString *)openID
                  accessToken:(NSString *)accessToken
                      showHUD:(BOOL)showHUD
              completionBlock:(void(^_Nullable)(YHWXUserInfoResult *_Nullable userInfoResult))completionBlock;

/**
 微信分享网页
 注意：
 1、新版本微信SDK分享的时候，即使点击微信分享页面的取消按钮时，也是回调的分享成功。具体请看:https://mp.weixin.qq.com/s?__biz=MjM5NDAwMTA2MA==&mid=2695730124&idx=1&sn=666a448b047d657350de7684798f48d3&chksm=83d74a07b4a0c311569a748f4d11a5ebcce3ba8f6bd5a4b3183a4fea0b3442634a1c71d3cdd0&scene=21#wechat_redirect
 
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


/**
 微信支付方式一：服务端只需要提供prepayID，其余的secretKey、partnerID、appID在APP里面写死（客户端做签名，不安全）
 
 @param partnerID 商户ID
 @param secretKey 商户秘钥（不是appSecret）
 @param prepayID 预支付ID
 @param showHUD 是否显示HUD
 @param completionBlock 支付完成后在主线程的回调
 */
- (void)pay1WithPartnerID:(NSString *)partnerID
               secretKey:(NSString *)secretKey
                prepayID:(NSString *)prepayID
                 showHUD:(BOOL)showHUD
          comletionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


/**
 微信支付方式二：支付参数全从服务端获取

 @param partnerID 商户ID
 @param prepayID 预支付ID
 @param sign 签名
 @param nonceStr 随机字符串
 @param timeStamp 时间戳
 @param showHUD 是否显示HUD
 @param completionBlock 支付完成后在主线程的回调
 */
- (void)pay2WithPartnerID:(NSString *)partnerID
                prepayID:(NSString *)prepayID
                    sign:(NSString *)sign
                nonceStr:(NSString *)nonceStr
               timeStamp:(NSString *)timeStamp
                 showHUD:(BOOL)showHUD
          comletionBlock:(void (^)(BOOL isSuccess))completionBlock;




@end

NS_ASSUME_NONNULL_END
