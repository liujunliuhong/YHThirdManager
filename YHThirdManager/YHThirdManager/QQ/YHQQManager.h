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
#import "TencentOAuth+YHQQDescription.h"


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

@interface YHQQUserInfo : NSObject
// 昵称
@property (nonatomic, copy, nullable) NSString *nickName;
// 性别  0:未知   1:男  2:女
@property (nonatomic, assign) int sex;
// 省份
@property (nonatomic, copy, nullable) NSString *province;
// 城市
@property (nonatomic, copy, nullable) NSString *city;
// 头像
@property (nonatomic, copy, nullable) NSString *headImgURL;
// 原始数据(如果以上信息不能满足开发要求，则可以用此属性)
@property (nonatomic, strong, nullable) NSDictionary *originInfo;

@end


/**
 * QQ登录、分享功能的封装(文档:http://wiki.connect.qq.com/)
 * 不包含QQ支付功能，QQ支付和分享是不同的SDK
 * 吐槽一下QQ的SDK：在sdkdef.h文件里，定义了log等级，但是并没有提供关闭日志的方法，导致每次QQ登录的时候，控制台一堆的log
 */
@interface YHQQManager : NSObject


// 授权成功后的信息保存在此对象里面.
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
 handleOpenURL
 
 @param URL URL
 */
- (void)handleOpenURL:(NSURL *)URL;



/**
 QQ授权

 @param showHUD 是否显示hUD
 @param completionBlock 回调(如果isSuccess为YES，代表授权成功，授权信息保存在oauth对象里面)
 */
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;



/**
 QQ登录(需要先授权)

 @param showHUD 是否显示HUD
 @param completionBlock 登录完成回调。如果成功获取到用户信息，result不为nil
 */
- (void)getUserInfoWithShowHUD:(BOOL)showHUD
               completionBlock:(void(^_Nullable)(YHQQUserInfo *_Nullable result))completionBlock;



/**
 QQ网页分享(不需要授权)

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



@end

NS_ASSUME_NONNULL_END
