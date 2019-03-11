//
//  YHWXManager.h
//  QAQSmooth
//
//  Created by apple on 2019/3/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 分享类型
 */
typedef NS_ENUM(NSUInteger, YHWXShareType) {
    YHWXShareType_Session,              // 分享至聊天界面
    YHWXShareType_Timeline,             // 分享至朋友圈
};


NS_ASSUME_NONNULL_BEGIN

@interface YHWXLoginResult : NSObject
// 接口调用凭证
@property (nonatomic, copy) NSString *access_token;
// access_token接口调用凭证超时时间，单位（秒）
@property (nonatomic, copy) NSString *expires_in;
// 用户刷新access_token
@property (nonatomic, copy) NSString *refresh_token;
// 授权用户唯一标识
@property (nonatomic, copy) NSString *openid;
// 用户授权的作用域，使用逗号（,）分隔
@property (nonatomic, copy) NSString *scope;
// 普通用户昵称
@property (nonatomic, copy, nullable) NSString *nickname;
// 普通用户性别    1:男性    2:女性
@property (nonatomic, assign) int sex;
// 普通用户个人资料填写的省份
@property (nonatomic, copy, nullable) NSString *province;
// 普通用户个人资料填写的城市
@property (nonatomic, copy, nullable) NSString *city;
// 国家，如中国为CN
@property (nonatomic, copy, nullable) NSString *country;
// 用户头像，最后一个数值代表正方形头像大小（有0、46、64、96、132数值可选，0代表640*640正方形头像），用户没有头像时该项为空
@property (nonatomic, copy, nullable) NSString *headimgurl;
// 用户统一标识。针对一个微信开放平台帐号下的应用，同一用户的unionid是唯一的。
@property (nonatomic, copy) NSString *unionid;
@end




/**
 * 微信登录、分享、支付封装(包含支付功能，请确保你的项目有用到微信支付，否则请导入无支付功能的模块)
 * 文档1:https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317853&lang=zh_CN
 * 文档2:https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317851&token=&lang=zh_CN
 */
@interface YHWXManager : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


/**
 SDK初始化

 @param appID appID
 @param appSecret appSecret
 */
- (void)initWithAppID:(NSString *)appID
            appSecret:(NSString *)appSecret;

/**
 微信登录
 
 @param viewController 当前viewController
 @param showHUD 是否显示HUD
 @param completionBlock 登录完成后在主线程的回调
 */
- (void)loginWithViewController:(nullable UIViewController *)viewController
                        showHUD:(BOOL)showHUD
                completionBlock:(void(^_Nullable)(YHWXLoginResult *_Nullable result))completionBlock;

/**
 微信分享网页
 注意：
 1、新版本微信SDK分享的时候，即使点击微信分享页面的取消按钮时，也是回调的分享成功。具体请看:https://mp.weixin.qq.com/s?__biz=MjM5NDAwMTA2MA==&mid=2695730124&idx=1&sn=666a448b047d657350de7684798f48d3&chksm=83d74a07b4a0c311569a748f4d11a5ebcce3ba8f6bd5a4b3183a4fea0b3442634a1c71d3cdd0&scene=21#wechat_redirect
 2、微信SDK要求分享图片大小不得超过64K，否则会导致分享失败并且还TMD没任何提示。而通常开发过程中能获得的仅为一个URL，像素和图片文件大小不得而知，我的解决办法是先对图片进行裁剪，再压缩。
 3、图片下载可以用SD下载
 
 - (UIImage *)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];//根据newSize对图片进行裁剪
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImage imageWithData:UIImageJPEGRepresentation(newImage, 0.5)];//压缩50%
 }
 
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
- (void)payWithPartnerID:(NSString *)partnerID
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
- (void)payWithPartnerID:(NSString *)partnerID
                prepayID:(NSString *)prepayID
                    sign:(NSString *)sign
                nonceStr:(NSString *)nonceStr
               timeStamp:(NSString *)timeStamp
                 showHUD:(BOOL)showHUD
          comletionBlock:(void (^)(BOOL isSuccess))completionBlock;

/**
 openURL

 @param URL URL
 */
- (void)handleOpenURL:(NSURL *)URL;


@end

NS_ASSUME_NONNULL_END
