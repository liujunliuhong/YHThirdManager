//
//  YHThirdDefine.h
//  YHThirdManager
//
//  Created by 银河 on 2019/11/3.
//  Copyright © 2019 yinhe. All rights reserved.
//

#ifndef YHThirdDefine_h
#define YHThirdDefine_h

#if __has_include(<MBProgressHUD/MBProgressHUD.h>)
#import <MBProgressHUD/MBProgressHUD.h>
#elif __has_include("MBProgressHUD.h")
#import "MBProgressHUD.h"
#endif

#ifdef DEBUG
    #define YHThirdDebugLog(format, ...)  printf("[👉] %s\n", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])
#else
    #define YHThirdDebugLog(format, ...)
#endif

#define YHThirdError(__msg__)            [NSError errorWithDomain:@"com.yinhe.yhthird.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: __msg__}]


#define YHThird_WeakSelf    __weak typeof(self) weakSelf = self;


#define YHThird_Color(R, G, B, A)      [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]


#define YHThird_GetHud \
({ \
MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES]; \
hud.mode = MBProgressHUDModeIndeterminate; \
hud.contentColor = YHThird_Color(255, 255, 255, 1); \
hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor; \
hud.bezelView.color = [YHThird_Color(0, 0, 0, 1) colorWithAlphaComponent:0.7]; \
hud.removeFromSuperViewOnHide = YES; \
(hud); \
})


#define YHThird_HideHud(hud) \
if (hud) { \
[hud hideAnimated:YES]; \
} \




#endif /* YHThirdDefine_h */
