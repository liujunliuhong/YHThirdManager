//
//  AppDelegate.m
//  YHThirdManager
//
//  Created by 银河 on 2019/3/10.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "AppDelegate.h"
#import "YHQQManager.h"
#import "YHWXManager.h"
#import "YHSinaManager.h"
#import "SDK.h"

@interface AppDelegate ()

@end

@implementation AppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[YHQQManager sharedInstance] initWithAppID:QQ_APP_ID universalLink:QQ_Universal_Links];
    //[[YHWXManager sharedInstance] initWithAppID:WECHAT_APP_ID appSecret:WECHAT_APP_SECRET universalLink:WECHAT_Universal_Links];
    //[[YHSinaManager sharedInstance] initWithAppID:SINA_APP_KEY redirectURI:SINA_Redirect_URL];
    
    return YES;
}

// 9.0之后
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    //[[YHWXManager sharedInstance] handleOpenURL:url];
    [[YHQQManager sharedInstance] handleOpenURL:url];
    //[[YHSinaManager sharedInstance] handleOpenURL:url];
    return YES;
}

// 9.0之前
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    //[[YHWXManager sharedInstance] handleOpenURL:url];
    [[YHQQManager sharedInstance] handleOpenURL:url];
    //[[YHSinaManager sharedInstance] handleOpenURL:url];
    return YES;
}

// 测试发现，在模拟器上，未安装微博，使用网页打开微博，点击取消，程序崩溃，加上下面这个方法后，程序正常运行
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    //[[YHWXManager sharedInstance] handleOpenURL:url];
    [[YHQQManager sharedInstance] handleOpenURL:url];
    //[[YHSinaManager sharedInstance] handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    //[[YHWXManager sharedInstance] handleOpenUniversalLink:userActivity];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
