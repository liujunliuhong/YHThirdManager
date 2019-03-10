//
//  YHWXManager.m
//  QAQSmooth
//
//  Created by apple on 2019/3/7.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXManager.h"
#import <CommonCrypto/CommonCrypto.h>

#if __has_include(<WechatOpenSDK/WXApi.h>)
    #import <WechatOpenSDK/WXApi.h>
#elif __has_include("WXApi.h")
    #import "WXApi.h"
#endif

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
    #import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
    #import "MBProgressHUD.h"
#endif

#ifdef DEBUG
    #define YHWXDebugLog(format, ...)  printf("👉👉👉👉👉[WX] %s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
    #define YHWXDebugLog(format, ...)
#endif

#define kYHWXError(__msg__)            [NSError errorWithDomain:@"com.yinhe.wx.nopay" code:-1 userInfo:@{NSLocalizedDescriptionKey: __msg__}]

@implementation YHWXLoginResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.access_token = @"";
        self.expires_in = @"";
        self.refresh_token = @"";
        self.openid = @"";
        self.scope = @"";
        self.nickname = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.country = @"";
        self.headimgurl = @"";
        self.unionid = @"";
    }
    return self;
}
@end


@interface YHWXManager() <WXApiDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *appSecret;

@property (nonatomic, strong) YHWXLoginResult *result;
@property (nonatomic, copy) void(^loginCompletionBlock)(YHWXLoginResult *result);
@property (nonatomic, copy) void(^shareCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^payCompletionBlock)(BOOL isSuccess);

#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
@property (nonatomic, strong) MBProgressHUD *hud;
#endif

@property (nonatomic, assign) BOOL sdkFlag;

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

- (void)loginWithViewController:(UIViewController *)viewController
                        showHUD:(BOOL)showHUD
                completionBlock:(void (^)(YHWXLoginResult * _Nullable))completionBlock{
    if (!self.appID) {
        YHWXDebugLog(@"[登录] appID为空");
        if (completionBlock) {
            completionBlock(nil);
        }
        return;
    }
    if (!self.appSecret) {
        YHWXDebugLog(@"[登录] appSecret为空");
        if (completionBlock) {
            completionBlock(nil);
        }
        return;
    }
    self.sdkFlag = NO;
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        // shou HUD.
        [self _showHUD];
    }
    // associated block.
    self.loginCompletionBlock = completionBlock;
    // init result.
    self.result = [[YHWXLoginResult alloc] init];
    //
    SendAuthReq *rq = [[SendAuthReq alloc] init];
    rq.scope = @"snsapi_userinfo";
    rq.state = [NSUUID UUID].UUIDString;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendAuthReq:rq viewController:viewController delegate:self];
    });
}
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
             thumbImage:(UIImage *)thumbImage
              shareType:(YHWXShareType)shareType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    if (!self.appID) {
        YHWXDebugLog(@"[分享] appID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        // shou HUD.
        [self _showHUD];
    }
    self.sdkFlag = NO;
    // associated block.
    self.shareCompletionBlock = completionBlock;
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:req];
    });
}

- (void)payWithPartnerID:(NSString *)partnerID secretKey:(NSString *)secretKey prepayID:(NSString *)prepayID showHUD:(BOOL)showHUD comletionBlock:(void (^)(BOOL))completionBlock{
    if (!self.appID) {
        YHWXDebugLog(@"[支付] appID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!partnerID) {
        YHWXDebugLog(@"[支付] partnerID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!secretKey) {
        YHWXDebugLog(@"[支付] secretKey为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!prepayID) {
        YHWXDebugLog(@"[支付] prepayID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        // shou HUD.
        [self _showHUD];
    }
    self.sdkFlag = NO;
    
    // associated block.
    self.payCompletionBlock = completionBlock;
    
    int timestamp = [[self _currentTimestamp] intValue];
    NSString *package = @"Sign=WXPay";
    NSString *noncestr = [self _gen32NonceString];
    
    NSDictionary *param = @{@"appid":self.appID,
                            @"partnerid":partnerID,
                            @"prepayid":prepayID,
                            @"package":package,
                            @"noncestr":noncestr,
                            @"timestamp":[NSString stringWithFormat:@"%d",(int)timestamp]};
    
    NSString *sign = [self _genSignWithSecretKey:secretKey param:param];
    
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = partnerID;
    request.prepayId = prepayID;
    request.package = package;
    request.nonceStr = noncestr;
    request.timeStamp = timestamp;
    request.sign = sign;
    dispatch_async(dispatch_get_main_queue(), ^{
       [WXApi sendReq:request];
    });
}


- (void)payWithPartnerID:(NSString *)partnerID prepayID:(NSString *)prepayID sign:(NSString *)sign nonceStr:(NSString *)nonceStr timeStamp:(NSString *)timeStamp showHUD:(BOOL)showHUD comletionBlock:(void (^)(BOOL))completionBlock{
    if (!self.appID) {
        YHWXDebugLog(@"[支付] appID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!partnerID) {
        YHWXDebugLog(@"[支付] partnerID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!prepayID) {
        YHWXDebugLog(@"[支付] prepayID为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!sign) {
        YHWXDebugLog(@"[支付] sign为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!nonceStr) {
        YHWXDebugLog(@"[支付] nonceStr为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (!timeStamp) {
        YHWXDebugLog(@"[支付] timeStamp为空");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        // shou HUD.
        [self _showHUD];
    }
    self.sdkFlag = NO;
    // associated block.
    self.payCompletionBlock = completionBlock;
    
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = partnerID;
    request.prepayId = prepayID;
    request.package = @"Sign=WXPay";
    request.nonceStr = nonceStr;
    request.timeStamp = [timeStamp intValue];
    request.sign = sign;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:request];
    });
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHWXDebugLog(@"applicationWillEnterForeground");
    [self _hideHUDWithCompletionBlock:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHWXDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHWXDebugLog(@"applicationDidBecomeActive");
    if (self.sdkFlag) {
        return;
    }
    [self _hideHUDWithCompletionBlock:nil];
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
        if (response.errCode == WXSuccess) {
            self.sdkFlag = YES;
            [self _hideHUDWithCompletionBlock:nil];
            [self _showHUD];
            NSString *responseCode = response.code;
            [self _requestAccessTokenWithCode:responseCode];
        } else if (response.errCode == WXErrCodeCommon ||
                   response.errCode == WXErrCodeUserCancel ||
                   response.errCode == WXErrCodeSentFail ||
                   response.errCode == WXErrCodeAuthDeny ||
                   response.errCode == WXErrCodeUnsupport) {
            [self _loginResult:nil];
        }
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        // 分享
        SendMessageToWXResp *response = (SendMessageToWXResp *)resp;
        YHWXDebugLog(@"[onResp] [SendMessageToWXResp] [errCode] %d", response.errCode);
        if (response.errCode == WXSuccess) {
            [self _shareResult:YES];
        } else if (response.errCode == WXErrCodeCommon ||
                   response.errCode == WXErrCodeUserCancel ||
                   response.errCode == WXErrCodeSentFail ||
                   response.errCode == WXErrCodeAuthDeny ||
                   response.errCode == WXErrCodeUnsupport) {
            [self _shareResult:NO];
        }
    } else if ([resp isKindOfClass:[PayResp class]]) {
        // 支付
        PayResp *response = (PayResp *)resp;
        YHWXDebugLog(@"[onResp] [PayResp] [errCode] %d", response.errCode);
        if (response.errCode == WXSuccess) {
            [self _payResult:YES];
        } else if (response.errCode == WXErrCodeCommon ||
                   response.errCode == WXErrCodeUserCancel ||
                   response.errCode == WXErrCodeSentFail ||
                   response.errCode == WXErrCodeAuthDeny ||
                   response.errCode == WXErrCodeUnsupport) {
            [self _payResult:NO];
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
    __weak typeof(self) weak_self = self;
    [YHWXManager _requestWithURL:url completionBlock:^(id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            YHWXDebugLog(@"[_requestAccessTokenWithCode] [error] %@", error);
        }
        if (responseObject) {
            YHWXDebugLog(@"[_requestAccessTokenWithCode] [responseObject] %@", responseObject);
        }
        if (!error && responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *infoDic = (NSDictionary *)responseObject;
            if ([infoDic.allKeys containsObject:@"errcode"]) {
                // 失败
                [weak_self _loginResult:nil];
            } else {
                // 成功
                if ([infoDic.allKeys containsObject:@"access_token"]) {
                    weak_self.result.access_token = [NSString stringWithFormat:@"%@",infoDic[@"access_token"]];
                }
                if ([infoDic.allKeys containsObject:@"expires_in"]) {
                    weak_self.result.expires_in = [NSString stringWithFormat:@"%@",infoDic[@"expires_in"]];
                }
                if ([infoDic.allKeys containsObject:@"refresh_token"]) {
                    weak_self.result.refresh_token = [NSString stringWithFormat:@"%@",infoDic[@"refresh_token"]];
                }
                if ([infoDic.allKeys containsObject:@"openid"]) {
                    weak_self.result.openid = [NSString stringWithFormat:@"%@",infoDic[@"openid"]];
                }
                if ([infoDic.allKeys containsObject:@"scope"]) {
                    weak_self.result.scope = [NSString stringWithFormat:@"%@",infoDic[@"scope"]];
                }
                // 成功获取access_token之后获取用户信息
                [weak_self _requestUserInfo];
            }
        } else {
            // 失败
            [weak_self _loginResult:nil];
        }
    }];
}

// 通过access_token和openid获取用户信息.
- (void)_requestUserInfo{
    __weak typeof(self) weak_self = self;
    // 加上下面几个判断，只是为了保险，按照正常逻辑，如果程序走到这儿，一般是不会出错的
    if (!self.result) {
        [self _loginResult:nil];
        return;
    }
    if (!self.result.access_token) {
        [self _loginResult:nil];
        return;
    }
    if (!self.result.openid) {
        [self _loginResult:nil];
        return;
    }
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", self.result.access_token, self.result.openid];
    [YHWXManager _requestWithURL:url completionBlock:^(id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            YHWXDebugLog(@"[_requestUserInfo] [error] %@", error);
        }
        if (responseObject) {
            YHWXDebugLog(@"[_requestUserInfo] [responseObject] %@", responseObject);
        }
        if (!error && responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *infoDic = (NSDictionary *)responseObject;
            if ([infoDic.allKeys containsObject:@"errcode"]) {
                // 失败
                [weak_self _loginResult:nil];
            } else {
                // 成功
                if ([infoDic.allKeys containsObject:@"nickname"]) {
                    weak_self.result.nickname = [NSString stringWithFormat:@"%@",infoDic[@"nickname"]];
                }
                if ([infoDic.allKeys containsObject:@"sex"]) {
                    NSString *sex = [NSString stringWithFormat:@"%@",infoDic[@"sex"]];
                    NSString *regex = @"[0-9]*";
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
                    BOOL res = [pred evaluateWithObject:sex];
                    if (res) {
                        weak_self.result.sex = [sex intValue];
                    } else {
                        weak_self.result.sex = 0;
                    }
                }
                if ([infoDic.allKeys containsObject:@"province"]) {
                    weak_self.result.province = [NSString stringWithFormat:@"%@",infoDic[@"province"]];
                }
                if ([infoDic.allKeys containsObject:@"city"]) {
                    weak_self.result.city = [NSString stringWithFormat:@"%@",infoDic[@"city"]];
                }
                if ([infoDic.allKeys containsObject:@"country"]) {
                    weak_self.result.country = [NSString stringWithFormat:@"%@",infoDic[@"country"]];
                }
                if ([infoDic.allKeys containsObject:@"headimgurl"]) {
                    weak_self.result.headimgurl = [NSString stringWithFormat:@"%@",infoDic[@"headimgurl"]];
                }
                if ([infoDic.allKeys containsObject:@"unionid"]) {
                    weak_self.result.unionid = [NSString stringWithFormat:@"%@",infoDic[@"unionid"]];
                }
                // 程序走到这儿，说明微信登录成功获取到了用户信息
                [weak_self _loginResult:weak_self.result];
            }
        } else {
            // 失败
            [weak_self _loginResult:nil];
        }
    }];
}


// 生成32位随机字符串
- (NSString *)_gen32NonceString {
    NSArray *sampleArray = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
                             @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",
                             @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T",
                             @"U", @"V", @"W", @"X", @"Y", @"Z"];
    NSMutableString *randomString = [NSMutableString string];
    for (NSInteger i = 0; i < 32; ++i) {
        [randomString appendString:sampleArray[random() % 32]];
    }
    return randomString;
}

// 生成签名    secretKey:商户平台设置的密钥key(不是appSecret)
- (NSString *)_genSignWithSecretKey:(NSString *)secretKey param:(NSDictionary *)param{
    NSMutableString *stringA = [NSMutableString string];
    // 按字典key升序排序
    NSArray *sortKeys = [[param allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // 拼接格式 “key0=value0&key1=value1&key2=value2”
    for (NSString *key in sortKeys) {
        [stringA appendString:[NSString stringWithFormat:@"%@=%@&", key, param[key]]];
    }
    // 拼接商户签名,,,,kShopSign 要和微信平台上填写的密钥一样，（密钥就是签名）
    [stringA appendString:[NSString stringWithFormat:@"key=%@", secretKey]];
    // MD5加密
    NSString *stringB = [self _MD5:stringA];
    // 返回大写字母
    return stringB.uppercaseString;
}

// MD5
- (NSString *)_MD5:(NSString *)string{
    if (!string) {
        return @"";
    }
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    return outputString;
}

// 获取当前时间戳
- (NSString *)_currentTimestamp{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%ld", (long)interval];
}

//
- (void)_loginResult:(YHWXLoginResult *)result{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginCompletionBlock) {
            self.loginCompletionBlock(result);
        }
        // 回调之后，把result置为nil，避免内存占用
        self.result = nil;
        self.loginCompletionBlock = nil;
    });
    [self _hideHUDWithCompletionBlock:^{
        [weak_self _nilHUD];
    }];
    [self _removeObserve];
}

//
- (void)_shareResult:(BOOL)result{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.shareCompletionBlock) {
            self.shareCompletionBlock(result);
        }
        self.shareCompletionBlock = nil;
    });
    [self _hideHUDWithCompletionBlock:^{
        [weak_self _nilHUD];
    }];
    [self _removeObserve];
}

//
- (void)_payResult:(BOOL)result{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.payCompletionBlock) {
            self.payCompletionBlock(result);
        }
        self.payCompletionBlock = nil;
    });
    [self _hideHUDWithCompletionBlock:^{
        [weak_self _nilHUD];
    }];
    [self _removeObserve];
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
