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
#import "YHWXManager+Pay.h"
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
    
    
    Model *model1 = [[Model alloc] initWithTitle:@"微信 - 获取code" action:@selector(weixin_getCode)];
    Model *model2 = [[Model alloc] initWithTitle:@"微信 - 获取accessToken" action:@selector(weixin_getAccessToken)];
    Model *model3 = [[Model alloc] initWithTitle:@"微信 - 获取获取用户信息" action:@selector(weixin_getUserInfo)];
    Model *model4 = [[Model alloc] initWithTitle:@"微信 - 获取网页分享" action:@selector(weixin_webShare)];
    Model *model5 = [[Model alloc] initWithTitle:@"微信 - 微信支付" action:@selector(weixin_pay)];
    Model *model6 = [[Model alloc] initWithTitle:@"QQ授权" action:@selector(qq_auth)];
    Model *model7 = [[Model alloc] initWithTitle:@"QQ获取用户信息" action:@selector(qq_getUserInfo)];
    Model *model8 = [[Model alloc] initWithTitle:@"QQ网页分享" action:@selector(qq_webShare)];
    Model *model9 = [[Model alloc] initWithTitle:@"QQ图片分享" action:@selector(qq_picShare)];
    NSArray<Model *> *ary = @[model1, model2, model3, model4, model5, model6, model7, model8, model9];
    [self.dataSource addObject:ary];
    
    
    
    [self.tableView reloadData];
}

- (void)alertMessage:(id)object{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"信息" message:[NSString stringWithFormat:@"%@", object] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SEL action = self.dataSource[indexPath.section][indexPath.row].action;
    if ([self respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:action];
#pragma clang diagnostic pop
    }
}








#pragma mark ------------------ 微信(本demo导入的是包含支付功能的SDK) ------------------
// 微信获取code
- (void)weixin_getCode{
    [[YHWXManager sharedInstance] authForGetCodeWithShowHUD:YES completionBlock:^(BOOL isGetCodeSuccess) {
        NSLog(@"😆微信获取Code: %d", isGetCodeSuccess);
    }];
}

// 微信获取accessToken
- (void)weixin_getAccessToken{
    __weak typeof(self) waekSelf = self;
    [[YHWXManager sharedInstance] authForGetCodeWithShowHUD:YES completionBlock:^(BOOL isGetCodeSuccess) {
        if (!isGetCodeSuccess) {
            NSLog(@"😆微信获取AccessToken - 获取code失败");
            return;
        }
        NSString *code = [YHWXManager sharedInstance].code;
        [[YHWXManager sharedInstance] authForGetAccessTokenWithAppID:WECHAT_APP_ID appSecret:WECHAT_APP_SECRET code:code showHUD:YES completionBlock:^(BOOL isGetAccessTokenSuccess) {
            NSLog(@"😆微信获取AccessToken: %d", isGetAccessTokenSuccess);
            [waekSelf alertMessage:[YHWXManager sharedInstance].authResult.originAuthInfo];
        }];
    }];
}

// 微信获取用户信息
- (void)weixin_getUserInfo{
    __weak typeof(self) waekSelf = self;
    [[YHWXManager sharedInstance] authForGetCodeWithShowHUD:YES completionBlock:^(BOOL isGetCodeSuccess) {
        if (!isGetCodeSuccess) {
            NSLog(@"😆微信获取用户信息 - 获取code失败");
            return;
        }
        NSString *code = [YHWXManager sharedInstance].code;
        [[YHWXManager sharedInstance] authForGetAccessTokenWithAppID:WECHAT_APP_ID appSecret:WECHAT_APP_SECRET code:code showHUD:YES completionBlock:^(BOOL isGetAccessTokenSuccess) {
            if (!isGetAccessTokenSuccess) {
                NSLog(@"😆微信获取用户信息 - 获取AccessToken失败");
                return;
            }
            NSString *openID = [YHWXManager sharedInstance].authResult.openID;
            NSString *accessToken = [YHWXManager sharedInstance].authResult.accessToken;
            [[YHWXManager sharedInstance] getUserInfoWithOpenID:openID accessToken:accessToken showHUD:YES completionBlock:^(BOOL isGetUserInfoSuccess) {
                NSLog(@"😆微信获取用户信息: %d", isGetUserInfoSuccess);
                [waekSelf alertMessage:[YHWXManager sharedInstance].userInfo.originInfo];
            }];
        }];
    }];
}

// 微信网页分享
- (void)weixin_webShare{
    NSString *url = @"https://www.baidu.com";
    NSString *title = @"这是标题";
    NSString *description = @"这是描述";
    UIImage *thumbImage = [UIImage imageNamed:@"1.png"];
    YHWXShareType shareType = YHWXShareType_Session;
    [[YHWXManager sharedInstance] shareWebWithURL:url title:title description:description thumbImage:thumbImage shareType:shareType showHUD:YES completionBlock:^(BOOL isSuccess) {
        NSLog(@"😆微信分享: %d", isSuccess);
    }];
}

// 微信支付
- (void)weixin_pay{
    [[YHWXManager sharedInstance] pay1WithPartnerID:@"商户ID" secretKey:@"秘钥" prepayID:@"预支付ID" showHUD:YES comletionBlock:^(BOOL isSuccess) {
        NSLog(@"😆微信支付:%d", isSuccess);
    }];
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
            [self alertMessage:[YHQQManager sharedInstance].userInfo.originInfo];
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
}

// QQ图片分享
- (void)qq_picShare{
    [[YHQQManager sharedInstance] shareImageWithImageData:UIImageJPEGRepresentation([UIImage imageNamed:@"1.png"], 1) thumbImageData:nil title:@"标题" description:@"内容内容内容内容内容内容" shareDestType:YHQQShareDestType_QQ showHUD:YES completionBlock:^(BOOL isSuccess) {
        if (!isSuccess) {
            NSLog(@"😋分享失败");
            return;
        }
        NSLog(@"😋分享成功");
    }];
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



@end
