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




@implementation YHSinaUserInfo
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
    NSDictionary *dic = @{@"nickName":self.nickName ? self.nickName : [NSNull null],
                          @"sex":@(self.sex),
                          @"province":self.province ? self.province : [NSNull null],
                          @"city":self.city ? self.city : [NSNull null],
                          @"headImgURL":self.headImgURL ? self.headImgURL : [NSNull null],
                          @"originInfo":self.originInfo ? self.originInfo : [NSNull null]};
    return [NSString stringWithFormat:@"%@", dic];
}
@end




@interface YHSinaManager () <WeiboSDKDelegate, WBHttpRequestDelegate>
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *redirectURI;

@property (nonatomic, strong) MBProgressHUD *authHUD;
@property (nonatomic, strong) MBProgressHUD *getUserInfoHUD;
@property (nonatomic, strong) MBProgressHUD *shareWebHUD;
@property (nonatomic, strong) MBProgressHUD *commentWeiBoHUD;
@property (nonatomic, strong) MBProgressHUD *mineWeiBoListHUD;

@property (nonatomic, copy) void(^authCompletionBlock)(WBAuthorizeResponse *authResponse);
@property (nonatomic, copy) void(^getUserInfoCompletionBlock)(YHSinaUserInfo *result);
@property (nonatomic, copy) void(^shareWebCompletionBlock)(BOOL isSuccess);
@property (nonatomic, copy) void(^commentWeiBoCompletionBlock)(NSDictionary *responseObject);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.appID) {
            YHSNDebugLog(@"[授权] appID为空");
            return;
        }
        if (!weakSelf.redirectURI) {
            YHSNDebugLog(@"[授权] redirectURI为空");
            return;
        }
        weakSelf.sdkFlag = NO;
        if (showHUD && [WeiboSDK isWeiboAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.authHUD = [weakSelf getHUD];
        }
        weakSelf.authCompletionBlock = completionBlock;
        
        WBAuthorizeRequest *authorizeRequest = [[WBAuthorizeRequest alloc] init];
        authorizeRequest.redirectURI = weakSelf.redirectURI;
        authorizeRequest.shouldShowWebViewForAuthIfCannotSSO = YES;
        authorizeRequest.scope = @"all";
        
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


- (void)getUserInfoWithAccessToken:(NSString *)accessToken
                            userID:(NSString *)userID
                           showHUD:(BOOL)showHUD
                   completionBlock:(void (^)(YHSinaUserInfo * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
            weakSelf.getUserInfoHUD = [weakSelf getHUD];
        }
        weakSelf.getUserInfoCompletionBlock = completionBlock;
        
        NSDictionary *param = @{@"access_token" : accessToken,
                                @"uid" : userID};
        
        [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_GetUserInfoAPI httpMethod:@"GET" params:param delegate:weakSelf withTag:kYHSN_GetUserInfoTag];
    });
}

- (void)shareWithTitle:(NSString *)title
                   url:(NSString *)url
           description:(NSString *)description
        thumbImageData:(NSData *)thumbImageData
               showHUD:(BOOL)showHUD
       completionBlock:(void (^)(BOOL))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.redirectURI) {
            YHSNDebugLog(@"[分享] redirectURI为空");
            return;
        }
        if (showHUD && [WeiboSDK isWeiboAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.shareWebHUD = [weakSelf getHUD];
        }
        weakSelf.sdkFlag = NO;
        weakSelf.shareWebCompletionBlock = completionBlock;
        
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
        
        BOOL res = [WeiboSDK sendRequest:request];
        if (!res) {
            if (completionBlock) {
                completionBlock(NO);
            }
            weakSelf.shareWebCompletionBlock = nil;
            [weakSelf _hideHUD:weakSelf.shareWebHUD];
        }
    });
}

- (void)commentWeiBo1WithAccessToken:(NSString *)accessToken
                                  ID:(NSString *)ID
                             comment:(NSString *)comment
         isCommentOriginWhenTransfer:(BOOL)isCommentOriginWhenTransfer
                             showHUD:(BOOL)showHUD
                     completionBlock:(void (^)(NSDictionary *))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
            weakSelf.commentWeiBoHUD = [weakSelf getHUD];
        }
        weakSelf.commentWeiBoCompletionBlock = completionBlock;
        
        NSDictionary *param = @{@"access_token" : accessToken,
                                @"comment" : comment,
                                @"id" : ID,
                                @"comment_ori" : isCommentOriginWhenTransfer ? @"1" : @"0"};
        [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_CommentWeiBoAPI httpMethod:@"POST" params:param delegate:weakSelf withTag:kYHSN_CommentWeiBoTag];
    });
}


- (void)commentWeiBo2WithID:(NSString *)ID
                    comment:(NSString *)comment{
    NSString *url = @"";
    if (!comment || comment.length == 0 || [comment isEqualToString:@""]) {
        url = [NSString stringWithFormat:@"sinaweibo://comment?srcid=%@", ID];
    } else {
        url = [NSString stringWithFormat:@"sinaweibo://comment?srcid=%@&content=%@", ID, comment];
    }
    NSURL *URL = [NSURL URLWithString:[self urlEncoding:url]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] canOpenURL:URL]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:URL];
            }
        } else {
            YHSNDebugLog(@"[评论指定微博] [用户没有安装微博客户端]");
        }
    });
}

- (void)getMineWeoBoListWithAccessToken:(NSString *)accessToken
                                 userID:(NSString *)userID
                               perCount:(int)perCount
                                curPage:(int)curPage
                                showHUD:(BOOL)showHUD
                        completionBlock:(void (^)(NSDictionary * _Nullable))completionBlock{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.sdkFlag = YES;
        if (showHUD) {
            weakSelf.mineWeiBoListHUD = [weakSelf getHUD];
        }
        weakSelf.mineWeiBoListCompletionBlock = completionBlock;
        
        NSDictionary *param = @{@"access_token" : accessToken,
                                @"uid" : userID,
                                @"count" : [NSString stringWithFormat:@"%d", perCount],
                                @"page" : [NSString stringWithFormat:@"%d", curPage]};
        [WBHttpRequest requestWithAccessToken:accessToken url:kYHSN_MineWeiBoListAPI httpMethod:@"GET" params:param delegate:weakSelf withTag:kYHSN_MineWeiBoListTag];
    });
}

#pragma mark ------------------ Notification ------------------
- (void)applicationWillEnterForeground:(NSNotification *)noti{
    YHSNDebugLog(@"applicationWillEnterForeground");
    [self _hideHUD:self.authHUD];
    [self _hideHUD:self.shareWebHUD];
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
    [self _hideHUD:self.shareWebHUD];
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
            if (weakSelf.shareWebCompletionBlock) {
                weakSelf.shareWebCompletionBlock(sendMessageToWeiboResponse.statusCode == WeiboSDKResponseStatusCodeSuccess ? YES : NO);
            }
            weakSelf.shareWebCompletionBlock = nil;
        });
        [self _hideHUD:self.shareWebHUD];
        [self _removeObserve];
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
            if (weakSelf.getUserInfoCompletionBlock) {
                weakSelf.getUserInfoCompletionBlock(nil);
            }
            weakSelf.getUserInfoCompletionBlock = nil;
        });
        [self _hideHUD:self.getUserInfoHUD];
    } else if ([request.tag isEqualToString:kYHSN_CommentWeiBoTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.commentWeiBoCompletionBlock) {
                weakSelf.commentWeiBoCompletionBlock(nil);
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
//- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result{
//    YHSNDebugLog(@"[didFinishLoadingWithResult] [request.tag] %@", request.tag);
//    id responseObject = [self jsonStringDecode:result];
//    YHSNDebugLog(@"[didFinishLoadingWithResult] [JSON解析成功]\n%@", responseObject);
//    __weak typeof(self) weakSelf = self;
//    if ([request.tag isEqualToString:kYHSN_GetUserInfoTag]) {
//        [self parseUserInfo:responseObject];
//    } else if ([request.tag isEqualToString:kYHSN_CommentWeiBoTag]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (weakSelf.commentWeiBoCompletionBlock) {
//                weakSelf.commentWeiBoCompletionBlock(responseObject ? responseObject : nil);
//            }
//            weakSelf.commentWeiBoCompletionBlock = nil;
//        });
//        [self _hideHUD:self.commentWeiBoHUD];
//    } else if ([request.tag isEqualToString:kYHSN_MineWeiBoListTag]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (weakSelf.mineWeiBoListCompletionBlock) {
//                weakSelf.mineWeiBoListCompletionBlock(responseObject ? responseObject : nil);
//            }
//            weakSelf.mineWeiBoListCompletionBlock = nil;
//        });
//        [self _hideHUD:self.mineWeiBoListHUD];
//    }
//}

- (void)request:(WBHttpRequest *)request didFinishLoadingWithDataResult:(NSData *)data{
    NSError *error = nil;
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (responseObject) {
        YHSNDebugLog(@"[didFinishLoadingWithDataResult] [request.tag] %@ [JSON解析成功]\n%@", request.tag, responseObject);
    }
    if (error) {
        YHSNDebugLog(@"[didFinishLoadingWithDataResult] [request.tag] %@ [JSON解析出错] %@", request.tag, error);
    }
    __weak typeof(self) weakSelf = self;
    if ([request.tag isEqualToString:kYHSN_GetUserInfoTag]) {
        [self parseUserInfo:responseObject];
    } else if ([request.tag isEqualToString:kYHSN_CommentWeiBoTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.commentWeiBoCompletionBlock) {
                weakSelf.commentWeiBoCompletionBlock(error ? nil : (responseObject ? responseObject : nil));
            }
            weakSelf.commentWeiBoCompletionBlock = nil;
        });
        [self _hideHUD:self.commentWeiBoHUD];
    } else if ([request.tag isEqualToString:kYHSN_MineWeiBoListTag]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.mineWeiBoListCompletionBlock) {
                weakSelf.mineWeiBoListCompletionBlock(error ? nil : (responseObject ? responseObject : nil));
            }
            weakSelf.mineWeiBoListCompletionBlock = nil;
        });
        [self _hideHUD:self.mineWeiBoListHUD];
    }
}

- (void)request:(WBHttpRequest *)request didReciveRedirectResponseWithURI:(NSURL *)redirectUrl{
    YHSNDebugLog(@"[didReciveRedirectResponseWithURI] [request.tag] %@ [redirectUrl] %@", request.tag, redirectUrl);
}



#pragma mark ------------------ 私有方法 ------------------
// 解析用户信息
- (void)parseUserInfo:(NSDictionary *)originUserInfo{
    __weak typeof(self) weakSelf = self;
    
    YHSinaUserInfo *info = [[YHSinaUserInfo alloc] init];
    
    info.originInfo = originUserInfo;
    
    if ([originUserInfo.allKeys containsObject:@"screen_name"]) {
        info.nickName = [NSString stringWithFormat:@"%@", originUserInfo[@"screen_name"]];
    }
    if ([originUserInfo.allKeys containsObject:@"gender"]) {
        NSString *gender = [NSString stringWithFormat:@"%@", originUserInfo[@"gender"]];
        if ([gender isEqualToString:@"m"]) {
            info.sex = 1;
        } else if ([gender isEqualToString:@"f"]) {
            info.sex = 2;
        } else {
            info.sex = 0;
        }
    }
    if ([originUserInfo.allKeys containsObject:@"province"]) {
        info.province = [NSString stringWithFormat:@"%@", originUserInfo[@"province"]];
    }
    if ([originUserInfo.allKeys containsObject:@"city"]) {
        info.city = [NSString stringWithFormat:@"%@", originUserInfo[@"city"]];
    }
    if ([originUserInfo.allKeys containsObject:@"avatar_large"]) {
        info.headImgURL = [NSString stringWithFormat:@"%@", originUserInfo[@"avatar_large"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.getUserInfoCompletionBlock) {
            weakSelf.getUserInfoCompletionBlock(info);
        }
        weakSelf.getUserInfoCompletionBlock = nil;
    });
    [self _hideHUD:self.getUserInfoHUD];
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

