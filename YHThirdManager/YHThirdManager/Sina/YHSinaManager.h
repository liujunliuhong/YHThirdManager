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





/**
 * 新浪登录、分享功能的封装（微博SDK是真心的垃圾，Android的都在持续更新，就iOS的不更新，上次更新都是2年前的了。这SDK用着真心累）
 * SDK下载下载地址:https://github.com/sinaweibosdk/weibo_ios_sdk
 * 微博开放平台文档:https://open.weibo.com/wiki/%E9%A6%96%E9%A1%B5
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
- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                            userID:(NSString *)userID
                           showHUD:(BOOL)showHUD
                   completionBlock:(void(^_Nullable)(YHSinaUserInfo *_Nullable result))completionBlock;



/**
 微博分享(目前只支持分享单图，多图分享SDK有问题)

 @param content 分享文本内容
 @param imageData 分享的图片(多图分享有问题。最关键的是，如果用WBImageObject的addImages方法，会把分享的图片保存到相册；还有一点，addImages方法，某些图片分享失败，即sendRequest的返回值是NO)
 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)shareWithContent:(nullable NSString *)content
               imageData:(nullable NSData *)imageData
                 showHUD:(BOOL)showHUD
         completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;




/**
 通过API的方式评论指定微博(需要提前获取accessToken)
 跳转到指定微博    sinaweibo://detail/?dispMeIfNeed=1&mblogid=<MID>
 调起微博直接到指定的个人页面 sinaweibo://userinfo?uid=xxxx
 
 @param accessToken accessToken
 @param ID 微博ID
 @param comment 评论的内容
 @param isCommentOriginWhenTransfer 当评论转发微博时，是否评论给原微博
 @param showHUD 是否显示HUD
 @param completionBlock 回调
 */
- (void)commentWeiBo1WithAccessToken:(NSString *)accessToken
                                  ID:(NSString *)ID
                             comment:(NSString *)comment
         isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                             showHUD:(BOOL)showHUD completionBlock:(void(^_Nullable)(NSDictionary *_Nullable responseObject))completionBlock;




/**
 评论指定微博(通过scheme的方式评论指定微博，可以打开微博的评论面板，评论完成后，不能自动返回APP)
 微博SDK的方法 commentToWeibo: 方法不能往输入框里面添加默认的内容
 
 @param ID 微博ID
 @param comment 评论的内容
 */
- (void)commentWeiBo2WithID:(NSString *)ID
                    comment:(nullable NSString *)comment;





/**
 获取我自己发布的微博(需要提前获取accessToken)

 @param accessToken accessToken
 @param userID userID
 @param perCount 单页返回的条数
 @param curPage 页数（默认1）
 @param showHUD 是否显示HUD
 @param completionBlock 回调的原始数据
 */
- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken
                                 userID:(NSString *)userID
                               perCount:(int)perCount
                                curPage:(int)curPage
                                showHUD:(BOOL)showHUD
                        completionBlock:(void(^_Nullable)(NSDictionary *_Nullable responseObject))completionBlock;


@end

NS_ASSUME_NONNULL_END
