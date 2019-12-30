//
//  YHThirdHttpRequest.m
//  YHThirdManager
//
//  Created by 银河 on 2019/11/3.
//  Copyright © 2019 yinhe. All rights reserved.
//

#import "YHThirdHttpRequest.h"
@import AFNetworking;

#define kTimeOutInterval        60

@interface YHThirdHttpRequest ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) AFJSONRequestSerializer *requestSerializerForJSON;
@property (nonatomic, strong) AFJSONResponseSerializer *responseSerializerForJSON;

@end

@implementation YHThirdHttpRequest

+ (instancetype)sharedInstance{
    static YHThirdHttpRequest *request = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        request = [[self alloc] init];
    });
    return request;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // sessionManager
        self.sessionManager = [AFHTTPSessionManager manager];
        // requestSerializerForJSON
        self.requestSerializerForJSON = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONReadingAllowFragments | NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers];
        self.requestSerializerForJSON.timeoutInterval = kTimeOutInterval;
        [self.requestSerializerForJSON setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        // responseSerializerForJSON
        self.responseSerializerForJSON = [AFJSONResponseSerializer serializer];
        self.responseSerializerForJSON.acceptableContentTypes = [NSSet setWithObjects:
                                                                 @"application/json",
                                                                 @"text/json",
                                                                 @"text/javascript",
                                                                 @"text/html",
                                                                 @"text/css",
                                                                 @"text/xml",
                                                                 @"text/plain",
                                                                 @"application/javascript",
                                                                 @"image/*",
                                                                 nil];
    }
    return self;
}

- (void)requestWithURL:(NSString *)url
                method:(YHThirdHttpRequestMethod)method
             parameter:(NSDictionary *)parameter
          successBlock:(void (^)(id _Nonnull))successBlock
          failureBlock:(void (^)(NSError * _Nonnull))failureBlock{
    NSString *newURL = [self urlTranscoding:url];
    switch (method) {
        case YHThirdHttpRequestMethodPOST:
        {
            [self POST_WithURL:newURL param:parameter successBlock:successBlock errorBlock:failureBlock];
        }
            break;
        case YHThirdHttpRequestMethodGET:
        {
            [self GET_WithURL:newURL param:parameter successBlock:successBlock errorBlock:failureBlock];
        }
            break;
        default:
            break;
    }
}

- (NSURLSessionDataTask *)POST_WithURL:(NSString *)url
                                 param:(NSDictionary *)param
                          successBlock:(void(^)(id responseObject))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock{
    NSURLSessionDataTask *task = [self.sessionManager POST:url parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (errorBlock) {
            errorBlock(error);
        }
    }];
    return task;
}

- (NSURLSessionDataTask *)GET_WithURL:(NSString *)url
                                param:(NSDictionary *)param
                         successBlock:(void(^)(id responseObject))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock{
    NSURLSessionDataTask *task = [self.sessionManager GET:url parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (errorBlock) {
            errorBlock(error);
        }
    }];
    return task;
}

- (NSString *)urlTranscoding:(NSString *)url{
    NSString *transcodingString = @"";
    if (url.length == 0 || !url) {
        return transcodingString;
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    NSString * kCharactersGeneralDelimitersToEncode = @":#[]@";
    NSString * kCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    NSMutableCharacterSet *allowedCharacterSet = (NSMutableCharacterSet *)[NSMutableCharacterSet URLQueryAllowedCharacterSet];
    [allowedCharacterSet removeCharactersInString:[kCharactersGeneralDelimitersToEncode stringByAppendingString:kCharactersSubDelimitersToEncode]];
    transcodingString = [url stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
#else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    transcodingString = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
#endif
    return transcodingString;
}
@end
