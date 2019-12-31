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


@interface Model : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SEL action;
- (instancetype)initWithTitle:(NSString *)title action:(SEL)action;
@end
@implementation Model
- (instancetype)initWithTitle:(NSString *)title action:(SEL)action
{
    self = [super init];
    if (self) {
        self.title = title;
        self.action = action;
    }
    return self;
}
@end

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSArray<Model *> *> *dataSource;
@end

@implementation ViewController
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"YHThirdManager";
    [self.view addSubview:self.tableView];
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    } else {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    self.dataSource = [NSMutableArray array];
    
    {
        Model *model1 = [[Model alloc] initWithTitle:@"QQ授权" action:@selector(qq_auth)];
        Model *model2 = [[Model alloc] initWithTitle:@"QQ获取用户信息" action:@selector(qq_getUserInfo)];
        Model *model3 = [[Model alloc] initWithTitle:@"QQ网页分享" action:@selector(qq_webShare)];
        Model *model4 = [[Model alloc] initWithTitle:@"QQ图片分享" action:@selector(qq_picShare)];
        NSArray<Model *> *ary = @[model1, model2, model3, model4];
        [self.dataSource addObject:ary];
    }
    
    
    
}
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataSource.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[self.dataSource objectAtIndex:section] count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    cell.textLabel.text = self.dataSource[indexPath.section][indexPath.row].title;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    SEL action = self.dataSource[indexPath.section][indexPath.row].action;
    if ([self respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:action];
#pragma clang diagnostic pop
    }
}










#pragma mark ------------------ QQ ------------------
// QQ授权
- (void)qq_auth{
    [[YHQQManager sharedInstance] authWithShowHUD:YES completionBlock:^(BOOL isSuccess) {
        if (!isSuccess) {
            NSLog(@"😋授权失败");
            return;
        }
        NSLog(@"😋授权成功");
    }];
}

// QQ获取用户信息
- (void)qq_getUserInfo{
    // 1、先授权
    // 2、再获取用户信息
    [[YHQQManager sharedInstance] authWithShowHUD:YES completionBlock:^(BOOL isSuccess) {
        if (!isSuccess) {
            NSLog(@"😋授权失败");
            return;
        }
        NSString *accessToken = [YHQQManager sharedInstance].oauth.accessToken;
        NSString *appID = [YHQQManager sharedInstance].oauth.appId;
        NSString *openID = [YHQQManager sharedInstance].oauth.openId;
        [[YHQQManager sharedInstance] getUserInfoWithAccessToken:accessToken appID:appID openId:openID isShowHUD:YES completionBlock:^(BOOL isSuccess) {
            if (!isSuccess) {
                NSLog(@"😋获取用户信息失败");
                return;
            }
            NSLog(@"😋获取用户信息成功");
        }];
    }];
}

// QQ网页分享
- (void)qq_webShare{
    [[YHQQManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"标题" description:@"内容内容内容内容内容内容" thumbImageURL:nil shareType:YHQQShareType_QQ shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
        if (!isSuccess) {
            NSLog(@"😋分享失败");
            return;
        }
        NSLog(@"😋分享成功");
    }];
//    [[YHQQManager sharedInstance] shareWebWithURL:@"https://www.baidu.com" title:@"标题" description:@"内容内容内容内容内容内容" thumbImageData:nil shareType:YHQQShareType_QQ shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
//        if (!isSuccess) {
//            NSLog(@"😋分享失败");
//            return;
//        }
//        NSLog(@"😋分享成功");
//    }];
}

// QQ图片分享
- (void)qq_picShare{
    
}


#pragma mark ------------------ 新浪微博 ------------------
// 新浪微博授权
- (void)sina_auth{
    //    [[YHSinaManager sharedInstance] authWithShowHUD:YES completionBlock:^(WBAuthorizeResponse * _Nullable authResponse) {
    //        NSLog(@"😆新浪授权:%@", authResponse.description);
    //    }];
}

// 新浪微博获取用户信息
- (void)sina_getUserInfo{
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
- (void)sina_share{
    //    UIImage *image = [UIImage imageNamed:@"1.png"];
    //    NSData *data = UIImagePNGRepresentation(image);
    //    [[YHSinaManager sharedInstance] shareWithContent:@"啦啦啦" imageData:data showHUD:YES completionBlock:^(BOOL isSuccess) {
    //        NSLog(@"😆新浪微博分享:isSuccess:%d", isSuccess);
    //    }];
}

// 新浪评论指定微博:通过API方式
- (void)sina_comment1{
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
- (void)sina_comment2{
    //    [[YHSinaManager sharedInstance] commentWeiBo2WithID:@"4368567048776515" comment:@"啦啦啦啦"];
}

// 新浪获取我的微博列表
- (void)sina_getMyWeiBoList{
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
- (void)weixin_auth{
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
- (void)weixin_getUserInfo{
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
- (void)weixin_webShare{
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

- (void)weixin_pay1{
    //    [[YHWXManager sharedInstance] pay1WithPartnerID:QAQ_WECHAT_PARTNERID secretKey:QAQ_WECHAT_SECRETKEY prepayID:@"wx081644129033974637e0de663796974002" showHUD:YES comletionBlock:^(BOOL isSuccess) {
    //        NSLog(@"微信支付1:😆:%d", isSuccess);
    //    }];
}

- (void)weixin_pay2{
    //    [[YHWXManager sharedInstance] pay2WithPartnerID:QAQ_WECHAT_PARTNERID prepayID:@"wx081644129033974637e0de663796974002" sign:@"" nonceStr:@"" timeStamp:@"" showHUD:YES comletionBlock:^(BOOL isSuccess) {
    //        NSLog(@"微信支付2:😆:%d", isSuccess);
    //    }];
}


@end
