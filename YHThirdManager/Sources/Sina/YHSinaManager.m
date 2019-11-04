//
//  YHSinaManager.m
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHSinaManager.h"

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
#import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
#import "MBProgressHUD.h"
#endif

#import "YHThirdDefine.h"
#import "YHThirdHttpRequest.h"

#define kGetUserInfoAPI            @"https://api.weibo.com/2/users/show.json"
#define kCommentWeiBoAPI           @"https://api.weibo.com/2/comments/create.json"
#define kMineWeiBoListAPI          @"https://api.weibo.com/2/statuses/user_timeline.json"


@interface YHSinaManager ()
#if __has_include(<Weibo_SDK/WeiboSDK.h>)
<WeiboSDKDelegate>
#endif

#if __has_include(<Weibo_SDK/WeiboSDK.h>)
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, strong) WBAuthorizeResponse *authorizeResponse;
@property (nonatomic, strong) YHSinaUserInfo *userInfo;
#endif

#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
@property (nonatomic, strong) MBProgressHUD *authHUD;
@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareWebHUD;
@property (nonatomic, strong) MBProgressHUD *commentWeiBoHUD;
@property (nonatomic, strong) MBProgressHUD *mineWeiBoListHUD;
#endif

@property (nonatomic, copy) void(^authCompletionBlock)(BOOL);
@property (nonatomic, copy) void(^shareWebCompletionBlock)(BOOL isSuccess);

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

#if __has_include(<Weibo_SDK/WeiboSDK.h>)
#pragma mark Init
- (void)initWithAppID:(NSString *)appID
          redirectURI:(NSString *)redirectURI{
    if (!appID) {
        YHThirdDebugLog(@"[Sina] [初始化] appID为空");
        return;
    }
    if (!redirectURI) {
        YHThirdDebugLog(@"[Sina] [初始化] redirectURI为空");
        return;
    }
    self.appID = appID;
    self.redirectURI = redirectURI;
    [WeiboSDK registerApp:appID];
}

- (void)handleOpenURL:(NSURL *)URL{
    [WeiboSDK handleOpenURL:URL delegate:self];
}

#pragma mark Auth
- (void)authWithShowHUD:(BOOL)showHUD
        completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.appID) {
            YHThirdDebugLog(@"[Sina] [授权] appID为空");
            return;
        }
        if (!self.redirectURI) {
            YHThirdDebugLog(@"[Sina] [授权] redirectURI为空");
            return;
        }
        self.sdkFlag = NO;
        if (showHUD && [WeiboSDK isWeiboAppInstalled]) {
            [self _removeObserve];
            [self _addObserve];
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            self.authHUD = [self getHUD];
#endif
        }
        self.authCompletionBlock = completionBlock;
        
        WBAuthorizeRequest *authorizeRequest = [[WBAuthorizeRequest alloc] init];
        authorizeRequest.redirectURI = self.redirectURI;
        authorizeRequest.shouldShowWebViewForAuthIfCannotSSO = YES;
        authorizeRequest.scope = @"all";
        
        BOOL result = [WeiboSDK sendRequest:authorizeRequest];
        if (!result) {
            self.authorizeResponse = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO);
                }
                self.authCompletionBlock = nil;
            });
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [self _hideHUD:self.authHUD];
#endif
            [self _removeObserve];
        }
    });
}

#pragma mark Share(分享这儿还需要再次处理下)
- (void)shareWithTitle:(NSString *)title
                   url:(NSString *)url
           description:(NSString *)description
        thumbImageData:(NSData *)thumbImageData
               showHUD:(BOOL)showHUD
       completionBlock:(void (^)(BOOL))completionBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.redirectURI) {
            YHThirdDebugLog(@"[Sina] [分享] redirectURI为空");
            return;
        }
        if (showHUD && [WeiboSDK isWeiboAppInstalled]) {
            [self _removeObserve];
            [self _addObserve];
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            self.shareWebHUD = [self getHUD];
#endif
        }
        self.sdkFlag = NO;
        self.shareWebCompletionBlock = completionBlock;
        
        WBWebpageObject *webpageObject = [WBWebpageObject object];
        webpageObject.webpageUrl = url;
        webpageObject.title = title;
        webpageObject.description = description;
        webpageObject.thumbnailData = thumbImageData;
        webpageObject.objectID = [NSUUID UUID].UUIDString;
        
        WBMessageObject *messageObject = [[WBMessageObject alloc] init];
        messageObject.text = description;
        messageObject.mediaObject = webpageObject;
        
        WBAuthorizeRequest *authorizeRequest = [WBAuthorizeRequest request];
        authorizeRequest.scope = @"all";
        authorizeRequest.redirectURI = self.redirectURI;
        
        WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:messageObject authInfo:authorizeRequest access_token:nil];
        
        BOOL result = [WeiboSDK sendRequest:request];
        if (!result) {
            if (completionBlock) {
                completionBlock(NO);
            }
            self.shareWebCompletionBlock = nil;
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [self _hideHUD:self.shareWebHUD];
#endif
        }
    });
}

#endif

#pragma mark Get User Info
- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                            userID:(NSString *)userID
                           showHUD:(BOOL)showHUD
                   completionBlock:(void (^)(void))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
            weakSelf.getUserInfoHUD = [weakSelf getHUD];
        }
        
        NSDictionary *param = @{@"access_token": accessToken,
                                @"uid": userID};
        YHThirdDebugLog(@"[Sina] [获取个人信息参数] %@", param);
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kGetUserInfoAPI method:YHThirdHttpRequestMethodGET parameter:param successBlock:^(id  _Nonnull responseObject) {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                YHThirdDebugLog(@"[Sina] [获取个人信息失败] [数据格式不正确] %@", responseObject);
                weakSelf.userInfo = nil;
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
                [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionBlock) {
                        completionBlock();
                    }
                });
                return ;
            }
            
            YHThirdDebugLog(@"[Sina] [获取个人信息成功] %@", responseObject);
            
            NSDictionary *infoDic = (NSDictionary *)responseObject;
            
            YHSinaUserInfo *userInfo = [[YHSinaUserInfo alloc] init];
            
            userInfo.originInfo = responseObject;
            
            if ([infoDic.allKeys containsObject:@"screen_name"]) {
                userInfo.nickName = [NSString stringWithFormat:@"%@", infoDic[@"screen_name"]];
            }
            if ([infoDic.allKeys containsObject:@"gender"]) {
                NSString *gender = [NSString stringWithFormat:@"%@", infoDic[@"gender"]];
                if ([gender isEqualToString:@"m"]) {
                    userInfo.sex = 1;
                } else if ([gender isEqualToString:@"f"]) {
                    userInfo.sex = 2;
                } else {
                    userInfo.sex = 0;
                }
            }
            if ([infoDic.allKeys containsObject:@"province"]) {
                userInfo.province = [NSString stringWithFormat:@"%@", infoDic[@"province"]];
            }
            if ([infoDic.allKeys containsObject:@"city"]) {
                userInfo.city = [NSString stringWithFormat:@"%@", infoDic[@"city"]];
            }
            if ([infoDic.allKeys containsObject:@"avatar_large"]) {
                userInfo.headImgURL = [NSString stringWithFormat:@"%@", infoDic[@"avatar_large"]];
            }
            
            weakSelf.userInfo = userInfo;
            
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock();
                }
            });
            
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[Sina] [获取个人信息失败] %@", error);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.getUserInfoHUD];
#endif
            weakSelf.userInfo = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock();
                }
            });
        }];
    });
}

#pragma mark Comment WeiBo
- (void)commentWeiBoWithAccessToken:(NSString *)accessToken
                                 ID:(NSString *)ID
                            comment:(NSString *)comment
        isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                            showHUD:(BOOL)showHUD
                    completionBlock:(void (^)(NSDictionary * _Nullable))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            weakSelf.commentWeiBoHUD = [weakSelf getHUD];
#endif
        }
        NSDictionary *param = @{@"access_token" : accessToken ? accessToken : @"",
                                @"comment" : comment ? comment : @"",
                                @"id" : ID ? ID : @"",
                                @"comment_ori" : isCommentOriginWhenTransfer ? @"1" : @"0"};
        YHThirdDebugLog(@"[Sina] [评论指定微博参数] %@", param);
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kCommentWeiBoAPI method:YHThirdHttpRequestMethodPOST parameter:param successBlock:^(id  _Nonnull responseObject) {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                YHThirdDebugLog(@"[Sina] [评论指定微博失败] 数据格式错误 %@", responseObject);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
                [weakSelf _hideHUD:weakSelf.commentWeiBoHUD];
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionBlock) {
                        completionBlock(nil);
                    }
                });
                return ;
            }
            
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.commentWeiBoHUD];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(responseObject);
                }
            });
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[Sina] [评论指定微博失败] %@", error);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.commentWeiBoHUD];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(nil);
                }
            });
        }];
    });
}


- (void)commentWeiBoWithID:(NSString *)ID
                   comment:(NSString *)comment{
    NSString *url = @"";
    if (!comment || comment.length == 0 || [comment isEqualToString:@""]) {
        url = [NSString stringWithFormat:@"sinaweibo://comment?srcid=%@", ID];
    } else {
        url = [NSString stringWithFormat:@"sinaweibo://comment?srcid=%@&content=%@", ID, comment];
    }
    NSURL *URL = [NSURL URLWithString:[[YHThirdHttpRequest sharedInstance] urlTranscoding:url]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] canOpenURL:URL]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:URL];
            }
        } else {
            YHThirdDebugLog(@"[Sina] [评论指定微博] [用户没有安装微博客户端]");
        }
    });
}

#pragma mark Get Wy WebiBo
- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken
                                 userID:(NSString *)userID
                               perCount:(int)perCount
                                curPage:(int)curPage
                                showHUD:(BOOL)showHUD
                        completionBlock:(void (^)(NSDictionary * _Nullable))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            weakSelf.mineWeiBoListHUD = [weakSelf getHUD];
#endif
        }
        
        NSDictionary *param = @{@"access_token" : accessToken,
                                @"uid" : userID,
                                @"count" : [NSString stringWithFormat:@"%d", perCount],
                                @"page" : [NSString stringWithFormat:@"%d", curPage]};
        YHThirdDebugLog(@"[Sina] [获取我的微博参数] %@", param);
        
        [[YHThirdHttpRequest sharedInstance] requestWithURL:kMineWeiBoListAPI method:YHThirdHttpRequestMethodGET parameter:param successBlock:^(id  _Nonnull responseObject) {
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                YHThirdDebugLog(@"[Sina] [获取我的微博失败] [数据格式不正确] %@", responseObject);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
                [weakSelf _hideHUD:weakSelf.mineWeiBoListHUD];
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionBlock) {
                        completionBlock(nil);
                    }
                });
                return ;
            }
            YHThirdDebugLog(@"[Sina] [获取我的微博成功] %@", responseObject);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.mineWeiBoListHUD];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(responseObject);
                }
            });
            
        } failureBlock:^(NSError * _Nonnull error) {
            YHThirdDebugLog(@"[Sina] [获取我的微博失败] %@", error);
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
            [weakSelf _hideHUD:weakSelf.mineWeiBoListHUD];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(nil);
                }
            });
        }];
    });
}


#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHThirdDebugLog(@"[Sina] applicationWillEnterForeground");
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
    [self _hideHUD:self.authHUD];
    [self _hideHUD:self.shareWebHUD];
#endif
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHThirdDebugLog(@"[Sina] applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHThirdDebugLog(@"[Sina] applicationDidBecomeActive");
    if (self.sdkFlag) {
        return;
    }
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
    [self _hideHUD:self.authHUD];
    [self _hideHUD:self.shareWebHUD];
#endif
}

#pragma mark <WeiboSDKDelegate>
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request{
    YHThirdDebugLog(@"[Sina] [didReceiveWeiboRequest] [request] %@ [userInfo] %@", request, request.userInfo);
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response{
    YHThirdDebugLog(@"[Sina] [didReceiveWeiboResponse] [response] %@ [statusCode] %d", response, (int)response.statusCode);
    if ([response isKindOfClass:[WBAuthorizeResponse class]]) {
        // 授权
        WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
        BOOL isSuccess = authorizeResponse.statusCode == WeiboSDKResponseStatusCodeSuccess;
        self.authorizeResponse = isSuccess ? authorizeResponse : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.authCompletionBlock) {
                self.authCompletionBlock(isSuccess);
            }
            self.authCompletionBlock = nil;
        });
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
        [self _hideHUD:self.authHUD];
#endif
        [self _removeObserve];
    } else if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        // 分享
        WBSendMessageToWeiboResponse *sendMessageToWeiboResponse = (WBSendMessageToWeiboResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.shareWebCompletionBlock) {
                self.shareWebCompletionBlock(sendMessageToWeiboResponse.statusCode == WeiboSDKResponseStatusCodeSuccess ? YES : NO);
            }
            self.shareWebCompletionBlock = nil;
        });
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
        [self _hideHUD:self.shareWebHUD];
#endif
        [self _removeObserve];
    }
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
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
- (MBProgressHUD *)getHUD{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];//必须在主线程，源码规定
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.contentColor = [UIColor whiteColor];
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    hud.removeFromSuperViewOnHide = YES;
    return hud;
}
#endif

// 隐藏HUD
#if __has_include(<MBProgressHUD/MBProgressHUD.h>) || __has_include("MBProgressHUD.h")
- (void)_hideHUD:(MBProgressHUD *)hud{
    if (!hud) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
    });
}
#endif
@end

