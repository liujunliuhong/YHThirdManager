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
#import <MBProgressHUD/MBProgressHUD.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"按钮" forState:UIControlStateNormal];
    btn.center = self.view.center;
    btn.bounds = CGRectMake(0, 0, 300, 100);
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)btnClick{
    __weak typeof(self) weak_self = self;
    
//    //微信登录
//    [[YHWXManager sharedInstance] loginWithViewController:self showHUD:YES completionBlock:^(YHWXLoginResult * _Nullable result) {
//        [weak_self hudOnlyMessage:@"成功获取到信息" inView:nil dismissBlock:nil];
//        NSLog(@"😆:%@", result);
//    }];
    
    
//    // 微信分享
//    [[YHWXManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"title" description:@"description" thumbImage:nil shareType:YHWXShareType_Session showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😆:%d", isSuccess);
//    }];
//
//    // 微信支付
//    [[YHWXManager sharedInstance] payWithPartnerID:QAQ_WECHAT_PARTNERID secretKey:QAQ_WECHAT_SECRETKEY prepayID:@"wx081644129033974637e0de663796974002" showHUD:YES comletionBlock:^(BOOL isSuccess) {
//        NSLog(@"😆:%d", isSuccess);
//    }];
//
//    // QQ分享
//    [[YHQQManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"SB" description:@"你是SB" thumbImageURL:@"http://r1.ykimg.com/050E000059488937ADBA1F9712028679" shareType:YHQQShareType_QQ shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😄:%d", (int)isSuccess);
//    }];
//
//    // QQ登录
//    [[YHQQManager sharedInstance] loginWithShowHUD:YES completionBlock:^(YHQQLoginResult * _Nullable result) {
//        NSLog(@"😄:%@", result);
//        [weak_self hudOnlyMessage:@"成功获取到信息" inView:nil dismissBlock:nil];
//    }];
    
    
    
    
    
    // 新浪授权
//    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
//        NSLog(@"😆accessToken:%@", authResponse.accessToken);
//        NSLog(@"😆userID:%@", authResponse.userID);
//        if (!authResponse) {
//            return ;
//        }
////        [[YHSinaManager sharedInstance] loginWithAccessToken:authResponse.accessToken userID:authResponse.userID showHUD:YES completionBlock:^(YHSinaLoginResult * _Nullable result) {
////
////                }];
//        [[YHSinaManager sharedInstance] shareWithAccessToken:authResponse.accessToken content:@"123456" images:@[[UIImage imageNamed:@"1.png"]] showHUD:YES completionBlock:^(BOOL isSuccess) {
//            NSLog(@"😆:分享结果:%d", isSuccess);
//        }];
////        [[YHSinaManager sharedInstance] commentWeiBoWithAccessToken:authResponse.accessToken ID:@"4348583429975153" comment:@"lalalalal" isCommentOriginWhenTransfer:NO showHUD:YES completionBlock:^(BOOL isSuccess) {
////
////        }];
////        [[YHSinaManager sharedInstance] getMineWeoBoListWithAccessToken:authResponse.accessToken userID:authResponse.userID perCount:20 curPage:1 showHUD:YES completionBlock:^(NSDictionary * _Nullable responseObject) {
////
////        }];
//
//    }];
    
    
    
    
    
    // 新浪微博获取我的微博列表
    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
        if (!authResponse.accessToken) {
            return ;
        }
        [[YHSinaManager sharedInstance] getMineWeoBoListWithAccessToken:authResponse.accessToken userID:authResponse.userID perCount:20 curPage:1 showHUD:YES completionBlock:^(NSDictionary * _Nullable responseObject) {
            
        }];
    }];
    
    
    
    
    
    
    
    // 新浪分享
//    NSData *data1 = UIImageJPEGRepresentation([UIImage imageNamed:@"1.png"], 0.2);
//    NSData *data2 = UIImageJPEGRepresentation([UIImage imageNamed:@"2.png"], 0.2);
//    NSData *data3 = UIImageJPEGRepresentation([UIImage imageNamed:@"123.png"], 0.1);
//    UIImage *image1 = [UIImage imageWithData:data1];
//    UIImage *image2 = [UIImage imageWithData:data2];
//    UIImage *image3 = [UIImage imageWithData:data3];
//    [[YHSinaManager sharedInstance] shareWithContent:@"哈哈" imageData:data2 showHUD:YES completionBlock:^(BOOL isSuccess) {
//
//    }];
    
    
    
    // 新浪评论指定微博
//    [[YHSinaManager sharedInstance] commentWeiBo2WithID:@"4368567048776515" comment:@"你好啊啊"];
    
    
    
    
    
    //
//    [[YHSinaManager sharedInstance] commentWeiBoWithAccessToken:@"2.00QtnqgBGdJgTB5e841d5cdcJJVruD" ID:@"4348583429975153" comment:@"啦啦啦啦哈哈" isCommentOriginWhenTransfer:NO showHUD:YES completionBlock:^(BOOL isSuccess) {
//
//    }];
    
    
    //    //新浪登录
//    [[YHSinaManager sharedInstance] loginWithShowHUD:YES completionBlock:^(YHSinaLoginResult * _Nullable result) {
//        NSLog(@"😄:%@", result);
//        [weak_self hudOnlyMessage:@"成功获取到信息" inView:nil dismissBlock:nil];
//    }];
    
    //新浪分享
//    [[YHSinaManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"啦啦" description:@"😋😋😋😋😋😋" thumbnailData:[UIImage imageNamed:@"test_share.jpeg"] showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😄:%d", isSuccess);
//    }];
//
//    [[YHSinaManager sharedInstance] shareWithContent:@"哈哈哈" images:@[[UIImage imageNamed:@"1.png"],[UIImage imageNamed:@"2.png"],[UIImage imageNamed:@"4.jpg"]] showHUD:YES completionBlock:^(BOOL isSuccess) {
//        NSLog(@"😄:%d", isSuccess);
//    }];
}

/** 仅仅只有一段提示信息，一段时间后消失 */
- (void)hudOnlyMessage:(NSString *)message inView:(UIView *)view dismissBlock:(void (^)(void))dismissBlock{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!message || message.length == 0) {
            return;
        }
        UIView *tmpView = view;
        if (!view) {
            tmpView = [UIApplication sharedApplication].keyWindow;
        }
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:tmpView animated:YES];//必须在主线程，源码规定
        
        hud.mode = MBProgressHUDModeText;
        hud.contentColor = [UIColor whiteColor];
        hud.label.text = message;
        hud.label.numberOfLines = 0;
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color = [UIColor blackColor];
        hud.removeFromSuperViewOnHide = NO;
        [hud hideAnimated:YES afterDelay:2];//必须在主线程，源码规定
        hud.completionBlock = dismissBlock;
    });
}

@end
