//
//  YHSinaManager.h
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Weibo_SDK/WeiboSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface YHSinaLoginResult : NSObject
// userID
@property (nonatomic, copy) NSString *userID;
// 昵称
@property (nonatomic, copy) NSString *nickName;
// 性别  0:未知  1:男  2:女
@property (nonatomic, assign) int sex;
// 省份    用户所在省级ID
@property (nonatomic, copy) NSString *province;
// 城市    用户所在城市ID
@property (nonatomic, copy) NSString *city;
// 头像
@property (nonatomic, copy) NSString *headimgURL;
@end





/**
 * 新浪登录、分享功能的封装
 * SDK下载下载地址:https://github.com/sinaweibosdk/weibo_ios_sdk
 */
@interface YHSinaManager : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


/**
 handleOpenURL

 @param URL URL
 */
- (void)handleOpenURL:(NSURL *)URL;


/**
 微博 SDK初始化

 @param appID appID
 @param redirectURI redirectURI
 */
- (void)initWithAppID:(NSString *)appID
          redirectURI:(NSString *)redirectURI;


/**
 微博授权获取accessToken

 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(WBAuthorizeResponse *_Nullable authResponse))completionBlock;



/**
 获取用户信息(需要提前获取accessToken)

 @param accessToken accessToken
 @param userID userID
 @param showHUD showHUD
 @param completionBlock 回调
 */
- (void)loginWithAccessToken:(NSString *)accessToken
                      userID:(NSString *)userID
                     showHUD:(BOOL)showHUD
             completionBlock:(void(^_Nullable)(YHSinaLoginResult *_Nullable result))completionBlock;



/**
 微博分享(需要提前获取accessToken)

 @param accessToken accessToken
 @param content 文本内容
 @param images 图片数组
 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)shareWithAccessToken:(NSString *)accessToken
                     content:(nullable NSString *)content
                      images:(nullable NSArray<UIImage *> *)images
                     showHUD:(BOOL)showHUD
             completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


- (void)commentWeiBoWithAccessToken:(NSString *)accessToken
                                 ID:(NSString *)ID
                            comment:(NSString *)comment
        isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                            showHUD:(BOOL)showHUD completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken
                                 userID:(NSString *)userID
                               perCount:(int)perCount
                                curPage:(int)curPage
                                showHUD:(BOOL)showHUD
                        completionBlock:(void(^_Nullable)(NSDictionary *_Nullable responseObject))completionBlock;


@end

NS_ASSUME_NONNULL_END
