//
//  ViewController.m
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "ViewController.h"

#import "YHWXManager.h"
#import "YHQQManager.h"
#import "YHSinaManager.h"

#import "SDK.h"


#define NSLog(format, ...)  printf("%s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark ------------------ QQ ------------------
// QQ授权
- (IBAction)qq_auth:(id)sender {
    [[YHQQManager sharedInstance] authWithShowHUD:YES completionBlock:^(BOOL isSuccess) {
        NSLog(@"😋QQ授权:%@", [YHQQManager sharedInstance].oauth.description);
    }];
}

// QQ获取用户信息
- (IBAction)qq_getUserInfo:(id)sender {
//    [[YHQQManager sharedInstance] authWithShowHUD:YES completionBlock:^(BOOL isSuccess) {
//        [[YHQQManager sharedInstance] getUserInfoWithShowHUD:YES completionBlock:^(YHQQUserInfo * _Nullable result) {
//            NSLog(@"😆QQ获取用户信息:%@", result.description);
//        }];
//    }];
}

// QQ分享
- (IBAction)qq_webShare:(id)sender {
//    [[YHQQManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"标题" description:@"内容内容内容啦啦啦啦啦啦啦Alla" thumbImageURL:@"http://r1.ykimg.com/050E00005CB6C4BE1B7691C88409BC09" shareType:YHQQShareType_QQ shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😆QQ网页分享:isSuccess:%d", isSuccess);
//    }];
}


#pragma mark ------------------ 新浪微博 ------------------
// 新浪微博授权
- (IBAction)sina_auth:(id)sender {
//    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
//        NSLog(@"😆新浪授权:%@", authResponse.description);
//    }];
}

// 新浪微博获取用户信息
- (IBAction)sina_getUserInfo:(id)sender {
//    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
//        if (!authResponse.accessToken) {
//            return ;
//        }
//        [[YHSinaManager sharedInstance] getUserInfoWithAccessToken:authResponse.accessToken userID:authResponse.userID showHUD:YES completionBlock:^(YHSinaUserInfo * _Nullable result) {
//            NSLog(@"😆:新浪获取用户信息:%@", result.description);
//        }];
//    }];
}

// 新浪微博分享
- (IBAction)sina_share:(id)sender {
//    UIImage *image = [UIImage imageNamed:@"1.png"];
//    NSData *data = UIImagePNGRepresentation(image);
//    [[YHSinaManager sharedInstance] shareWithContent:@"啦啦啦" imageData:data showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😆新浪微博分享:isSuccess:%d", isSuccess);
//    }];
}

// 新浪评论指定微博:通过API方式
- (IBAction)sina_comment1:(id)sender {
//    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
//        if (!authResponse.accessToken) {
//            return ;
//        }
//        [[YHSinaManager sharedInstance] commentWeiBo1WithAccessToken:authResponse.accessToken ID:@"4368567048776515" comment:@"hello" isCommentOriginWhenTransfer:NO showHUD:YES completionBlock:^(NSDictionary * _Nullable responseObject) {
//            NSLog(@"😆新浪评论指定微博:responseObject:%@", responseObject);
//        }];
//    }];
}

// 新浪评论指定微博:通过scheme方式
- (IBAction)sina_comment2:(id)sender {
//    [[YHSinaManager sharedInstance] commentWeiBo2WithID:@"4368567048776515" comment:@"啦啦啦啦"];
}

// 新浪获取我的微博列表
- (IBAction)sina_getMyWeiBoList:(id)sender {
//    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
//        if (!authResponse.accessToken) {
//            return ;
//        }
//        [[YHSinaManager sharedInstance] getMineWeoBoListWithAccessToken:authResponse.accessToken userID:authResponse.userID perCount:20 curPage:1 showHUD:YES completionBlock:^(NSDictionary * _Nullable responseObject) {
//            NSLog(@"😆新浪获取我的微博列表:responseObject:%@", responseObject);
//        }];
//    }];
}

#pragma mark ------------------ 微信(本demo导入的是包含支付功能的SDK) ------------------
// 微信授权
- (IBAction)weixin_auth:(id)sender {
//#ifdef kWechatNoPay
//    [[YHWXNoPayManager sharedInstance] authWithShowHUD:YES completionBlock:^(YHWXNoPayAuthResult * _Nullable authResult) {
//        NSLog(@"微信授权:😆:%@", authResult.description);
//    }];
//#else
//    [[YHWXManager sharedInstance] authWithShowHUD:YES completionBlock:^(YHWXAuthResult * _Nullable authResult) {
//        NSLog(@"微信授权:😆:%@", authResult.description);
//    }];
//#endif
}

// 微信获取用户信息
- (IBAction)weixin_getUserInfo:(id)sender {
//#ifdef kWechatNoPay
//    [[YHWXNoPayManager sharedInstance] authWithShowHUD:YES completionBlock:^(YHWXNoPayAuthResult * _Nullable authResult) {
//        if (!authResult) {
//            return ;
//        }
//        [[YHWXNoPayManager sharedInstance] getUserInfoWithOpenID:authResult.openID accessToken:authResult.accessToken showHUD:YES completionBlock:^(YHWXNoPayUserInfoResult * _Nullable userInfoResult) {
//            NSLog(@"微信获取用户信息:😆:%@", userInfoResult.description);
//        }];
//    }];
//#else
//    [[YHWXManager sharedInstance] authWithShowHUD:YES completionBlock:^(YHWXAuthResult * _Nullable authResult) {
//        if (!authResult) {
//            return ;
//        }
//        [[YHWXManager sharedInstance] getUserInfoWithOpenID:authResult.openID accessToken:authResult.accessToken showHUD:YES completionBlock:^(YHWXUserInfoResult * _Nullable userInfoResult) {
//            NSLog(@"微信获取用户信息:😆:%@", userInfoResult.description);
//        }];
//    }];
//#endif
}

// 微信网页分享
- (IBAction)weixin_webShare:(id)sender {
//#ifdef kWechatNoPay
//    [[YHWXNoPayManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"测试标题" description:@"测试内容测试内容测试内容测试内容测试内容测试内容测试内容" thumbImage:[UIImage imageNamed:@"big_image.jpeg"] shareType:YHWXNoPayShareType_Session showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"微信网页分享:😆:%d", isSuccess);
//    }];
//#else
//    [[YHWXManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"测试标题" description:@"测试内容测试内容测试内容测试内容测试内容测试内容测试内容" thumbImage:[UIImage imageNamed:@"1.png"] shareType:YHWXShareType_Session showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"微信网页分享:😆:%d", isSuccess);
//    }];
//#endif
}

- (IBAction)weixin_pay1:(id)sender {
//    [[YHWXManager sharedInstance] pay1WithPartnerID:QAQ_WECHAT_PARTNERID secretKey:QAQ_WECHAT_SECRETKEY prepayID:@"wx081644129033974637e0de663796974002" showHUD:YES comletionBlock:^(BOOL isSuccess) {
//        NSLog(@"微信支付1:😆:%d", isSuccess);
//    }];
}

- (IBAction)weixin_pay2:(id)sender {
//    [[YHWXManager sharedInstance] pay2WithPartnerID:QAQ_WECHAT_PARTNERID prepayID:@"wx081644129033974637e0de663796974002" sign:@"" nonceStr:@"" timeStamp:@"" showHUD:YES comletionBlock:^(BOOL isSuccess) {
//        NSLog(@"微信支付2:😆:%d", isSuccess);
//    }];
}


@end
