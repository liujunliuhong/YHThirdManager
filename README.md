# YHThirdManager
一个好用的社交化组件，目前支持微信、新浪微博、QQ

# 🔥即将增加FaceBook，谷歌、苹果登录

### Demo运行
下载下来之后，请执行`pod install`，运行会提示缺少`SDK.h`文件，该文件是保存的APPID，key等各种常量的，请自行新建一个同名文件，然后添加上以下宏定义。
```
#define WECHAT_APP_ID             @""
#define WECHAT_APP_SECRET         @""
#define WECHAT_Universal_Links    @""

#define QQ_APP_ID                 @""
#define QQ_Universal_Links        @""

#define SINA_APP_KEY              @""
#define SINA_Redirect_URL         @""
```
<br>

### 注意事项
- 该库依赖于`MBProgressHUD`和`AFNetworking`，请在自己项目中的`Podfile`里面加上这两个库。


```
pod 'MBProgressHUD'
pod 'AFNetworking'
```

- Demo里面的`微信SDK`，`QQ SDK`有可能不是最新版本，请自行去对应网站下载最新版本进行替换。（`微博 SDK`是通过pod的形式导入的）

<br/>
## 安装
目前支持手动方式安装，不支持`pod`。
###### 微信模块
- `Core`：核心模块，必须导入
- `WeiXin`：初始化、处理微信回调、微信登录、微信分享
- `WeiXin Pay`：微信支付模块。如果导入了该模块，那么`Core`和`WeiXin`必须导入

###### QQ

###### 新浪


<br/>

## 使用方法
### 一、微信相关功能
##### 初始化
初始化非常简单
```
- (void)initWithAppID:(NSString *)appID
            appSecret:(nullable NSString *)appSecret
        universalLink:(NSString *)universalLink;
```
##### 处理微信回调
```
// 9.0之后
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [[YHWXManager sharedInstance] handleOpenURL:url];
    return YES;
}

// 9.0之前
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    [[YHWXManager sharedInstance] handleOpenURL:url];
    return YES;
}

// 测试发现，在模拟器上，未安装微博，使用网页打开微博，点击取消，程序崩溃，加上下面这个方法后，程序正常运行
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [[YHWXManager sharedInstance] handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    [[YHWXManager sharedInstance] handleOpenUniversalLink:userActivity];
    return YES;
}
```

##### 获取用户信息（微信登录）
通过查看微信开发者文档，发现通过微信SDK不能直接获取到用户信息，要获取用户信息，需要由3个步骤:
- 通过微信SDK获取code

```
- (void)authForGetCodeWithShowHUD:(BOOL)showHUD
                  completionBlock:(void(^_Nullable)(BOOL isGetCodeSuccess))completionBlock;
```
该方法回调的是一个block，如果获取code成功，`isGetCodeSuccess`会回调`YES`，同时code会保存在`YHWXManager`的`code`属性里面

```
NSString *code = [YHWXManager sharedInstance].code; // 拿到code
```

- 通过上一步获取到的`code`去获取`AccessToken`

```
- (void)authForGetAccessTokenWithAppID:(NSString *)appID
                             appSecret:(NSString *)appSecret
                                  code:(NSString *)code
                               showHUD:(BOOL)showHUD
                       completionBlock:(void(^_Nullable)(BOOL isGetAccessTokenSuccess))completionBlock;
```
`appID`和`appSecret`可以从微信开发者后台获取到。该方法回调的是一个block，如果获取`AccessToken`成功，`isGetAccessTokenSuccess`会回调`YES`，同时相关信息会保存在`YHWXAuthResult`里面。
```
YHWXAuthResult *authResult = [YHWXManager sharedInstance].authResult;
NSString *openID = authResult.openID;
NSString *accessToken = authResult.accessToken;
```
`openID`和`accessToken`在最终获取用户信息的时候会用到。

- 获取用户信息

```
- (void)getUserInfoWithOpenID:(NSString *)openID
                  accessToken:(NSString *)accessToken
                      showHUD:(BOOL)showHUD
              completionBlock:(void(^_Nullable)(BOOL isGetUserInfoSuccess))completionBlock;
```
该方法回调的是一个block，如果获取用户信息成功，`isGetUserInfoSuccess`会回调`YES`。同时相关信息会保存在`YHWXUserInfo`里面。
```
YHWXUserInfo *userInfo = [YHWXManager sharedInstance].userInfo;
```


##### 微信分享网页
```
- (void)shareWebWithURL:(NSString *)URL
                  title:(nullable NSString *)title
            description:(nullable NSString *)description
             thumbImage:(nullable UIImage *)thumbImage
              shareType:(YHWXShareType)shareType
                showHUD:(BOOL)showHUD
        completionBlock:(void(^_Nullable)(BOOL isSuccess))completionBlock;
```

##### 微信支付
微信支付是一个单独的模块，如果你的应用不包含微信支付，请不要导入，否则可能会被拒。
```
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
```


### 二、QQ相关功能

### 三、新浪相关功能







# 总结
&emsp;&emsp;友盟等三方分享SDK虽然使用起来比较方便，但是有很多限制。比如一个App如果运营到后期，肯定不止分享和登录这么简单的功能。比如要集成微信支付，这个时候使用友盟自带的微信SDK是完不成的，即使使用完整版，因为APP无法调用友盟自带的微信SDK里面的API。再比如也许会增加获取我的微博列表，同样无法使用友盟自带的微博SDK完成。这个时候，必须要再次导入微信或者微博SDK才能完成。换句话说，友盟等三方分享SDK，仅仅只是为分享和登录服务的，无法完成其他功能。在项目前期使用友盟确实比较方便，但是项目后期，继续使用友盟个人觉得不是很合适。
&emsp;&emsp;在使用友盟完整版的情况下，要使用微信支付、获取微博列表等这些功能，也无法完成，除非自己再次导入SDK。
&emsp;&emsp;在第一次打开三方应用时，iOS系统会给用户一个选项，即"是否允许打开xxx"的这个一个弹出框，这个弹出框属于系统级别，开发者无法获取到用户到底是点击了"确定"还是"取消"。如果界面上有一个按钮，点击这个按钮时，会有个loading圈显示，如果这个时候用户点击了"取消"，那么loading圈仍然在继续显示，无法取消，本人已经看到很多APP都有这个问题；另外，即使用户点击了"确定"按钮，跳转到了三方应用了，这个时候，如果用户点击屏幕左上角返回APP，loading圈仍然在加载，因为开发者仍然获取不到用户点击屏幕左上角这个事件。`YHThirdManager`完美的解决了这些问题








