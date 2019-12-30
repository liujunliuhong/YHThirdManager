//
//  YHSinaManager.h
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#if __has_include(<Weibo_SDK/WeiboSDK.h>)
    #import <Weibo_SDK/WeiboSDK.h>
#endif
#import "YHSinaUserInfo.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * SDK版本：3.2.5.1
 * 新浪登录、分享功能的封装
 * SDK下载下载地址:https://github.com/sinaweibosdk/weibo_ios_sdk
 * 微博开放平台文档:https://open.weibo.com/wiki/%E9%A6%96%E9%A1%B5
 * 跳转到指定微博：sinaweibo://detail/?dispMeIfNeed=1&mblogid=<MID>
 * 调起微博直接到指定的个人页面：sinaweibo://userinfo?uid=xxxx
 */
@class MBProgressHUD;
@interface YHSinaManager : NSObject
#if __has_include(<Weibo_SDK/WeiboSDK.h>)
/// 初始化SDK的appID
@property (nonatomic, copy, readonly) NSString *appID;

/// 初始化SDK的redirectURI
@property (nonatomic, copy, readonly) NSString *redirectURI;

/// 授权成功后的信息保存在此对象里面，需要什么信息自己去拿
@property (nonatomic, strong, readonly, nullable) WBAuthorizeResponse *authorizeResponse;

/// 微博登录获取的个人信息
@property (nonatomic, strong, readonly, nullable) YHSinaUserInfo *userInfo;

#endif

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#if __has_include(<Weibo_SDK/WeiboSDK.h>)
#pragma mark Init
/// SDK初始化
/// @param appID appID
/// @param redirectURI redirectURI
- (void)initWithAppID:(NSString *)appID
          redirectURI:(NSString *)redirectURI;

/// handleOpenURL
/// @param URL URL
- (void)handleOpenURL:(NSURL *)URL;


#pragma mark Auth
/// 微博授权(授权成功后，信息保存在authorizeResponse里面)
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

#pragma mark Share(分享这儿还需要再次处理下)
/// 微博分享(目前只支持分享单图，多图分享SDK有问题)
/// @param title 标题
/// @param url 链接
/// @param description 描述
/// @param thumbImageData 缩略图(必须配置，url才有效，才能点击；不能太大，不然分享不出去，根据SDK，不能超过32k)
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调
- (void)shareWithTitle:(NSString *)title
                   url:(NSString *)url
           description:(nullable NSString *)description
        thumbImageData:(nullable NSData *)thumbImageData
               showHUD:(BOOL)showHUD
       completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;
#endif

#pragma mark Get User Info
/// 获取用户信息
/// @param accessToken accessToken
/// @param userID userID
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调
- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                            userID:(NSString *)userID
                           showHUD:(BOOL)showHUD
                   completionBlock:(void(^_Nullable)(void))completionBlock;

#pragma mark Comment WeiBo
/// 评论指定微博(通过API的方式评论指定微博)
/// @param accessToken accessToken
/// @param ID 微博ID
/// @param comment 评论的内容
/// @param isCommentOriginWhenTransfer 当评论转发微博时，是否评论给原微博
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调
- (void)commentWeiBoWithAccessToken:(NSString *)accessToken
                                 ID:(NSString *)ID
                            comment:(NSString *)comment
        isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                            showHUD:(BOOL)showHUD completionBlock:(void(^_Nullable)(NSDictionary *_Nullable responseObject))completionBlock;

/// 评论指定微博(通过scheme的方式评论指定微博，可以打开微博的评论面板，评论完成后，不能自动返回APP)
/// 微博SDK的方法 commentToWeibo: 方法不能往输入框里面添加默认的内容，仅仅只是拉起微博
/// @param ID 微博ID
/// @param comment 评论的内容
- (void)commentWeiBoWithID:(NSString *)ID
                   comment:(nullable NSString *)comment;

#pragma mark Get Wy WebiBo
/// 获取我自己发布的微博
/// @param accessToken accessToken
/// @param userID userID
/// @param perCount 单页返回的条数
/// @param curPage 页数
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调的原始数据
- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken
                                 userID:(NSString *)userID
                               perCount:(int)perCount
                                curPage:(int)curPage
                                showHUD:(BOOL)showHUD
                        completionBlock:(void(^_Nullable)(NSDictionary *_Nullable responseObject))completionBlock;
@end


@interface YHSinaManager (Private)
- (void)_addObserve;
- (void)_removeObserve;
- (MBProgressHUD *)getHUD;
- (void)_hideHUD:(MBProgressHUD *)hud;
@end

NS_ASSUME_NONNULL_END
