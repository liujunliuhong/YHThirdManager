//
//  YHAlipayManager.h
//  YHThirdManager
//
//  Created by apple on 2020/1/17.
//  Copyright © 2020 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 支付宝相关功能封装
 * SDK版本:v15.6.8
 * 文档:https://docs.open.alipay.com/204/105295/
 */
@interface YHAlipayManager : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


/// handleOpenURL
/// @param URL URL
- (void)handleOpenURL:(NSURL *)URL;


/// 支付
/// @param order 订单参数，从服务端获取
/// @param scheme scheme
/// @param completionBlock 回调
- (void)payWithOrder:(NSString *)order
              scheme:(NSString *)scheme
     completionBlock:(void(^_Nullable)(NSDictionary *resultDic))completionBlock;

@end

NS_ASSUME_NONNULL_END
