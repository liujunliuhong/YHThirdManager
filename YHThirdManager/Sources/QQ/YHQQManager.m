//
//  YHQQManager.m
//  QAQSmooth
//
//  Created by apple on 2019/3/8.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHQQManager.h"
#import "YHThirdDefine.h"
#import "YHThirdHttpRequest.h"

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
#import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
#import "MBProgressHUD.h"
#endif

#define kGetUserInfoAPI    @"https://graph.qq.com/user/get_user_info"

@interface YHQQManager()<TencentSessionDelegate, QQApiInterfaceDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) TencentOAuth *oauth;
@property (nonatomic, strong) YHQQUserInfo *userInfo;

@property (nonatomic, strong) MBProgressHUD *authHUD;
@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareHUD;

@property (nonatomic, copy) void(^authComplectionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^shareComplectionBlock)(BOOL isSuccess);

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

#pragma mark Init
- (void)initWithAppID:(NSString *)appID universalLink:(NSString *)universalLink{
    if (self.oauth) {
        self.oauth = nil;
    }
    if (!appID || appID.length <= 0) {
        YHThirdDebugLog(@"[QQ] [初始化] appID为空");
        return;
    }
    self.appID = appID;
    if (universalLink && universalLink.length > 0) {
        self.oauth = [[TencentOAuth alloc] initWithAppId:appID andUniversalLink:universalLink andDelegate:self];
    } else {
        self.oauth = [[TencentOAuth alloc] initWithAppId:appID andDelegate:self];
    }
}

- (void)handleOpenURL:(NSURL *)URL{
    [TencentOAuth HandleOpenURL:URL];
    [QQApiInterface handleOpenURL:URL delegate:self];
}

- (void)handleUniversalLink:(NSURL *)universalLink{
    [TencentOAuth HandleUniversalLink:universalLink];
    [QQApiInterface handleOpenUniversallink:universalLink delegate:self];
}

#pragma mark Auth
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _removeObserve];
        if (!self.appID) {
            YHThirdDebugLog(@"[QQ] [授权] appID为空");
            return;
        }
        if (showHUD && [QQApiInterface isQQInstalled]) { // 此处做了个判断：只有安装了QQ,才会显示HUD，否则不显示
            [self _addObserve];
            self.authHUD = YHThird_GetHud;
        }
        self.authComplectionBlock = completionBlock;
        
        NSArray *permissions = @[kOPEN_PERMISSION_GET_INFO,
                                 kOPEN_PERMISSION_GET_USER_INFO,
                                 kOPEN_PERMISSION_GET_SIMPLE_USER_INFO];
        BOOL result = [self.oauth authorize:permissions];
        if (result) {
            return;
        }
        YHThirdDebugLog(@"[QQ] [授权] 授权失败");
        if (completionBlock) {
            completionBlock(NO);
        }
        self.authComplectionBlock = nil;
        YHThird_HideHud(self.authHUD);
        self.authHUD = nil;
        [self _removeObserve];
    });
}

#pragma mark Get User Info
- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                             appID:(NSString *)appID
                            openId:(NSString *)openId
                         isShowHUD:(BOOL)showHUD
                   completionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _removeObserve];
        NSDictionary *param = @{@"access_token": accessToken ? accessToken : @"",
                                @"oauth_consumer_key": appID ? appID : @"",
                                @"openid": openId ? openId : @""};
        YHThirdDebugLog(@"[QQ] [获取个人信息参数] %@", param);
        if (showHUD) {
            weakSelf.getUserInfoHUD = YHThird_GetHud;
        }
        
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kGetUserInfoAPI method:YHThirdHttpRequestMethodGET parameter:param successBlock:^(id  _Nonnull responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf _removeObserve];
                if (![responseObject isKindOfClass:[NSDictionary class]]) {
                    YHThirdDebugLog(@"[QQ] [获取个人信息失败] [数据格式不正确] %@", responseObject);
                    weakSelf.userInfo = nil;
                    YHThird_HideHud(weakSelf.getUserInfoHUD);
                    weakSelf.getUserInfoHUD = nil;
                    if (completionBlock) {
                        completionBlock(NO);
                    }
                    return ;
                }
                
                YHThirdDebugLog(@"[QQ] [获取个人信息成功] %@", responseObject);
                
                NSDictionary *infoDic = (NSDictionary *)responseObject;
                
                YHQQUserInfo *result = [[YHQQUserInfo alloc] init];
                
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
                weakSelf.userInfo = result;
                YHThird_HideHud(weakSelf.getUserInfoHUD);
                weakSelf.getUserInfoHUD = nil;
                if (completionBlock) {
                    completionBlock(YES);
                }
            });
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[QQ] [获取个人信息失败] %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf _removeObserve];
                YHThird_HideHud(weakSelf.getUserInfoHUD);
                weakSelf.getUserInfoHUD = nil;
                weakSelf.userInfo = nil;
                
                if (completionBlock) {
                    completionBlock(NO);
                }
            });
        }];
    });
}


#pragma mark Share
- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
          thumbImageURL:(NSString *)thumbImageURL
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _removeObserve];
        if (!self.appID || self.appID.length <= 0) {
            YHThirdDebugLog(@"[QQ] [分享] appID为空");
            return;
        }
        if (showHUD && [QQApiInterface isQQInstalled]) {
            [self _addObserve];
            self.shareHUD = YHThird_GetHud;
        }
        self.shareComplectionBlock = completionBlock;
        
    QQApiNewsObject *object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:URL] title:title description:description previewImageURL:thumbImageURL ? [NSURL URLWithString:thumbImageURL] : nil];
        
        ShareDestType destType = ShareDestTypeQQ;
        if (shareDestType == YHQQShareDestType_QQ) {
            destType = ShareDestTypeQQ;
        } else if (shareDestType == YHQQShareDestType_TIM) {
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
        
        YHThirdDebugLog(@"[QQ] [分享] [QQApiSendResultCode] %d", (int)sendResultCode);
        if (sendResultCode == EQQAPISENDSUCESS) {
            return;
        }
        if (completionBlock) {
            completionBlock(NO);
        }
        self.shareComplectionBlock = nil;
        YHThird_HideHud(self.shareHUD);
        self.shareHUD = nil;
        [self _removeObserve];
    });
}

- (void)shareWebWithURL:(NSString *)URL
                  title:(NSString *)title
            description:(NSString *)description
         thumbImageData:(NSData *)thumbImageData
              shareType:(YHQQShareType)shareTye
          shareDestType:(YHQQShareDestType)shareDestType
                showHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _removeObserve];
        if (!self.appID) {
            YHThirdDebugLog(@"[QQ] [分享] appID为空");
            return;
        }
        if (showHUD && [QQApiInterface isQQInstalled]) {
            [self _addObserve];
            self.shareHUD = YHThird_GetHud;
        }
        self.shareComplectionBlock = completionBlock;
        
        QQApiNewsObject *object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:URL] title:title description:description previewImageData:thumbImageData];
        
        ShareDestType destType = ShareDestTypeQQ;
        if (shareDestType == YHQQShareDestType_QQ) {
            destType = ShareDestTypeQQ;
        } else if (shareDestType == YHQQShareDestType_TIM) {
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
        YHThirdDebugLog(@"[QQ] [分享] [QQApiSendResultCode] %d", (int)sendResultCode);
        if (sendResultCode == EQQAPISENDSUCESS) {
            return;
        }
        if (completionBlock) {
            completionBlock(NO);
        }
        self.shareComplectionBlock = nil;
        YHThird_HideHud(self.shareHUD);
        self.shareHUD = nil;
        [self _removeObserve];
    });
}

- (void)shareImageWithImageData:(NSData *)imageData
                 thumbImageData:(NSData *)thumbImageData
                          title:(NSString *)title
                    description:(NSString *)description
                  shareDestType:(YHQQShareDestType)shareDestType
                        showHUD:(BOOL)showHUD
                completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _removeObserve];
        if (!self.appID) {
            YHThirdDebugLog(@"[QQ] [分享] appID为空");
            return;
        }
        if (showHUD && [QQApiInterface isQQInstalled]) {
            [self _addObserve];
            self.shareHUD = YHThird_GetHud;
        }
        self.shareComplectionBlock = completionBlock;
        
        QQApiImageObject *imageObject = [QQApiImageObject objectWithData:imageData previewImageData:thumbImageData title:title description:description];
        
        ShareDestType destType = ShareDestTypeQQ;
        if (shareDestType == YHQQShareDestType_QQ) {
            destType = ShareDestTypeQQ;
        } else if (shareDestType == YHQQShareDestType_TIM) {
            destType = ShareDestTypeTIM;
        }
        imageObject.shareDestType = destType;
        
        SendMessageToQQReq *rq = [SendMessageToQQReq reqWithContent:imageObject];
        
        QQApiSendResultCode sendResultCode = [QQApiInterface sendReq:rq];
        YHThirdDebugLog(@"[QQ] [分享] [QQApiSendResultCode] %d", (int)sendResultCode);
        if (sendResultCode == EQQAPISENDSUCESS) {
            return;
        }
        if (completionBlock) {
            completionBlock(NO);
        }
        self.shareComplectionBlock = nil;
        YHThird_HideHud(self.shareHUD);
        self.shareHUD = nil;
        [self _removeObserve];
    });
}

#pragma mark <TencentLoginDelegate>
// 登录成功后的回调.
- (void)tencentDidLogin {
    YHThirdDebugLog(@"[QQ] [授权] [TencentLoginDelegate] tencentDidLogin");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.authComplectionBlock) {
            self.authComplectionBlock(YES);
        }
        self.authComplectionBlock = nil;
        YHThird_HideHud(self.authHUD);
        self.authHUD = nil;
        [self _removeObserve];
    });
}

// 授权失败后的回调.
- (void)tencentDidNotLogin:(BOOL)cancelled {
    YHThirdDebugLog(@"[QQ] [授权] [TencentLoginDelegate] tencentDidNotLogin");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.authComplectionBlock) {
            self.authComplectionBlock(NO);
        }
        self.authComplectionBlock = nil;
        YHThird_HideHud(self.authHUD);
        self.authHUD = nil;
        [self _removeObserve];
    });
}

// 授权时网络有问题的回调.
- (void)tencentDidNotNetWork {
    YHThirdDebugLog(@"[QQ] [授权] [TencentLoginDelegate] tencentDidNotNetWork");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.authComplectionBlock) {
            self.authComplectionBlock(NO);
        }
        self.authComplectionBlock = nil;
        YHThird_HideHud(self.authHUD);
        self.authHUD = nil;
        [self _removeObserve];
    });
}

- (void)didGetUnionID{
    YHThirdDebugLog(@"[QQ] [didGetUnionID] %@", self.oauth.unionid);
}

#pragma mark <QQApiInterfaceDelegate>
// 处理来至QQ的请求.
- (void)onReq:(QQBaseReq *)req{
    YHThirdDebugLog(@"[QQ] [QQApiInterfaceDelegate] [onReq] %@ [type] %d", req, req.type);
}

// 处理来至QQ的响应.
- (void)onResp:(QQBaseResp *)resp{
    YHThirdDebugLog(@"[QQ] [QQApiInterfaceDelegate] [onResp] %@", resp);
    if ([resp isKindOfClass:[SendMessageToQQResp class]]) {
        SendMessageToQQResp *response = (SendMessageToQQResp *)resp;
        YHThirdDebugLog(@"[QQ] [分享] [QQApiInterfaceDelegate] [onResp] [SendMessageToQQResp] [result] %@", response.result);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.shareComplectionBlock) {
                self.shareComplectionBlock([response.result isEqualToString:@"0"]);
            }
            self.shareComplectionBlock = nil;
            YHThird_HideHud(self.shareHUD);
            self.shareHUD = nil;
            [self _removeObserve];
        });
    }
}

// 处理QQ在线状态的回调.
- (void)isOnlineResponse:(NSDictionary *)response{
    YHThirdDebugLog(@"[QQ] [QQApiInterfaceDelegate] [isOnlineResponse] %@", response);
}

#pragma mark Notification
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHThirdDebugLog(@"applicationWillEnterForeground");
    //
    YHThird_HideHud(self.shareHUD);
    self.shareHUD = nil;
    //
    YHThird_HideHud(self.authHUD);
    self.authHUD = nil;
    //
    [self _removeObserve];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHThirdDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHThirdDebugLog(@"applicationDidBecomeActive");
    //
    YHThird_HideHud(self.shareHUD);
    self.shareHUD = nil;
    //
    YHThird_HideHud(self.authHUD);
    self.authHUD = nil;
    //
    [self _removeObserve];
}

@end



@implementation YHQQManager (Private)
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
