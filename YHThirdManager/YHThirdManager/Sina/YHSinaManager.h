//
//  YHSinaManager.h
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface YHSinaLoginResult : NSObject
// 认证口令
@property (nonatomic, copy) NSString *access_token;
// 用户id
@property (nonatomic, copy) NSString *userid;
// 认证过期时间
@property (nonatomic, copy) NSString *expires_in;
// 昵称
@property (nonatomic, copy, nullable) NSString *nickname;
// 性别   1:男  2:女
@property (nonatomic, assign) int sex;
// 省份    用户所在省级ID
@property (nonatomic, copy, nullable) NSString *province;
// 城市    用户所在城市ID
@property (nonatomic, copy, nullable) NSString *city;
// 头像
@property (nonatomic, copy, nullable) NSString *headimgurl;
@end





/**
 * 新浪登录、分享功能的封装
 * SDK下载下载地址:https://github.com/sinaweibosdk/weibo_ios_sdk
 */
@interface YHSinaManager : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)handleOpenURL:(NSURL *)URL;

- (void)initWithAppID:(NSString *)appID redirectURI:(NSString *)redirectURI;

- (void)loginWithShowHUD:(BOOL)showHUD completionBlock:(void(^_Nullable)(YHSinaLoginResult *_Nullable result))completionBlock;


- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(nullable NSString *)description
          thumbnailData:(nullable NSData *)thumbnailData
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


- (void)shareWithContent:(nullable NSString *)content
                  images:(NSArray<UIImage *> *)images
                 showHUD:(BOOL)showHUD
         completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;


@end

NS_ASSUME_NONNULL_END
