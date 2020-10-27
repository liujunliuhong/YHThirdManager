//
//  YHWXManager+Pay.m
//  YHThirdManager
//
//  Created by apple on 2019/12/30.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHWXManager+Pay.h"
#import <objc/message.h>
#import <CommonCrypto/CommonCrypto.h>

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
#import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
#import "MBProgressHUD.h"
#endif

#import "YHThirdDefine.h"

@interface YHWXManager()

@property (nonatomic, strong) MBProgressHUD *payHUD;
@property (nonatomic, assign) BOOL isNeedToHidePayHUD;

@property (nonatomic, copy) void(^payCompletionBlock)(BOOL isSuccess);

@end


@implementation YHWXManager (Pay)

- (void)pay1WithPartnerID:(NSString *)partnerID
                secretKey:(NSString *)secretKey
                 prepayID:(NSString *)prepayID
                  showHUD:(BOOL)showHUD
           comletionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!weakSelf.appID && weakSelf.appID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付1] appID为空");
            return;
        }
        if (!partnerID && partnerID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付1] partnerID为空");
            return;
        }
        if (!secretKey && secretKey.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付1] secretKey为空");
            return;
        }
        if (!prepayID && prepayID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付1] prepayID为空");
            return;
        }
        
        [weakSelf handleNotification];
        
        if (showHUD && [WXApi isWXAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.payHUD = YHThird_GetHud;
        }
        weakSelf.isNeedToHidePayHUD = YES;
        
        weakSelf.payCompletionBlock = completionBlock;
        
        int timestamp = [[weakSelf _currentTimestamp] intValue];
        NSString *package = @"Sign=WXPay";
        NSString *noncestr = [weakSelf _gen32NonceString];
        
        NSDictionary *param = @{@"appid":weakSelf.appID,
                                @"partnerid":partnerID,
                                @"prepayid":prepayID,
                                @"package":package,
                                @"noncestr":noncestr,
                                @"timestamp":[NSString stringWithFormat:@"%d",(int)timestamp]};
        
        NSString *sign = [weakSelf _genSignWithSecretKey:secretKey param:param];
        
        PayReq *request = [[PayReq alloc] init];
        request.partnerId = partnerID;
        request.prepayId = prepayID;
        request.package = package;
        request.nonceStr = noncestr;
        request.timeStamp = timestamp;
        request.sign = sign;
        
        [WXApi sendReq:request completion:^(BOOL success) {
            if (success) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO);
                }
                weakSelf.payCompletionBlock = nil;
                [weakSelf _removeObserve];
                YHThird_HideHud(weakSelf.payHUD);
                [weakSelf removeNotification];
                weakSelf.payHUD = nil;
            });
        }];
    });
}


- (void)pay2WithPartnerID:(NSString *)partnerID
                 prepayID:(NSString *)prepayID
                     sign:(NSString *)sign
                 nonceStr:(NSString *)nonceStr
                timeStamp:(NSString *)timeStamp
                  showHUD:(BOOL)showHUD
           comletionBlock:(void (^)(BOOL))completionBlock{
    YHThird_WeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!weakSelf.appID && weakSelf.appID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] appID为空");
            return;
        }
        if (!partnerID && partnerID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] partnerID为空");
            return;
        }
        if (!prepayID && prepayID.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] prepayID为空");
            return;
        }
        if (!sign && sign.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] sign为空");
            return;
        }
        if (!nonceStr && nonceStr.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] nonceStr为空");
            return;
        }
        if (!timeStamp && timeStamp.length <= 0) {
            YHThirdDebugLog(@"[微信] [支付2] timeStamp为空");
            return;
        }
        
        [weakSelf handleNotification];
        
        if (showHUD && [WXApi isWXAppInstalled]) {
            [weakSelf _removeObserve];
            [weakSelf _addObserve];
            weakSelf.payHUD = YHThird_GetHud;
        }
        weakSelf.isNeedToHidePayHUD = YES;
        
        weakSelf.payCompletionBlock = completionBlock;
        
        PayReq *request = [[PayReq alloc] init];
        request.partnerId = partnerID;
        request.prepayId = prepayID;
        request.package = @"Sign=WXPay";
        request.nonceStr = nonceStr;
        request.timeStamp = [timeStamp intValue];
        request.sign = sign;
        
        [WXApi sendReq:request completion:^(BOOL success) {
            if (success) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO);
                }
                weakSelf.payCompletionBlock = nil;
                [weakSelf _removeObserve];
                YHThird_HideHud(weakSelf.payHUD);
                [weakSelf removeNotification];
                weakSelf.payHUD = nil;
            });
        }];
    });
}


- (void)handleNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"yh_wx_ppp_aaa_yyy_notification"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"yh_wx_hide_hud_ppp_aaa_yyy_notification"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(payNotification:)
                                                 name:@"yh_wx_ppp_aaa_yyy_notification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hidePayHUDNotification)
                                                 name:@"yh_wx_hide_hud_ppp_aaa_yyy_notification"
                                               object:nil];
}


- (void)payNotification:(NSNotification *)noti{
    BaseResp *resp = noti.userInfo[@"resp"];
    if (![resp isKindOfClass:[PayResp class]]) {
        return;
    }
    self.isNeedToHidePayHUD = YES;
    // 支付
    PayResp *response = (PayResp *)resp;
    YHThirdDebugLog(@"[微信支付] [onResp] [PayResp] [errCode] %d [returnKey] %@", response.errCode, response.returnKey);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.payCompletionBlock) {
            self.payCompletionBlock(response.errCode == WXSuccess);
        }
        self.payCompletionBlock = nil;
        [self _removeObserve];
        YHThird_HideHud(self.payHUD);
        [self removeNotification];
        self.payHUD = nil;
    });
}

- (void)hidePayHUDNotification{
    if (!self.isNeedToHidePayHUD) {
        return;
    }
    YHThird_HideHud(self.payHUD);
    [self removeNotification];
    self.isNeedToHidePayHUD = YES;
    self.payHUD = nil;
}




- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"yh_wx_ppp_aaa_yyy_notification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"yh_wx_hide_hud_ppp_aaa_yyy_notification" object:nil];
}


















- (MBProgressHUD *)payHUD{
    return objc_getAssociatedObject(self, @selector(payHUD));
}

- (void)setPayHUD:(MBProgressHUD *)payHUD{
    objc_setAssociatedObject(self, @selector(payHUD), payHUD, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(BOOL))payCompletionBlock{
    return objc_getAssociatedObject(self, @selector(payCompletionBlock));
}

- (void)setPayCompletionBlock:(void (^)(BOOL))payCompletionBlock{
    objc_setAssociatedObject(self, @selector(payCompletionBlock), payCompletionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)isNeedToHidePayHUD{
    return [objc_getAssociatedObject(self, @selector(isNeedToHidePayHUD)) boolValue];
}
- (void)setIsNeedToHidePayHUD:(BOOL)isNeedToHidePayHUD{
    objc_setAssociatedObject(self, @selector(isNeedToHidePayHUD), [NSNumber numberWithBool:isNeedToHidePayHUD], OBJC_ASSOCIATION_ASSIGN);
}


// 生成32位随机字符串
- (NSString *)_gen32NonceString {
    NSArray *sampleArray = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
                             @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",
                             @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T",
                             @"U", @"V", @"W", @"X", @"Y", @"Z"];
    NSMutableString *randomString = [NSMutableString string];
    for (NSInteger i = 0; i < 32; ++i) {
        [randomString appendString:sampleArray[random() % 32]];
    }
    return randomString;
}

// 生成签名    secretKey:商户平台设置的密钥key(不是appSecret)
- (NSString *)_genSignWithSecretKey:(NSString *)secretKey param:(NSDictionary *)param{
    NSMutableString *stringA = [NSMutableString string];
    // 按字典key升序排序
    NSArray *sortKeys = [[param allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // 拼接格式 “key0=value0&key1=value1&key2=value2”
    for (NSString *key in sortKeys) {
        [stringA appendString:[NSString stringWithFormat:@"%@=%@&", key, param[key]]];
    }
    // 拼接商户签名,,,,kShopSign 要和微信平台上填写的密钥一样，（密钥就是签名）
    [stringA appendString:[NSString stringWithFormat:@"key=%@", secretKey]];
    // MD5加密
    NSString *stringB = [self _MD5:stringA];
    // 返回大写字母
    return stringB.uppercaseString;
}

// MD5
- (NSString *)_MD5:(NSString *)string{
    if (!string) {
        return @"";
    }
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    return outputString;
}

// 获取当前时间戳
- (NSString *)_currentTimestamp{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%ld", (long)interval];
}

@end
