//
//  YHThirdHttpRequest.h
//  YHThirdManager
//
//  Created by 银河 on 2019/11/3.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YHThirdHttpRequestMethod) {
    YHThirdHttpRequestMethodGET,
    YHThirdHttpRequestMethodPOST,
};

@interface YHThirdHttpRequest : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)urlTranscoding:(NSString *)url;

- (void)requestWithURL:(NSString *)url
                method:(YHThirdHttpRequestMethod)method
             parameter:(nullable NSDictionary *)parameter
          successBlock:(void(^)(id responseObject))successBlock
          failureBlock:(void(^)(NSError *error))failureBlock;
@end

NS_ASSUME_NONNULL_END
