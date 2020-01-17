//
//  YHAlipayManager.m
//  YHThirdManager
//
//  Created by apple on 2020/1/17.
//  Copyright © 2020 yinhe. All rights reserved.
//

#import "YHAlipayManager.h"
#import <UIKit/UIKit.h>
#import "YHThirdDefine.h"

#if __has_include(<AlipaySDK/AlipaySDK.h>)
    #import <AlipaySDK/AlipaySDK.h>
#endif

@interface YHAlipayManager()
@property (nonatomic, copy) void(^payCompletionBlock)(NSDictionary *resultDic);
@end

@implementation YHAlipayManager

+ (instancetype)sharedInstance{
    static YHAlipayManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

/// handleOpenURL
/// @param URL URL
- (void)handleOpenURL:(NSURL *)URL{
    YHThird_WeakSelf
    if ([URL.host isEqualToString:@"safepay"]) {
        #if __has_include(<AlipaySDK/AlipaySDK.h>)
        [[AlipaySDK defaultService] processOrderWithPaymentResult:URL standbyCallback:^(NSDictionary *resultDic) {
            YHThirdDebugLog(@"[支付宝] [processOrderWithPaymentResult:standbyCallback:] %@", resultDic);
            if (resultDic) {
                if (weakSelf.payCompletionBlock) {
                    weakSelf.payCompletionBlock(resultDic);
                }
            }
        }];
        #endif
    }
}

/// 支付
/// @param order 订单参数，从服务端获取
/// @param scheme scheme
/// @param completionBlock 回调
- (void)payWithOrder:(NSString *)order scheme:(NSString *)scheme completionBlock:(void (^)(NSDictionary * _Nonnull))completionBlock{
    #if __has_include(<AlipaySDK/AlipaySDK.h>)
    [[AlipaySDK defaultService] payOrder:order fromScheme:scheme callback:^(NSDictionary *resultDic) {
        YHThirdDebugLog(@"[支付宝] [payOrder:fromScheme:callback:] %@", resultDic);
        if (resultDic) {
            if (completionBlock) {
                completionBlock(resultDic);
            }
        }
    }];
    #endif
}





@end
