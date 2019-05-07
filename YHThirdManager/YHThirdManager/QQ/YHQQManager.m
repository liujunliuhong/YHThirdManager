//
//  YHQQManager.m
//  QAQSmooth
//
//  Created by apple on 2019/3/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHQQManager.h"


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

@implementation YHQQUserInfo
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nickName = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.headImgURL = @"";
        self.originInfo = nil;
    }
    return self;
}

- (NSString *)description{
    NSDictionary *dic = @{@"nickName": self.nickName ? self.nickName : [NSNull null],
                          @"sex":@(self.sex),
                          @"province":self.province ? self.province : [NSNull null],
                          @"city":self.city ? self.city : [NSNull null],
                          @"headImgURL":self.headImgURL ? self.headImgURL : [NSNull null],
                          @"originInfo":self.originInfo ? self.originInfo : [NSNull null]};
    return [NSString stringWithFormat:@"%@", dic];
}

@end


@interface YHQQManager() <TencentSessionDelegate, QQApiInterfaceDelegate>
@property (nonatomic, strong) TencentOAuth *oauth;
@property (nonatomic, copy) NSString *appID;

@property (nonatomic, strong) MBProgressHUD *authHUD;
@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareWebHUD;

@property (nonatomic, copy) void(^authComplectionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^getUserInfoComplectionBlock)(YHQQUserInfo *result);
@property (nonatomic, copy) void(^shareWebComplectionBlock)(BOOL isSuccess);

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



- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHQQDebugLog(@"[授权] appID为空");
            return;
        }
        weakSelf.sdkFlag = NO;
        if (showHUD && [QQApiInterface isQQInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.authHUD = [weakSelf getHUD];
        }
        weakSelf.authComplectionBlock = completionBlock;
        
        NSArray *permissions = @[kOPEN_PERMISSION_GET_INFO,
                                 kOPEN_PERMISSION_GET_USER_INFO,
                                 kOPEN_PERMISSION_GET_SIMPLE_USER_INFO];
        BOOL res = [weakSelf.oauth authorize:permissions inSafari:NO];
        if (!res) {
            if (completionBlock) {
                completionBlock(NO);
            }
            weakSelf.authComplectionBlock = nil;
            [weakSelf _hideHUD:weakSelf.authHUD];
            [weakSelf _removeObserve];
        }
    });
}

- (void)getUserInfoWithShowHUD:(BOOL)showHUD
               completionBlock:(void (^)(YHQQUserInfo * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
            weakSelf.getUserInfoHUD = [weakSelf getHUD];
        }
        weakSelf.getUserInfoComplectionBlock = completionBlock;
        
        BOOL res = [weakSelf.oauth getUserInfo];
        if (!res) {
            if (completionBlock) {
                completionBlock(nil);
            }
            weakSelf.getUserInfoComplectionBlock = nil;
            [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
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
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHQQDebugLog(@"[分享] appID为空");
            return;
        }
        weakSelf.sdkFlag = NO;
        if (showHUD && [QQApiInterface isQQInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.shareWebHUD = [weakSelf getHUD];
        }
        weakSelf.shareWebComplectionBlock = completionBlock;
        
        QQApiNewsObject *object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:URL] title:title description:description previewImageURL:[NSURL URLWithString:thumbImageURL]];
        ShareDestType destType = ShareDestTypeQQ;
        if (shareDestType == YHQQShareDestType_QQ) {
            destType = ShareDestTypeQQ;
        } else if (shareTye == YHQQShareDestType_TIM) {
            destType = ShareDestTypeTIM;
        }
        object.shareDestType = destType;
        SendMessageToQQReq *rq = [SendMessageToQQReq reqWithContent:object];
        
        QQApiSendResultCode sendResultCode = EQQAPISENDFAILD;
        if (shareTye == YHQQShareType_QQ) {
            sendResultCode = [QQApiInterface sendReq:rq];
        } else if (shareTye == YHQQShareType_QZone) {
            sendResultCode = [QQApiInterface SendReqToQZone:rq];
        }
        YHQQDebugLog(@"[分享] [QQApiSendResultCode] %d", sendResultCode);
        if (sendResultCode != EQQAPISENDSUCESS) {
            if (completionBlock) {
                completionBlock(NO);
            }
            weakSelf.shareWebComplectionBlock = nil;
            [weakSelf _hideHUD:weakSelf.shareWebHUD];
            [weakSelf _removeObserve];
        }
    });
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHQQDebugLog(@"applicationWillEnterForeground");
    [self _hideHUD:self.authHUD];
    [self _hideHUD:self.shareWebHUD];
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
    [self _hideHUD:self.authHUD];
    [self _hideHUD:self.shareWebHUD];
}


#pragma mark ------------------ <TencentLoginDelegate> ------------------
// 登录成功后的回调.
- (void)tencentDidLogin {
    YHQQDebugLog(@"[登录] [TencentSessionDelegate] tencentDidLogin");
    if (self.authComplectionBlock) {
        self.authComplectionBlock(YES);
    }
    self.authComplectionBlock = nil;
    [self _hideHUD:self.authHUD];
    [self _removeObserve];
}

// 授权失败后的回调.
- (void)tencentDidNotLogin:(BOOL)cancelled {
    YHQQDebugLog(@"[授权] [TencentSessionDelegate] tencentDidNotLogin");
    if (self.authComplectionBlock) {
        self.authComplectionBlock(NO);
    }
    self.authComplectionBlock = nil;
    [self _hideHUD:self.authHUD];
    [self _removeObserve];
}

// 授权时网络有问题的回调.
- (void)tencentDidNotNetWork {
    YHQQDebugLog(@"[授权] [TencentSessionDelegate] tencentDidNotNetWork");
    if (self.authComplectionBlock) {
        self.authComplectionBlock(NO);
    }
    self.authComplectionBlock = nil;
    [self _hideHUD:self.authHUD];
    [self _removeObserve];
}

- (void)didGetUnionID{
    YHQQDebugLog(@"[didGetUnionID] %@", self.oauth.unionid);
}

#pragma mark ------------------ <TencentSessionDelegate> ------------------
- (void)getUserInfoResponse:(APIResponse *)response{
    // 获取用户个人信息回调.
    YHQQDebugLog(@"[获取用户信息] [TencentSessionDelegate] [getUserInfoResponse] %@", response.jsonResponse);
    if (response.detailRetCode == kOpenSDKErrorSuccess && response.retCode == URLREQUEST_SUCCEED && response.jsonResponse && [response.jsonResponse isKindOfClass:[NSDictionary class]]) {
        
        YHQQUserInfo *result = [[YHQQUserInfo alloc] init];
        
        NSDictionary *infoDic = (NSDictionary *)response.jsonResponse;
        
        result.originInfo = infoDic;
        
        if ([infoDic.allKeys containsObject:@"nickname"]) {
            result.nickName = [NSString stringWithFormat:@"%@", infoDic[@"nickname"]];
        }
        if ([infoDic.allKeys containsObject:@"gender"]) {
            NSString *sex = [NSString stringWithFormat:@"%@", infoDic[@"gender"]];
            if ([sex isEqualToString:@"男"]) {
                result.sex = 1;
            } else if ([sex isEqualToString:@"女"]) {
                result.sex = 2;
            } else {
                result.sex = 0;
            }
        }
        if ([infoDic.allKeys containsObject:@"province"]) {
            result.province = [NSString stringWithFormat:@"%@", infoDic[@"province"]];
        }
        if ([infoDic.allKeys containsObject:@"city"]) {
            result.city = [NSString stringWithFormat:@"%@", infoDic[@"city"]];
        }
        
        // 依次取头像，保证一定有头像返回
        if ([infoDic.allKeys containsObject:@"figureurl_qq"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_qq_2"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq_2"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_2"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_2"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_1"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_1"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl"]];
        } else if ([infoDic.allKeys containsObject:@"figureurl_qq_1"]) {
            result.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"figureurl_qq_1"]];
        }
        
        if (self.getUserInfoComplectionBlock) {
            self.getUserInfoComplectionBlock(result);
        }
        self.getUserInfoComplectionBlock = nil;
        [self _hideHUD:self.getUserInfoHUD];
    } else {
        if (self.getUserInfoComplectionBlock) {
            self.getUserInfoComplectionBlock(nil);
        }
        self.getUserInfoComplectionBlock = nil;
        [self _hideHUD:self.getUserInfoHUD];
    }
}


#pragma mark ------------------ <QQApiInterfaceDelegate> ------------------
// 处理来至QQ的请求.
- (void)onReq:(QQBaseReq *)req{
    YHQQDebugLog(@"[QQApiInterfaceDelegate] [onReq] %@ [type] %d", req, req.type);
}

// 处理来至QQ的响应.
- (void)onResp:(QQBaseResp *)resp{
    YHQQDebugLog(@"[QQApiInterfaceDelegate] [onResp] %@", resp);
    if ([resp isKindOfClass:[SendMessageToQQResp class]]) {
        SendMessageToQQResp *response = (SendMessageToQQResp *)resp;
        YHQQDebugLog(@"[分享] [QQApiInterfaceDelegate] [onResp] [SendMessageToQQResp] [result] %@", response.result);
        if ([response.result isEqualToString:@"0"]) {
            if (self.shareWebComplectionBlock) {
                self.shareWebComplectionBlock(YES);
            }
            self.shareWebComplectionBlock = nil;
            [self _hideHUD:self.shareWebHUD];
            [self _removeObserve];
        } else {
            if (self.shareWebComplectionBlock) {
                self.shareWebComplectionBlock(NO);
            }
            self.shareWebComplectionBlock = nil;
            [self _hideHUD:self.shareWebHUD];
            [self _removeObserve];
        }
    }
}

// 处理QQ在线状态的回调.
- (void)isOnlineResponse:(NSDictionary *)response{
    YHQQDebugLog(@"[QQApiInterfaceDelegate] [isOnlineResponse] %@", response);
}


#pragma mark ------------------ 私有方法 ------------------
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
