//
//  YHSinaManager.m
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHSinaManager.h"
#import <objc/message.h>

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


#define kYHSN_GetUserInfoAPI           @"https://api.weibo.com/2/users/show.json"
#define kYHSN_GetUserInfoTag           @"kYHSN_GetUserInfoTag"


#define kYHSN_CommentWeiBoAPI          @"https://api.weibo.com/2/comments/create.json"
#define kYHSN_CommentWeiBoTag          @"kYHSN_CommentWeiBoTag"


#define kYHSN_MineWeiBoListAPI         @"https://api.weibo.com/2/statuses/user_timeline.json"
#define kYHSN_MineWeiBoListTag         @"kYHSN_MineWeiBoListTag"


@implementation YHSinaLoginResult
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userID = @"";
        self.nickName = @"";
        self.sex = 0;
        self.province = @"";
        self.city = @"";
        self.headimgURL = @"";
    }
    return self;
}
@end




@interface YHSinaManager () <WeiboSDKDelegate, WBHttpRequestDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *redirectURI;

@property (nonatomic, strong) MBProgressHUD *authHUD;
@property (nonatomic, strong) MBProgressHUD *loginHUD;
@property (nonatomic, strong) MBProgressHUD *shareHUD;
@property (nonatomic, strong) MBProgressHUD *commentWeiBoHUD;
@property (nonatomic, strong) MBProgressHUD *mineWeiBoListHUD;

@property (nonatomic, copy) void(^authCompletionBlock)(WBAuthorizeResponse *authResponse);
@property (nonatomic, copy) void(^loginCompletionBlock)(YHSinaLoginResult *result);
@property (nonatomic, copy) void(^shareCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^commentWeiBoCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^mineWeiBoListCompletionBlock)(NSDictionary *responseObject);

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

- (void)authWithShowHUD:(BOOL)showHUD completionBlock:(void (^)(WBAuthorizeResponse * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    
    if (!self.appID) {
        YHSNDebugLog(@"[授权] appID为空");
        return;
    }
    if (!self.redirectURI) {
        YHSNDebugLog(@"[授权] redirectURI为空");
        return;
    }
    self.sdkFlag = NO;
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        [self getAuthHUD];
    }
    self.authCompletionBlock = completionBlock;
    
    WBAuthorizeRequest *authorizeRequest = [[WBAuthorizeRequest alloc] init];
    authorizeRequest.redirectURI = self.redirectURI;
    authorizeRequest.shouldShowWebViewForAuthIfCannotSSO = YES;
    authorizeRequest.scope = @"all";
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL res = [WeiboSDK sendRequest:authorizeRequest];
        if (!res) {
            if (completionBlock) {
                completionBlock(nil);
            }
            weakSelf.authCompletionBlock = nil;
            [weakSelf _hideHUD:weakSelf.authHUD];
            [weakSelf _removeObserve];
        }
    });
}


- (void)loginWithAccessToken:(NSString *)accessToken
                      userID:(NSString *)userID
                     showHUD:(BOOL)showHUD
             completionBlock:(void (^)(YHSinaLoginResult * _Nullable))completionBlock{
    self.sdkFlag = YES;
    if (showHUD) {
        [self getLoginHUD];
    }
    self.loginCompletionBlock = completionBlock;
    
    NSDictionary *param = @{@"access_token" : accessToken,
                            @"uid" : userID};
    
    [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_GetUserInfoAPI httpMethod:@"GET" params:param delegate:self withTag:kYHSN_GetUserInfoTag];
}

- (void)shareWithAccessToken:(NSString *)accessToken
                     content:(NSString *)content
                      images:(NSArray<UIImage *> *)images
                     showHUD:(BOOL)showHUD
             completionBlock:(void (^)(BOOL))completionBlock{
    __weak typeof(self) weakSelf = self;
    if (!self.redirectURI) {
        YHSNDebugLog(@"[分享] redirectURI为空");
        return;
    }
    if (showHUD) {
        [self _removeObserve];
        [self _addObserve];
        [self getShareHUD];
    }
    self.sdkFlag = YES;
    self.shareCompletionBlock = completionBlock;
    
    
    WBMessageObject *messageObject = [[WBMessageObject alloc] init];
    messageObject.text = content;
    
    if (images && images.count > 0) {
        WBImageObject *imageObject = [WBImageObject object];
        imageObject.isShareToStory = NO;
        [imageObject addImages:images];
        messageObject.imageObject = imageObject;
    }
    
    
    WBAuthorizeRequest *authorizeRequest = [WBAuthorizeRequest request];
    authorizeRequest.scope = @"all";
    authorizeRequest.redirectURI = self.redirectURI;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:messageObject authInfo:authorizeRequest access_token:accessToken]; // access_token传nil会分享不成功，但是如果是一个空的对象，却成功，这微博SDK真怪
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL res = [WeiboSDK sendRequest:request];
        
        if (!res) {
            [weakSelf _hideHUD:weakSelf.shareHUD];
        }
    });
}

- (void)commentWeiBoWithAccessToken:(NSString *)accessToken
                                 ID:(NSString *)ID
                            comment:(NSString *)comment
        isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                            showHUD:(BOOL)showHUD completionBlock:(void (^)(BOOL))completionBlock{
    [WeiboSDK commentToWeibo:ID];
//    
//        self.sdkFlag = YES;
//        if (showHUD) {
//            [self getCommentWeiBoHUD];
//        }
//        self.commentWeiBoCompletionBlock = completionBlock;
//    
//        NSDictionary *param = @{@"access_token" : accessToken,
//                                @"comment" : comment,
//                            @"id" : ID,
//                            @"comment_ori" : isCommentOriginWhenTransfer ? @"1" : @"0"};
//    
//    [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_CommentWeiBoAPI httpMethod:@"POST" params:param delegate:self withTag:kYHSN_CommentWeiBoTag];
}

- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken userID:(NSString *)userID perCount:(int)perCount curPage:(int)curPage showHUD:(BOOL)showHUD completionBlock:(void (^)(NSDictionary * _Nullable))completionBlock{
    self.sdkFlag = YES;
    if (showHUD) {
        [self getMineWeiBoListHUD];
    }
    self.mineWeiBoListCompletionBlock = completionBlock;
    
    NSDictionary *param = @{@"access_token" : accessToken,
                            @"uid" : userID,
                            @"count" : [NSString stringWithFormat:@"%d", perCount],
                            @"page" : [NSString stringWithFormat:@"%d", curPage]};
    
    [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_MineWeiBoListAPI httpMethod:@"GET" params:param delegate:self withTag:kYHSN_MineWeiBoListTag];
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHSNDebugLog(@"applicationWillEnterForeground");
    [self _hideHUD:self.authHUD];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti{
    YHSNDebugLog(@"applicationDidEnterBackground");
}

- (void)applicationDidBecomeActive:(NSNotification *)noti{
    YHSNDebugLog(@"applicationDidBecomeActive");
    if (self.sdkFlag) {
        return;
    }
    [self _hideHUD:self.authHUD];
}

#pragma mark ------------------ <WeiboSDKDelegate> ------------------
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request{
    YHSNDebugLog(@"[didReceiveWeiboRequest] [request] %@ [userInfo] %@", request, request.userInfo);
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response{
    YHSNDebugLog(@"[didReceiveWeiboResponse] [response] %@ [statusCode] %d", response, (int)response.statusCode);
    __weak typeof(self) weakSelf = self;
    if ([response isKindOfClass:[WBAuthorizeResponse class]]) {
        // 授权
        WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.authCompletionBlock) {
                weakSelf.authCompletionBlock(authorizeResponse.statusCode == WeiboSDKResponseStatusCodeSuccess ? authorizeResponse : nil);
            }
            weakSelf.authCompletionBlock = nil;
        });
        [self _hideHUD:self.authHUD];
        [self _removeObserve];
        
    } else if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        // 分享
        WBSendMessageToWeiboResponse *sendMessageToWeiboResponse = (WBSendMessageToWeiboResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.shareCompletionBlock) {
                weakSelf.shareCompletionBlock(sendMessageToWeiboResponse.statusCode == WeiboSDKResponseStatusCodeSuccess ? YES : NO);
            }
            weakSelf.shareCompletionBlock = nil;
        });
        [self _hideHUD:self.shareHUD];
    }
}


#pragma mark ------------------ <WBHttpRequestDelegate> ------------------
- (void)request:(WBHttpRequest *)request didReceiveResponse:(NSURLResponse *)response{
    YHSNDebugLog(@"[didReceiveResponse] [request.tag] %@ [response] %@", request.tag, response);
}

- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error{
    YHSNDebugLog(@"[didFailWithError] [request.tag] %@ [error] %@", request.tag, error);
    __weak typeof(self) weakSelf = self;
    if ([request.tag isEqualToString:kYHSN_GetUserInfoTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.loginCompletionBlock) {
                weakSelf.loginCompletionBlock(nil);
            }
            weakSelf.loginCompletionBlock = nil;
        });
        [self _hideHUD:self.loginHUD];
    } else if ([request.tag isEqualToString:kYHSN_CommentWeiBoTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.commentWeiBoCompletionBlock) {
                weakSelf.commentWeiBoCompletionBlock(NO);
            }
            weakSelf.commentWeiBoCompletionBlock = nil;
        });
        [self _hideHUD:self.commentWeiBoHUD];
    } else if ([request.tag isEqualToString:kYHSN_MineWeiBoListTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.mineWeiBoListCompletionBlock) {
                weakSelf.mineWeiBoListCompletionBlock(nil);
            }
            weakSelf.mineWeiBoListCompletionBlock = nil;
        });
        [self _hideHUD:self.mineWeiBoListHUD];
    }
}

// didFinishLoadingWithResult和didFinishLoadingWithDataResult只会走其中一个回调
- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result{
    
    YHSNDebugLog(@"[didFinishLoadingWithResult] [request.tag] %@ [result] %@", request.tag, result);
    if ([request.tag isEqualToString:kYHSN_GetUserInfoTag]) {
        [self parseUserInfo:result];
    } else if ([request.tag isEqualToString:kYHSN_CommentWeiBoTag]) {
        
    } else if ([request.tag isEqualToString:kYHSN_MineWeiBoListTag]) {
        
    }
}

//- (void)request:(WBHttpRequest *)request didFinishLoadingWithDataResult:(NSData *)data{
//    YHSNDebugLog(@"[didFinishLoadingWithDataResult] [request.tag] %@ [data] %@", request.tag, data);
//    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
//    YHSNDebugLog(@"😋😋%@", responseObject);
//}

- (void)request:(WBHttpRequest *)request didReciveRedirectResponseWithURI:(NSURL *)redirectUrl{
    YHSNDebugLog(@"[didReciveRedirectResponseWithURI] [request.tag] %@ [redirectUrl] %@", request.tag, redirectUrl);
}



#pragma mark ------------------ 私有方法 ------------------
// 解析用户信息
- (void)parseUserInfo:(NSString *)originUserInfo{
    __weak typeof(self) weakSelf = self;
    
    NSDictionary *userInfo = [self jsonStringDecode:originUserInfo];
    YHSNDebugLog(@"[新浪登录获取到的用户信息] %@", userInfo);
    
    YHSinaLoginResult *loginResult = [[YHSinaLoginResult alloc] init];
    
    if ([userInfo.allKeys containsObject:@"idstr"]) {
        loginResult.userID = [NSString stringWithFormat:@"%@", userInfo[@"idstr"]];
    }
    if ([userInfo.allKeys containsObject:@"screen_name"]) {
        loginResult.nickName = [NSString stringWithFormat:@"%@", userInfo[@"screen_name"]];
    }
    if ([userInfo.allKeys containsObject:@"gender"]) {
        NSString *gender = [NSString stringWithFormat:@"%@", userInfo[@"gender"]];
        if ([gender isEqualToString:@"m"]) {
            loginResult.sex = 1;
        } else if ([gender isEqualToString:@"f"]) {
            loginResult.sex = 2;
        } else {
            loginResult.sex = 0;
        }
    }
    if ([userInfo.allKeys containsObject:@"province"]) {
        loginResult.province = [NSString stringWithFormat:@"%@", userInfo[@"province"]];
    }
    if ([userInfo.allKeys containsObject:@"city"]) {
        loginResult.city = [NSString stringWithFormat:@"%@", userInfo[@"city"]];
    }
    if ([userInfo.allKeys containsObject:@"avatar_large"]) {
        loginResult.headimgURL = [NSString stringWithFormat:@"%@", userInfo[@"avatar_large"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.loginCompletionBlock) {
            weakSelf.loginCompletionBlock(loginResult);
        }
        weakSelf.loginCompletionBlock = nil;
    });
    [self _hideHUD:self.loginHUD];
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

// 赋值authHUD
- (void)getAuthHUD{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.authHUD = [weakSelf getHUD];
    });
}

// 赋值loginHUD
- (void)getLoginHUD{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.loginHUD = [weakSelf getHUD];
    });
}

// 赋值shareHUD
- (void)getShareHUD{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.shareHUD = [weakSelf getHUD];
    });
}

// 赋值评论微博HUD
- (void)getCommentWeiBoHUD{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.commentWeiBoHUD = [weakSelf getHUD];
    });
}

// 赋值我的微博列表HUD
- (void)getMineWeiBoListHUD{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.mineWeiBoListHUD = [weakSelf getHUD];
    });
}

// 隐藏HUD
- (void)_hideHUD:(MBProgressHUD *)hud{
    if (hud) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    }
}

// JSON string decode.
- (id)jsonStringDecode:(NSString *)json{
    if (!json) {
        return nil;
    }
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id value = [NSJSONSerialization JSONObjectWithData:jsonData
                                               options:NSJSONReadingMutableContainers
                                                 error:&err];
    if (!err && value) {
        YHSNDebugLog(@"JSON string decode successful.");
        return value;
    } else {
        YHSNDebugLog(@"JSON string decode failed, error : %@.", err);
        return nil;
    }
}

// URL encode.
- (NSString *)urlEncoding:(NSString *)text{
    NSString *transcodingString = @"";
    if (text.length == 0 || !text) {
        return transcodingString;
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    transcodingString = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
#else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    transcodingString = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
#endif
    return transcodingString;
}

@end

