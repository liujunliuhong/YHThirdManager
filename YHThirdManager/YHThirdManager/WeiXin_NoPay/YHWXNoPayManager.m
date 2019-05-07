//
//  YHWXNoPayManager.m
//  QAQSmooth
//
//  Created by 银河 on 2019/3/9.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXNoPayManager.h"


#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
    #import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
    #import "MBProgressHUD.h"
#endif

#ifdef DEBUG
    #define YHWXDebugLog(format, ...)  printf("👉👉👉👉👉[WX_NoPay] %s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
    #define YHWXDebugLog(format, ...)
#endif

#define kYHWXError(__msg__)            [NSError errorWithDomain:@"com.yinhe.wx.nopay" code:-1 userInfo:@{NSLocalizedDescriptionKey: __msg__}]

@implementation YHWXNoPayUserInfoResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nickName = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.country = @"";
        self.headImgURL = @"";
        self.unionID = @"";
        self.originUserInfo = nil;
    }
    return self;
}

- (NSString *)description{
    NSDictionary *dic = @{@"nickName":self.nickName ? self.nickName : [NSNull null],
                          @"sex":@(self.sex),
                          @"province":self.province ? self.province : [NSNull null],
                          @"city":self.city ? self.city : [NSNull null],
                          @"country":self.country ? self.country : [NSNull null],
                          @"headImgURL":self.headImgURL ? self.headImgURL : [NSNull null],
                          @"unionID":self.unionID ? self.unionID : [NSNull null],
                          @"originUserInfo":self.originUserInfo ? self.originUserInfo : [NSNull null]};
    return [NSString stringWithFormat:@"%@", dic];
}

@end



@implementation YHWXNoPayAuthResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.openID = @"";
        self.accessToken = @"";
        self.refreshToken = @"";
        self.scope = @"";
        self.expiresIn = @"";
        self.originAuthInfo = nil;
    }
    return self;
}

- (NSString *)description{
    NSDictionary *dic = @{@"openID":self.openID ? self.openID : [NSNull null],
                          @"accessToken":self.accessToken ? self.accessToken : [NSNull null],
                          @"expiresIn":self.expiresIn ? self.expiresIn : [NSNull null],
                          @"refreshToken":self.refreshToken ? self.refreshToken : [NSNull null],
                          @"scope":self.scope ? self.scope : [NSNull null],
                          @"originAuthInfo":self.originAuthInfo ? self.originAuthInfo : [NSNull null]};
    return [NSString stringWithFormat:@"%@", dic];
}
@end

@interface YHWXNoPayManager () <WXApiDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *appSecret;

@property (nonatomic, copy) void(^shareWebCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^payCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^authCompletionBlock)(YHWXNoPayAuthResult *authResult);



@property (nonatomic, strong) MBProgressHUD *requestCodeHUD;
@property (nonatomic, strong) MBProgressHUD *requestAccessTokenHUD;

@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareWebHUD;





@property (nonatomic, assign) BOOL sdkFlag;

@end

@implementation YHWXNoPayManager
+ (instancetype)sharedInstance{
    static YHWXNoPayManager *manager = nil;
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
- (void)initWithAppID:(NSString *)appID appSecret:(NSString *)appSecret{
    if (!appID) {
        YHWXDebugLog(@"[初始化] appID为空");
        return;
    }
    if (!appSecret) {
        YHWXDebugLog(@"[初始化] appSecret为空");
        return;
    }
    self.appID = appID;
    self.appSecret = appSecret;
    [WXApi registerApp:appID];
}

- (void)handleOpenURL:(NSURL *)URL{
    if ([URL.scheme hasPrefix:@"wx"]) {
        YHWXDebugLog(@"[handleOpenURL] [URL] %@", URL);
        [WXApi handleOpenURL:URL delegate:self];
    }
}

- (void)authWithShowHUD:(BOOL)showHUD completionBlock:(void (^)(YHWXNoPayAuthResult * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHWXDebugLog(@"[授权] appID为空");
            return;
        }
        if (!weakSelf.appSecret) {
            YHWXDebugLog(@"[授权] appSecret为空");
            return;
        }
        
        weakSelf.sdkFlag = NO;
        
        if (showHUD && [WXApi isWXAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.requestCodeHUD = [weakSelf getHUD];
        }
        
        weakSelf.authCompletionBlock = completionBlock;
        
        SendAuthReq *rq = [[SendAuthReq alloc] init];
        rq.scope = @"snsapi_userinfo";
        
        BOOL res = [WXApi sendAuthReq:rq viewController:[UIApplication sharedApplication].keyWindow.rootViewController delegate:weakSelf];
        if (!res) {
            if (completionBlock) {
                completionBlock(nil);
            }
            weakSelf.authCompletionBlock = nil;
            [weakSelf _hideHUD:weakSelf.requestCodeHUD];
            [weakSelf _removeObserve];
        }
    });
}

- (void)getUserInfoWithOpenID:(NSString *)openID accessToken:(NSString *)accessToken showHUD:(BOOL)showHUD completionBlock:(void (^)(YHWXNoPayUserInfoResult * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!accessToken || accessToken.length <= 0) {
            YHWXDebugLog(@"[获取用户信息] [accessToken为空]");
            return;
        }
        if (!openID || openID.length <= 0) {
            YHWXDebugLog(@"[获取用户信息] [openID为空]");
            return;
        }
        if (showHUD) {
            weakSelf.getUserInfoHUD = [weakSelf getHUD];
        }
        NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", accessToken, openID];
        [YHWXNoPayManager _requestWithURL:url completionBlock:^(id  _Nullable responseObject, NSError * _Nullable error) {
            if (error) {
                YHWXDebugLog(@"[获取用户信息] [error] %@", error);
            }
            if (responseObject) {
                YHWXDebugLog(@"[获取用户信息] [responseObject] %@", responseObject);
            }
            if (!error && responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *infoDic = (NSDictionary *)responseObject;
                if ([infoDic.allKeys containsObject:@"errcode"]) {
                    // 失败
                    if (completionBlock) {
                        completionBlock(nil);
                    }
                    [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
                } else {
                    // 成功
                    YHWXNoPayUserInfoResult *userInfoResult = [[YHWXNoPayUserInfoResult alloc] init];
                    
                    userInfoResult.originUserInfo = infoDic;
                    
                    if ([infoDic.allKeys containsObject:@"nickname"]) {
                        userInfoResult.nickName = [NSString stringWithFormat:@"%@",infoDic[@"nickname"]];
                    }
                    if ([infoDic.allKeys containsObject:@"sex"]) {
                        NSString *sex = [NSString stringWithFormat:@"%@",infoDic[@"sex"]];
                        NSString *regex = @"[0-9]*";
                        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
                        BOOL res = [pred evaluateWithObject:sex];
                        if (res) {
                            userInfoResult.sex = [sex intValue];
                        } else {
                            userInfoResult.sex = 0;
                        }
                    }
                    if ([infoDic.allKeys containsObject:@"province"]) {
                        userInfoResult.province = [NSString stringWithFormat:@"%@",infoDic[@"province"]];
                    }
                    if ([infoDic.allKeys containsObject:@"city"]) {
                        userInfoResult.city = [NSString stringWithFormat:@"%@",infoDic[@"city"]];
                    }
                    if ([infoDic.allKeys containsObject:@"country"]) {
                        userInfoResult.country = [NSString stringWithFormat:@"%@",infoDic[@"country"]];
                    }
                    if ([infoDic.allKeys containsObject:@"headimgurl"]) {
                        userInfoResult.headImgURL = [NSString stringWithFormat:@"%@",infoDic[@"headimgurl"]];
                    }
                    if ([infoDic.allKeys containsObject:@"unionid"]) {
                        userInfoResult.unionID = [NSString stringWithFormat:@"%@",infoDic[@"unionid"]];
                    }
                    if (completionBlock) {
                        completionBlock(userInfoResult);
                    }
                    [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
                }
            } else {
                // 失败
                if (completionBlock) {
                    completionBlock(nil);
                }
                [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
            }
        }];
    });
}


- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
             thumbImage:(UIImage *)thumbImage
              shareType:(YHWXNoPayShareType)shareType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHWXDebugLog(@"[分享] appID为空");
            return;
        }
        if (showHUD && [WXApi isWXAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.shareWebHUD = [weakSelf getHUD];
        }
        weakSelf.sdkFlag = NO;
        
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
        if (shareType == YHWXNoPayShareType_Session) {
            scene = WXSceneSession;
        } else if (shareType == YHWXNoPayShareType_Timeline) {
            scene = WXSceneTimeline;
        }
        req.scene = scene;
        
        BOOL res = [WXApi sendReq:req];
        if (!res) {
            if (completionBlock) {
                completionBlock(NO);
            }
            weakSelf.shareWebCompletionBlock = nil;
            [weakSelf _removeObserve];
            [weakSelf _hideHUD:weakSelf.shareWebHUD];
        }
    });
}


#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHWXDebugLog(@"applicationWillEnterForeground");
    [self _hideHUD:self.requestCodeHUD];
    [self _hideHUD:self.shareWebHUD];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHWXDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHWXDebugLog(@"applicationDidBecomeActive");
    if (self.sdkFlag) {
        return;
    }
    [self _hideHUD:self.requestCodeHUD];
    [self _hideHUD:self.shareWebHUD];
}


#pragma mark ------------------ <WXApiDelegate> ------------------
- (void)onReq:(BaseReq *)req{
    YHWXDebugLog(@"[onReq] [req] %@ [type] %d", req, req.type);
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
        YHWXDebugLog(@"[onResp] [SendAuthResp] [errCode] %d", response.errCode);
        YHWXDebugLog(@"[onResp] [SendAuthResp] [code] %@", response.code);
        YHWXDebugLog(@"[onResp] [SendAuthResp] [state] %@", response.state);
        YHWXDebugLog(@"[onResp] [SendAuthResp] [lang] %@", response.lang);
        YHWXDebugLog(@"[onResp] [SendAuthResp] [country] %@", response.country);
        if (response.errCode == WXSuccess) {
            self.sdkFlag = YES;
            [self _removeObserve];
            [self _hideHUD:self.requestCodeHUD];
            self.requestAccessTokenHUD = [self getHUD];
            NSString *responseCode = response.code; // code获取成功，接下来获取accessToken
            [self _requestAccessTokenWithCode:responseCode];
        } else if (response.errCode == WXErrCodeCommon ||
                   response.errCode == WXErrCodeUserCancel ||
                   response.errCode == WXErrCodeSentFail ||
                   response.errCode == WXErrCodeAuthDeny ||
                   response.errCode == WXErrCodeUnsupport) {
            [self _removeObserve];
            [self _hideHUD:self.requestCodeHUD];
            [self _hideHUD:self.requestAccessTokenHUD]; // 保险起见，也隐藏这个
            if (self.authCompletionBlock) {
                self.authCompletionBlock(nil);
            }
            self.authCompletionBlock = nil;
        }
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        // 分享
        SendMessageToWXResp *response = (SendMessageToWXResp *)resp;
        YHWXDebugLog(@"[onResp] [SendMessageToWXResp] [errCode] %d", response.errCode);
        if (response.errCode == WXSuccess) {
            if (self.shareWebCompletionBlock) {
                self.shareWebCompletionBlock(YES);
            }
            self.shareWebCompletionBlock = nil;
            [self _removeObserve];
            [self _hideHUD:self.shareWebHUD];
        } else if (response.errCode == WXErrCodeCommon ||
                   response.errCode == WXErrCodeUserCancel ||
                   response.errCode == WXErrCodeSentFail ||
                   response.errCode == WXErrCodeAuthDeny ||
                   response.errCode == WXErrCodeUnsupport) {
            if (self.shareWebCompletionBlock) {
                self.shareWebCompletionBlock(NO);
            }
            self.shareWebCompletionBlock = nil;
            [self _removeObserve];
            [self _hideHUD:self.shareWebHUD];
        }
    }
}

#pragma mark ------------------ 私有方法 ------------------
+ (void)_requestWithURL:(NSString *)URL completionBlock:(void (^)(id _Nullable responseObject, NSError * _Nullable error))completionBlock{
    NSURL *url = [NSURL URLWithString:URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (responseObject) {
                if (completionBlock) {
                    completionBlock(responseObject, nil);
                }
            } else {
                if (completionBlock) {
                    completionBlock(nil, kYHWXError(@"请求失败"));
                }
            }
        } else {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }
    }];
    [task resume];
}

// 通过code获取access_token.
- (void)_requestAccessTokenWithCode:(NSString *)code{
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", self.appID, self.appSecret, code];
    __weak typeof(self) weakSelf = self;
    [YHWXNoPayManager _requestWithURL:url completionBlock:^(id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            YHWXDebugLog(@"[获取accessToken等信息失败] [error] %@", error);
        }
        if (responseObject) {
            YHWXDebugLog(@"[获取accessToken等信息成功] [responseObject] %@", responseObject);
        }
        if (!error && responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *infoDic = (NSDictionary *)responseObject;
            if ([infoDic.allKeys containsObject:@"errcode"]) {
                // 失败
                [weakSelf _removeObserve];
                [weakSelf _hideHUD:weakSelf.requestCodeHUD];
                [weakSelf _hideHUD:weakSelf.requestAccessTokenHUD];
                if (weakSelf.authCompletionBlock) {
                    weakSelf.authCompletionBlock(nil);
                }
                weakSelf.authCompletionBlock = nil;
            } else {
                // 成功
                YHWXNoPayAuthResult *authResult = [[YHWXNoPayAuthResult alloc] init];
                
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
                [weakSelf _removeObserve];
                [weakSelf _hideHUD:weakSelf.requestCodeHUD];
                [weakSelf _hideHUD:weakSelf.requestAccessTokenHUD];
                if (weakSelf.authCompletionBlock) {
                    weakSelf.authCompletionBlock(authResult);
                }
                weakSelf.authCompletionBlock = nil;
            }
        } else {
            // 失败
            [weakSelf _removeObserve];
            [weakSelf _hideHUD:weakSelf.requestCodeHUD];
            [weakSelf _hideHUD:weakSelf.requestAccessTokenHUD];
            if (weakSelf.authCompletionBlock) {
                weakSelf.authCompletionBlock(nil);
            }
            weakSelf.authCompletionBlock = nil;
        }
    }];
}

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


// 显示HUD
- (MBProgressHUD *)getHUD{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];//必须在主线程，源码规定
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.contentColor = [UIColor whiteColor];
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    hud.removeFromSuperViewOnHide = YES;
    return hud;
}


// 隐藏HUD
- (void)_hideHUD:(MBProgressHUD *)hud{
    __weak typeof(hud) weakHUD = hud;
    if (hud) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakHUD) strongHUD = weakHUD;
            [strongHUD hideAnimated:YES];
            strongHUD = nil;
        });
    }
}

@end
