//
//  YHSinaManager.m
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHSinaManager.h"
#import <Weibo_SDK/WeiboSDK.h>

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
    #import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
    #import "MBProgressHUD.h"
#endif

#ifdef DEBUG
    #define YHSNDebugLog(format, ...)  printf("👉👉👉👉👉[Sina] %s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
    #define YHSNDebugLog(format, ...)
#endif

#define kYHSNError(__msg__)            [NSError errorWithDomain:@"com.yinhe.sn" code:-1 userInfo:@{NSLocalizedDescriptionKey: __msg__}]


@implementation YHSinaLoginResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.access_token = @"";
        self.userid = @"";
        self.expires_in = @"";
        self.nickname = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.headimgurl = @"";
    }
    return self;
}
@end




@interface YHSinaManager () <WeiboSDKDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, copy) NSString *access_token;

#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
@property (nonatomic, strong) MBProgressHUD *hud;
#endif

@property (nonatomic, strong) YHSinaLoginResult *result;

@property (nonatomic, copy) void(^loginCompletionBlock)(YHSinaLoginResult *result);
@property (nonatomic, copy) void(^shareCompletionBlock)(BOOL isSuccess);

@property (nonatomic, assign) BOOL sdkFlag;

@end

@implementation YHSinaManager

+ (instancetype)sharedInstance{
    static YHSinaManager *manager = nil;
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

- (void)initWithAppID:(NSString *)appID redirectURI:(NSString *)redirectURI{
    if (!appID) {
        YHSNDebugLog(@"[初始化] appID为空");
        return;
    }
    if (!redirectURI) {
        YHSNDebugLog(@"[初始化] redirectURI为空");
        return;
    }
    self.appID = appID;
    self.redirectURI = redirectURI;
    [WeiboSDK registerApp:appID];
}

- (void)handleOpenURL:(NSURL *)URL{
    if ([URL.scheme hasPrefix:@"wb"]) {
        YHSNDebugLog(@"[handleOpenURL] [URL] %@", URL);
        [WeiboSDK handleOpenURL:URL delegate:self];
    }
}

- (void)loginWithShowHUD:(BOOL)showHUD completionBlock:(void (^)(YHSinaLoginResult * _Nullable))completionBlock{
    if (!self.appID) {
        YHSNDebugLog(@"[登录] appID为空");
        return;
    }
    if (!self.redirectURI) {
        YHSNDebugLog(@"[登录] redirectURI为空");
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
    self.loginCompletionBlock = completionBlock;
    self.result = [[YHSinaLoginResult alloc] init];
    
    WBAuthorizeRequest *authorizeRequest = [[WBAuthorizeRequest alloc] init];
    authorizeRequest.redirectURI = self.redirectURI;
    authorizeRequest.shouldShowWebViewForAuthIfCannotSSO = YES;
    authorizeRequest.scope = @"all";
    dispatch_async(dispatch_get_main_queue(), ^{
       BOOL res = [WeiboSDK sendRequest:authorizeRequest];
        if (!res) {
            [self _loginResult:nil];
        }
    });
}

- (void)shareWithContent:(NSString *)content
                  images:(NSArray<UIImage *> *)images
                 showHUD:(BOOL)showHUD
         completionBlock:(void (^)(BOOL))completionBlock{
    
    if (!self.redirectURI) {
        YHSNDebugLog(@"[分享] redirectURI为空");
        return;
    }
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        // shou HUD.
        [self _showHUD];
    }
    self.sdkFlag = NO;
    self.shareCompletionBlock = completionBlock;
    
    
    WBImageObject *imageObject = [WBImageObject object];
    imageObject.isShareToStory = NO;
    if (images && images.count > 0) {
        [imageObject addImages:images];
    }
    
    WBMessageObject *messageObject = [[WBMessageObject alloc] init];
    messageObject.imageObject = imageObject;
    messageObject.text = content;
    
    WBAuthorizeRequest *authorizeRequest = [WBAuthorizeRequest request];
    authorizeRequest.scope = @"all";
    authorizeRequest.redirectURI = self.redirectURI;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:messageObject authInfo:authorizeRequest access_token:self.access_token]; // access_token传nil会分享不成功，但是如果是一个空的对象，却成功，这微博SDK真怪
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL res = [WeiboSDK sendRequest:request];
        if (!res) {
            [self _shareResult:NO];
        }
    });
}


#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHSNDebugLog(@"applicationWillEnterForeground");
    [self _hideHUDWithCompletionBlock:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHSNDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHSNDebugLog(@"applicationDidBecomeActive");
    if (self.sdkFlag) {
        return;
    }
    [self _hideHUDWithCompletionBlock:nil];
}

#pragma mark ------------------ <WeiboSDKDelegate> ------------------
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request{
    YHSNDebugLog(@"[didReceiveWeiboRequest] [request] %@ [userInfo] %@", request, request.userInfo);
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response{
    YHSNDebugLog(@"[didReceiveWeiboResponse] [response] %@ [statusCode] %d", response, (int)response.statusCode);
    if ([response isKindOfClass:[WBAuthorizeResponse class]]) {
        WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
        if (authorizeResponse.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            self.sdkFlag = YES;
            [self _hideHUDWithCompletionBlock:nil];
            [self _showHUD];
            NSString *accessToken = authorizeResponse.accessToken;
            NSString *userID = authorizeResponse.userID;
            NSTimeInterval expirationDate = [authorizeResponse.expirationDate timeIntervalSince1970];
            self.result.expires_in = [NSString stringWithFormat:@"%ld", (long)expirationDate];
            self.result.access_token = accessToken;
            [self _requestUserInfoWithUserID:userID accessToken:accessToken];
        } else {
            [self _loginResult:nil];
        }
    } else if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        WBSendMessageToWeiboResponse *sendMessageToWeiboResponse = (WBSendMessageToWeiboResponse *)response;
        if (sendMessageToWeiboResponse.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            [self _shareResult:YES];
        } else {
            [self _shareResult:NO];
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
                    completionBlock(nil, kYHSNError(@"请求失败"));
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

- (void)_requestUserInfoWithUserID:(NSString *)userID accessToken:(NSString *)accessToken{
    NSString *url = [NSString stringWithFormat:@"https://api.weibo.com/2/users/show.json?access_token=%@&uid=%@", accessToken, userID];
    __weak typeof(self) weak_self = self;
    [YHSinaManager _requestWithURL:url completionBlock:^(id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            YHSNDebugLog(@"[_requestUserInfoWithUserID:accessToken:] [error] %@", error);
        }
        if (responseObject) {
            YHSNDebugLog(@"[_requestUserInfoWithUserID:accessToken:] [responseObject] %@", responseObject);
        }
        if (!error && responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *infoDic = (NSDictionary *)responseObject;
            if ([infoDic.allKeys containsObject:@"error_code"]) {
                // 失败
                [weak_self _loginResult:nil];
            } else {
                // 成功
                if ([infoDic.allKeys containsObject:@"idstr"]) {
                    weak_self.result.userid = [NSString stringWithFormat:@"%@", infoDic[@"idstr"]];
                }
                if ([infoDic.allKeys containsObject:@"screen_name"]) {
                    weak_self.result.nickname = [NSString stringWithFormat:@"%@", infoDic[@"screen_name"]];
                }
                if ([infoDic.allKeys containsObject:@"gender"]) {
                    NSString *gender = [NSString stringWithFormat:@"%@", infoDic[@"gender"]];
                    if ([gender isEqualToString:@"m"]) {
                        weak_self.result.sex = 1;
                    } else if ([gender isEqualToString:@"f"]) {
                        weak_self.result.sex = 2;
                    } else {
                        weak_self.result.sex = 0;
                    }
                }
                if ([infoDic.allKeys containsObject:@"province"]) {
                    weak_self.result.province = [NSString stringWithFormat:@"%@", infoDic[@"province"]];
                }
                if ([infoDic.allKeys containsObject:@"city"]) {
                    weak_self.result.city = [NSString stringWithFormat:@"%@", infoDic[@"city"]];
                }
                if ([infoDic.allKeys containsObject:@"avatar_large"]) {
                    weak_self.result.headimgurl = [NSString stringWithFormat:@"%@", infoDic[@"avatar_large"]];
                }
                [weak_self _loginResult:weak_self.result];
            }
        } else {
            // 失败
            [weak_self _loginResult:nil];
        }
    }];
}

//
- (void)_loginResult:(YHSinaLoginResult *)result{
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
}
#endif
@end

