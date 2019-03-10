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
    
    //    [[YHWXManager sharedInstance] loginWithViewController:self showHUD:YES completionBlock:^(YHWXLoginResult * _Nullable result) {
    //        [YHMBHud hudOnlyMessage:@"成功获取到信息" inView:nil dismissBlock:nil];
    //        NSLog(@"😆:%@", result);
    //    }];
    
    
    
    
    //    [[YHWXManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"title" description:@"description" thumbImage:nil shareType:YHWXShareType_Session showHUD:YES completionBlock:^(BOOL isSuccess) {
    //        NSLog(@"😆:%d", isSuccess);
    //    }];
    
    //    [[YHWXManager sharedInstance] payWithPartnerID:@"1483786922" secretKey:@"97a4b0035899c8e0fa9b1364e9b0d643" prepayID:@"wx081644129033974637e0de663796974002" showHUD:YES comletionBlock:^(BOOL isSuccess, NSError * _Nullable error) {
    //        NSLog(@"😆:%d", isSuccess);
    //        NSLog(@"😆:%@", error);
    //    }];
    
    
    //    [[YHQQManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"SB" description:@"你是SB" thumbImageURL:@"http://r1.ykimg.com/050E000059488937ADBA1F9712028679" shareType:YHQQShareType_QQ shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
    //        NSLog(@"😄:%d", (int)isSuccess);
    //    }];
    
    
    [[YHQQManager sharedInstance] loginWithShowHUD:YES completionBlock:^(YHQQLoginResult * _Nullable result) {
        NSLog(@"😄:%@", result);
        [weak_self hudOnlyMessage:@"成功获取到信息" inView:nil dismissBlock:nil];
    }];
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
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:2];//必须在主线程，源码规定
        hud.completionBlock = dismissBlock;
    });
}

@end
