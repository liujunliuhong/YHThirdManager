//
//  YHQQManager.m
//  QAQSmooth
//
//  Created by apple on 2019/3/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHQQManager.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
    #import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
    #import "MBProgressHUD.h"
#endif

#ifdef DEBUG
    #define YHQQDebugLog(format, ...)  printf("👉👉👉👉👉[QQ] %s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
    #define YHQQDebugLog(format, ...)
#endif

@implementation YHQQLoginResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.access_token = @"";
        self.openid = @"";
        self.expires_in = @"";
        self.nickname = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.headimgurl = @"";
        self.unionid = @"";
    }
    return self;
}
@end


@interface YHQQManager() <TencentSessionDelegate, QQApiInterfaceDelegate>
@property (nonatomic, strong) TencentOAuth *oauth;
@property (nonatomic, copy) NSString *appID;

#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
@property (nonatomic, strong) MBProgressHUD *hud;
#endif

@property (nonatomic, strong) YHQQLoginResult *result;

@property (nonatomic, copy) void(^loginComplectionBlock)(YHQQLoginResult *result);
@property (nonatomic, copy) void(^shareComplectionBlock)(BOOL isSuccess);

@property (nonatomic, assign) BOOL sdkFlag;

@end


@implementation YHQQManager

+ (instancetype)sharedInstance{
    static YHQQManager *manager = nil;
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

- (void)initWithAppID:(NSString *)appID{
    if (self.oauth) {
        self.oauth = nil;
    }
    if (!appID) {
        YHQQDebugLog(@"[初始化] appID为空");
        return;
    }
    self.appID = appID;
    self.oauth = [[TencentOAuth alloc] initWithAppId:appID andDelegate:self];
}

- (void)handleOpenURL:(NSURL *)URL{
    if ([URL.scheme hasPrefix:@"tencent"]) {
        YHQQDebugLog(@"[handleOpenURL] [URL] %@", URL);
        [TencentOAuth HandleOpenURL:URL];
        [QQApiInterface handleOpenURL:URL delegate:self];
    }
}

- (void)loginWithShowHUD:(BOOL)showHUD
         completionBlock:(void (^)(YHQQLoginResult * _Nullable))completionBlock{
    if (!self.appID) {
        YHQQDebugLog(@"[登录] appID为空");
        if (completionBlock) {
            completionBlock(nil);
        }
        return;
    }
    self.sdkFlag = NO;
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        [self _showHUD];
    }
    if (self.result) {
        self.result = nil;
    }
    self.loginComplectionBlock = completionBlock;
    self.result = [[YHQQLoginResult alloc] init];
    
    NSArray *permissions = @[kOPEN_PERMISSION_GET_INFO,
                             kOPEN_PERMISSION_GET_USER_INFO,
                             kOPEN_PERMISSION_GET_SIMPLE_USER_INFO];
    dispatch_async(dispatch_get_main_queue(), ^{
       BOOL res = [self.oauth authorize:permissions inSafari:NO];
        if (!res) {
            [self _loginResult:nil];
        }
    });
}

- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
          thumbImageURL:(NSString *)thumbImageURL
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    if (!self.appID) {
        YHQQDebugLog(@"[分享] appID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    self.sdkFlag = NO;
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        [self _showHUD];
    }
    self.shareComplectionBlock = completionBlock;

    QQApiNewsObject *object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:URL] title:title description:description previewImageURL:[NSURL URLWithString:thumbImageURL]];
    ShareDestType destType = ShareDestTypeQQ;
    if (shareDestType == YHQQShareDestType_QQ) {
        destType = ShareDestTypeQQ;
    } else if (shareTye == YHQQShareDestType_TIM) {
        destType = ShareDestTypeTIM;
    }
    object.shareDestType = destType;
    SendMessageToQQReq *rq = [SendMessageToQQReq reqWithContent:object];
    dispatch_async(dispatch_get_main_queue(), ^{
        QQApiSendResultCode sendResultCode = EQQAPISENDFAILD;
        if (shareTye == YHQQShareType_QQ) {
            sendResultCode = [QQApiInterface sendReq:rq];
        } else if (shareTye == YHQQShareType_QZone) {
            sendResultCode = [QQApiInterface SendReqToQZone:rq];
        }
        YHQQDebugLog(@"[分享] [QQApiSendResultCode] %d", sendResultCode);
        if (sendResultCode != EQQAPISENDSUCESS) {
            [self _shareResult:NO];
        }
    });
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHQQDebugLog(@"applicationWillEnterForeground");
    [self _hideHUDWithCompletionBlock:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHQQDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHQQDebugLog(@"applicationDidBecomeActive");
    // 经过不断测试发现：当代理tencentDidLogin回调之后，有时仍然会走该通知回调。因此定义了一个flag，当tencentDidLogin回调之后，设置该flag为YES，否则HUD会提前关闭
    if (self.sdkFlag) {
        return;
    }
    [self _hideHUDWithCompletionBlock:nil];
}

#pragma mark ------------------ <TencentSessionDelegate> ------------------
- (void)tencentDidLogin {
    // 登录成功后的回调.
    YHQQDebugLog(@"[登录] [TencentSessionDelegate] tencentDidLogin");
    self.sdkFlag = YES;
    [self _hideHUDWithCompletionBlock:nil];
    [self _showHUD];
    [self _successLogin];
}

- (void)tencentDidNotLogin:(BOOL)cancelled {
    // 登录失败后的回调.
    YHQQDebugLog(@"[登录] [TencentSessionDelegate] tencentDidNotLogin");
    [self _loginResult:nil];
}

- (void)tencentDidNotNetWork {
    // 登录时网络有问题的回调
    YHQQDebugLog(@"[登录] [TencentSessionDelegate] tencentDidNotNetWork");
    [self _loginResult:nil];
}

- (void)getUserInfoResponse:(APIResponse *)response{
    // 获取用户个人信息回调.
    YHQQDebugLog(@"[登录] [TencentSessionDelegate] [getUserInfoResponse] %@", response.jsonResponse);
    if (response.detailRetCode == kOpenSDKErrorSuccess && response.retCode == URLREQUEST_SUCCEED && response.jsonResponse && [response.jsonResponse isKindOfClass:[NSDictionary class]]) {
        NSDictionary *infoDic = (NSDictionary *)response.jsonResponse;
        if ([infoDic.allKeys containsObject:@"nickname"]) {
            self.result.nickname = [NSString stringWithFormat:@"%@", infoDic[@"nickname"]];
        }
        if ([infoDic.allKeys containsObject:@"gender"]) {
            NSString *sex = [NSString stringWithFormat:@"%@", infoDic[@"gender"]];
            if ([sex isEqualToString:@"男"]) {
                self.result.sex = 1;
            } else if ([sex isEqualToString:@"女"]) {
                self.result.sex = 2;
            } else {
                self.result.sex = 0;
            }
        }
        if ([infoDic.allKeys containsObject:@"province"]) {
            self.result.province = [NSString stringWithFormat:@"%@", infoDic[@"province"]];
        }
        if ([infoDic.allKeys containsObject:@"city"]) {
            self.result.city = [NSString stringWithFormat:@"%@", infoDic[@"city"]];
        }
        if ([infoDic.allKeys containsObject:@"figureurl_qq"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_qq_2"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq_2"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_2"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_2"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_1"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_1"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_qq_1"]) {
            self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq_1"]];
        }
        self.result.access_token = self.oauth.accessToken;
        self.result.openid = self.oauth.openId;
        self.result.expires_in = [NSString stringWithFormat:@"%d",(int)[self.oauth.expirationDate timeIntervalSince1970]];
        self.result.unionid = self.oauth.unionid;
        
        [self _loginResult:self.result];
    } else {
        [self _loginResult:nil];
    }
}


#pragma mark ------------------ <QQApiInterfaceDelegate> ------------------
- (void)onReq:(QQBaseReq *)req{
    // 处理来至QQ的请求
    YHQQDebugLog(@"[QQApiInterfaceDelegate] [onReq] %@ [type] %d", req, req.type);
}

- (void)onResp:(QQBaseResp *)resp{
    // 处理来至QQ的响应
    if ([resp isKindOfClass:[SendMessageToQQResp class]]) {
        SendMessageToQQResp *response = (SendMessageToQQResp *)resp;
        YHQQDebugLog(@"[分享] [QQApiInterfaceDelegate] [onResp] [SendMessageToQQResp] [result] %@", response.result);
        if ([response.result isEqualToString:@"0"]) {
            [self _shareResult:YES];
        } else {
            [self _shareResult:NO];
        }
    }
}

- (void)isOnlineResponse:(NSDictionary *)response{
    // 处理QQ在线状态的回调
    YHQQDebugLog(@"[QQApiInterfaceDelegate] [isOnlineResponse] %@", response);
}


#pragma mark ------------------ 私有方法 ------------------
// 成功登录
- (void)_successLogin{
    if (self.oauth.accessToken && self.oauth.accessToken.length > 0) {
        self.result.access_token = self.oauth.accessToken;
        self.result.openid = self.oauth.openId;
        self.result.expires_in = [NSString stringWithFormat:@"%d",(int)[self.oauth.expirationDate timeIntervalSince1970]];
        self.result.unionid = self.oauth.unionid;
        [self.oauth getUserInfo];
    } else {
        [self _loginResult:nil];
    }
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

//
- (void)_loginResult:(YHQQLoginResult *)result{
    __weak typeof(self) weak_self = self;
    [self _hideHUDWithCompletionBlock:^{
        [weak_self _nilHUD];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginComplectionBlock) {
            self.loginComplectionBlock(result);
        }
        self.result = nil;
        self.loginComplectionBlock = nil;
    });
    [self _removeObserve];
}

//
- (void)_shareResult:(BOOL)result{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.shareComplectionBlock) {
            self.shareComplectionBlock(result);
        }
        self.shareComplectionBlock = nil;
    });
    [self _hideHUDWithCompletionBlock:^{
        [weak_self _nilHUD];
    }];
    [self _removeObserve];
}

// 显示HUD
- (void)_showHUD{
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.hud) {
            self.hud = nil;
        }
        self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];//必须在主线程，源码规定
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.contentColor = [UIColor whiteColor];
        self.hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.hud.bezelView.color = [UIColor blackColor];
        self.hud.removeFromSuperViewOnHide = YES;
    });
#endif
}

// 隐藏HUD
- (void)_hideHUDWithCompletionBlock:(void(^)(void))completionBlock{
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.hud) {
            return;
        }
        [self.hud hideAnimated:YES];
        self.hud.completionBlock = ^{
            if (completionBlock) {
                completionBlock();
            }
        };
    });
#else
    if (completionBlock) {
        completionBlock();
    }
#endif
}

// 把HUD置为nil
- (void)_nilHUD{
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
    if (self.hud) {
        self.hud = nil;
    }
#endif
}

@end
