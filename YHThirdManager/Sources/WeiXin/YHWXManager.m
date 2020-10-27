//
//  YHWXManager.m
//  QAQSmooth
//
//  Created by apple on 2019/3/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXManager.h"
#import <objc/message.h>

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
#import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
#import "MBProgressHUD.h"
#endif

#import "YHThirdDefine.h"
#import "YHThirdHttpRequest.h"


#define kGetAccessTokenAPI   @"https://api.weixin.qq.com/sns/oauth2/access_token"
#define kGetUserInfoAPI      @"https://api.weixin.qq.com/sns/userinfo"


@interface YHWXManager() <WXApiDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, strong) YHWXAuthResult *authResult;
@property (nonatomic, strong) YHWXUserInfo *userInfo;


@property (nonatomic, strong) MBProgressHUD *requestCodeHUD;
@property (nonatomic, strong) MBProgressHUD *requestAccessTokenHUD;
@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareWebHUD;


@property (nonatomic, copy) void(^getCodeCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^shareWebCompletionBlock)(BOOL isSuccess);
@end


@implementation YHWXManager

+ (instancetype)sharedInstance{
    static YHWXManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)initWithAppID:(NSString *)appID
            appSecret:(NSString *)appSecret
        universalLink:(NSString *)universalLink{
    if (!appID) {
        YHThirdDebugLog(@"[微信] [初始化] appID为空");
        return;
    }
    self.appID = appID;
    self.appSecret = appSecret;
    [WXApi registerApp:appID universalLink:universalLink];
}

- (void)handleOpenURL:(NSURL *)URL{
    YHThirdDebugLog(@"[微信] [handleOpenURL] [URL] %@", URL);
    [WXApi handleOpenURL:URL delegate:self];
}

- (void)handleOpenUniversalLink:(NSUserActivity *)userActivity{
    YHThirdDebugLog(@"[微信] [handleOpenUniversalLink] [userActivity] %@", userActivity);
    [WXApi handleOpenUniversalLink:userActivity delegate:self];
}


#pragma mark Auth
- (void)authForGetCodeWithShowHUD:(BOOL)showHUD completionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.appID) {
            YHThirdDebugLog(@"[微信] [获取code] appID为空");
            return;
        }
        
        if (showHUD && [WXApi isWXAppInstalled]) {
            [self _removeObserve];
            [self _addObserve];
            self.requestCodeHUD = YHThird_GetHud;
        }
        
        self.getCodeCompletionBlock = completionBlock;
        
        SendAuthReq *rq = [[SendAuthReq alloc] init];
        rq.scope = @"snsapi_userinfo";
        
        [WXApi sendAuthReq:rq viewController:[UIApplication sharedApplication].keyWindow.rootViewController delegate:self completion:^(BOOL success) {
            if (success) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO);
                }
                weakSelf.getCodeCompletionBlock = nil;
                [weakSelf _removeObserve];
                YHThird_HideHud(weakSelf.requestCodeHUD);
                weakSelf.requestCodeHUD = nil;
            });
        }];
    });
}

/// 通过code获取AccessToken（获取AccessToken其实是个普通的网络请求）
/// @param appID appID
/// @param appSecret appSecret
/// @param code code
/// @param completionBlock 回调(是否获取成功，授权信息保存在`authResult`里面)
- (void)authForGetAccessTokenWithAppID:(NSString *)appID
                             appSecret:(NSString *)appSecret
                                  code:(NSString *)code
                               showHUD:(BOOL)showHUD
                       completionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        if (showHUD) {
            weakSelf.requestAccessTokenHUD = YHThird_GetHud;
        }
        
        NSDictionary *param = @{@"appid": appID ? appID : @"",
                                @"secret": appSecret ? appSecret : @"",
                                @"code": code ? code : @"",
                                @"grant_type": @"authorization_code"};
        
        YHThirdDebugLog(@"[微信] [获取accessToken参数] %@", param);
        
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kGetAccessTokenAPI method:YHThirdHttpRequestMethodGET parameter:param successBlock:^(id  _Nonnull responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                YHThird_HideHud(weakSelf.requestAccessTokenHUD);
                weakSelf.requestAccessTokenHUD = nil;
                if (![responseObject isKindOfClass:[NSDictionary class]]) {
                    YHThirdDebugLog(@"[微信] [获取accessToken失败] [数据格式不正确] %@", responseObject);
                    weakSelf.authResult = nil; // 置为nil
                    if (completionBlock) {
                        completionBlock(NO);
                    }
                    return ;
                }
                YHThirdDebugLog(@"[微信] [获取accessToken成功] %@", responseObject);
                NSDictionary *infoDic = (NSDictionary *)responseObject;
                YHWXAuthResult *authResult = [[YHWXAuthResult alloc] init];
                authResult.code = code;
                authResult.originAuthInfo = infoDic;
                if ([infoDic.allKeys containsObject:@"access_token"]) {
                    authResult.accessToken = [NSString stringWithFormat:@"%@",infoDic[@"access_token"]];
                }
                if ([infoDic.allKeys containsObject:@"expires_in"]) {
                    authResult.expiresIn = [NSString stringWithFormat:@"%@",infoDic[@"expires_in"]];
                }
                if ([infoDic.allKeys containsObject:@"refresh_token"]) {
                    authResult.refreshToken = [NSString stringWithFormat:@"%@",infoDic[@"refresh_token"]];
                }
                if ([infoDic.allKeys containsObject:@"openid"]) {
                    authResult.openID = [NSString stringWithFormat:@"%@",infoDic[@"openid"]];
                }
                if ([infoDic.allKeys containsObject:@"scope"]) {
                    authResult.scope = [NSString stringWithFormat:@"%@",infoDic[@"scope"]];
                }
                weakSelf.authResult = authResult; // 赋值
                if (completionBlock) {
                    completionBlock(YES);
                }
            });
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[微信] [获取accessToken失败] %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                YHThird_HideHud(weakSelf.requestAccessTokenHUD);
                weakSelf.requestAccessTokenHUD = nil;
                weakSelf.authResult = nil; // 置为nil
                if (completionBlock) {
                    completionBlock(NO);
                }
            });
        }];
    });
}


#pragma mark Get User Info
/// 获取用户信息（本质上是一个普通的网络请求）
/// @param openID 授权成功后获取到的openID
/// @param accessToken 授权成功后获取到的accessToken
/// @param showHUD 是否显示HUD
/// @param completionBlock 回调（如果获取成功，那么用户信息保存在`userInfo`里面）
- (void)getUserInfoWithOpenID:(NSString *)openID
                  accessToken:(NSString *)accessToken
                      showHUD:(BOOL)showHUD
              completionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (showHUD) {
            weakSelf.getUserInfoHUD = YHThird_GetHud;
        }
        
        NSDictionary *param = @{@"access_token": accessToken ? accessToken : @"",
                                @"openid": openID ? openID : @""};
        
        YHThirdDebugLog(@"[微信] [获取用户信息参数] %@", param);
        
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kGetUserInfoAPI method:YHThirdHttpRequestMethodGET parameter:param successBlock:^(id  _Nonnull responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                YHThird_HideHud(weakSelf.getUserInfoHUD);
                weakSelf.getUserInfoHUD = nil;
                if (![responseObject isKindOfClass:[NSDictionary class]]) {
                    YHThirdDebugLog(@"[微信] [获取用户信息失败] [数据格式不正确] %@", responseObject);
                    weakSelf.userInfo = nil; // 置为nil
                    if (completionBlock) {
                        completionBlock(NO);
                    }
                    return ;
                }
                YHThirdDebugLog(@"[微信] [获取用户信息成功] %@", responseObject);
                NSDictionary *infoDic = (NSDictionary *)responseObject;
                YHWXUserInfo *userInfo = [[YHWXUserInfo alloc] init];
                userInfo.originInfo = infoDic;
                if ([infoDic.allKeys containsObject:@"nickname"]) {
                    userInfo.nickName = [NSString stringWithFormat:@"%@",infoDic[@"nickname"]];
                }
                if ([infoDic.allKeys containsObject:@"sex"]) {
                    NSString *sex = [NSString stringWithFormat:@"%@",infoDic[@"sex"]];
                    NSString *regex = @"[0-9]*";
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
                    BOOL res = [pred evaluateWithObject:sex];
                    if (res) {
                        userInfo.sex = [sex intValue];
                    } else {
                        userInfo.sex = 0;
                    }
                }
                if ([infoDic.allKeys containsObject:@"province"]) {
                    userInfo.province = [NSString stringWithFormat:@"%@",infoDic[@"province"]];
                }
                if ([infoDic.allKeys containsObject:@"city"]) {
                    userInfo.city = [NSString stringWithFormat:@"%@",infoDic[@"city"]];
                }
                if ([infoDic.allKeys containsObject:@"country"]) {
                    userInfo.country = [NSString stringWithFormat:@"%@",infoDic[@"country"]];
                }
                if ([infoDic.allKeys containsObject:@"headimgurl"]) {
                    userInfo.headImgURL = [NSString stringWithFormat:@"%@",infoDic[@"headimgurl"]];
                }
                if ([infoDic.allKeys containsObject:@"unionid"]) {
                    userInfo.unionID = [NSString stringWithFormat:@"%@",infoDic[@"unionid"]];
                }
                weakSelf.userInfo = userInfo;
                if (completionBlock) {
                    completionBlock(YES);
                }
            });
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[微信] [获取用户信息失败] %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                YHThird_HideHud(weakSelf.getUserInfoHUD);
                weakSelf.getUserInfoHUD = nil;
                weakSelf.userInfo = nil; // 置为nil
                if (completionBlock) {
                    completionBlock(NO);
                }
            });
        }];
    });
}








#pragma mark Share
/// 微信分享网页
/// @param URL 链接
/// @param title 标题
/// @param description 描述
/// @param thumbImage 缩略图
/// @param shareType 分享类型（目前只能分享到朋友圈和聊天界面）
/// @param showHUD 是否显示HUD
/// @param completionBlock 分享完成后的回调
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
             thumbImage:(UIImage *)thumbImage
              shareType:(YHWXShareType)shareType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHThirdDebugLog(@"[微信] [分享] appID为空");
            return;
        }
        if (showHUD && [WXApi isWXAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.shareWebHUD = YHThird_GetHud;
        }
        
        weakSelf.shareWebCompletionBlock = completionBlock;
        
        WXWebpageObject *webpageObject = [WXWebpageObject object];
        webpageObject.webpageUrl = URL;
        
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = title;
        message.description = description;
        [message setThumbImage:thumbImage];
        message.mediaObject = webpageObject;
        
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
        req.bText = NO; // YES:文本消息    NO:多媒体消息
        req.message = message;
        
        enum WXScene scene = WXSceneSession;
        if (shareType == YHWXShareType_Session) {
            scene = WXSceneSession;
        } else if (shareType == YHWXShareType_Timeline) {
            scene = WXSceneTimeline;
        }
        req.scene = scene;
        
        [WXApi sendReq:req completion:^(BOOL success) {
            if (success) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO);
                }
                weakSelf.shareWebCompletionBlock = nil;
                [weakSelf _removeObserve];
                YHThird_HideHud(weakSelf.shareWebHUD);
                weakSelf.shareWebHUD = nil;
            });
        }];
    });
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHThirdDebugLog(@"[微信] applicationWillEnterForeground");
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        YHThird_HideHud(self.requestCodeHUD);
        self.requestCodeHUD = nil;
        //
        YHThird_HideHud(self.shareWebHUD)
        self.shareWebHUD = nil;
        // for pay
        [[NSNotificationCenter defaultCenter] postNotificationName:@"yh_wx_hide_hud_ppp_aaa_yyy_notification" object:nil userInfo:nil];
    });
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHThirdDebugLog(@"[微信] applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHThirdDebugLog(@"[微信] applicationDidBecomeActive");
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        YHThird_HideHud(self.requestCodeHUD);
        self.requestCodeHUD = nil;
        //
        YHThird_HideHud(self.shareWebHUD)
        self.shareWebHUD = nil;
        // for pay
        [[NSNotificationCenter defaultCenter] postNotificationName:@"yh_wx_hide_hud_ppp_aaa_yyy_notification" object:nil userInfo:nil];
    });
}


#pragma mark ------------------ <WXApiDelegate> ------------------
- (void)onReq:(BaseReq *)req{
    YHThirdDebugLog(@"[微信] [onReq] [req] %@ [type] %d", req, req.type);
}



/*
 WXSuccess           = 0,    // 成功
 WXErrCodeCommon     = -1,   // 普通错误类型
 WXErrCodeUserCancel = -2,   // 用户点击取消并返回
 WXErrCodeSentFail   = -3,   // 发送失败
 WXErrCodeAuthDeny   = -4,   // 授权失败
 WXErrCodeUnsupport  = -5,   // 微信不支持
 */
- (void)onResp:(BaseResp *)resp{
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        // 授权
        SendAuthResp *response = (SendAuthResp *)resp;
        YHThirdDebugLog(@"[微信] [onResp] [SendAuthResp] [errCode] %d", response.errCode);
        YHThirdDebugLog(@"[微信] [onResp] [SendAuthResp] [code] %@", response.code);
        YHThirdDebugLog(@"[微信] [onResp] [SendAuthResp] [state] %@", response.state);
        YHThirdDebugLog(@"[微信] [onResp] [SendAuthResp] [lang] %@", response.lang);
        YHThirdDebugLog(@"[微信] [onResp] [SendAuthResp] [country] %@", response.country);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.code = response.errCode == WXSuccess ? response.code : nil;
            [self _removeObserve];
            YHThird_HideHud(self.requestCodeHUD);
            self.requestCodeHUD = nil;
            if (self.getCodeCompletionBlock) {
                self.getCodeCompletionBlock(response.errCode == WXSuccess);
            }
            self.getCodeCompletionBlock = nil;
        });
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        // 分享
        SendMessageToWXResp *response = (SendMessageToWXResp *)resp;
        YHThirdDebugLog(@"[微信] [onResp] [SendMessageToWXResp] [errCode] %d", response.errCode);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _removeObserve];
            YHThird_HideHud(self.shareWebHUD);
            self.shareWebHUD = nil;
            if (self.shareWebCompletionBlock) {
                self.shareWebCompletionBlock(response.errCode == WXSuccess);
            }
            self.shareWebCompletionBlock = nil;
        });
    } else {
        // for pay
        [[NSNotificationCenter defaultCenter] postNotificationName:@"yh_wx_ppp_aaa_yyy_notification" object:nil userInfo:@{@"resp": resp}];
    }
}
@end



@implementation YHWXManager (Private)
// 添加观察者
- (void)_addObserve{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

// 移除观察者
- (void)_removeObserve{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}
@end
