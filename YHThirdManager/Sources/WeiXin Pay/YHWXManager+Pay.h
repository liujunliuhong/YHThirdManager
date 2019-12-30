//
//  YHWXManager+Pay.h
//  YHThirdManager
//
//  Created by apple on 2019/12/30.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YHWXManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface YHWXManager (Pay)

/// 微信支付方式一：服务端只需要提供prepayID，其余的secretKey、partnerID、appID在APP里面写死（客户端做签名，不安全）
/// @param partnerID 商户ID
/// @param secretKey 商户秘钥（不是appSecret）
/// @param prepayID 预支付ID
/// @param showHUD 是否显示HUD
/// @param completionBlock 支付完成后在主线程的回调
- (void)pay1WithPartnerID:(NSString *)partnerID
               secretKey:(NSString *)secretKey
                prepayID:(NSString *)prepayID
                 showHUD:(BOOL)showHUD
          comletionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;

/// 微信支付方式二：支付参数全从服务端获取
/// @param partnerID 商户ID
/// @param prepayID 预支付ID
/// @param sign 签名
/// @param nonceStr 随机字符串
/// @param timeStamp 时间戳
/// @param showHUD 是否显示HUD
/// @param completionBlock 支付完成后在主线程的回调
- (void)pay2WithPartnerID:(NSString *)partnerID
                prepayID:(NSString *)prepayID
                    sign:(NSString *)sign
                nonceStr:(NSString *)nonceStr
               timeStamp:(NSString *)timeStamp
                 showHUD:(BOOL)showHUD
          comletionBlock:(void (^)(BOOL isSuccess))completionBlock;
@end

NS_ASSUME_NONNULL_END
