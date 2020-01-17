# 一个好用的社交化组件，目前支持微信(包含支付功能和不包含支付功能)、新浪微博、QQ、支付宝(暂时只支持支付，不支持授权，因为我也没做过授权🤣)

# 请根据自己项目的实际情况，导入对应的模块(重要的事情说3遍)
# 请根据自己项目的实际情况，导入对应的模块(重要的事情说3遍)
# 请根据自己项目的实际情况，导入对应的模块(重要的事情说3遍)
<br>
<br>
<br>
该开源库编写的初衷：替代友盟等三方库。因为友盟等三方库虽然使用起来比较方便，但是个人觉得太臃肿了。
<br>
<br>
<br>

# 该组件暂时不支持pod，请使用手动的方式集成进自己的项目中。
<br>
<br>

# 下载下来之后，请`pod install`，之后运行会提示缺少`SDK.h`文件，请自己新建一个同名文件。该文件是保存的APPID，key等各种常量的
```
#define WECHAT_APP_ID       @""
#define WECHAT_APP_SECRET   @""
#define QQ_APP_ID           @""
#define SINA_APP_KEY        @""
#define SINA_Redirect_URL   @""
```
<br>
<br>

### 1、必须导入的三方库

```
pod 'MBProgressHUD'
pod 'AFNetworking/Serialization'
pod 'AFNetworking/Security'
pod 'AFNetworking/Reachability'
pod 'AFNetworking/NSURLSession'
```

### 2、`Podfile`文件里加上`use_frameworks!`
### 3、源文件里面`Core`文件夹是必须导入的
### 4、关于微信：如果你的应用包含支付功能，请导入`WeiXin Pay`文件夹，否则不要导入。另外请自行前往微信官方下载包含支付功能的SDK，否则请下载不包含支付功能的SDK

# 总结
#### 1、友盟等三方分享SDK虽然使用起来比较方便，但是有很多限制。比如一个App如果运营到后期，肯定不止分享和登录这么简单的功能。比如要集成微信支付，这个时候使用友盟自带的微信SDK是完不成的，即使使用完整版，因为APP无法调用友盟自带的微信SDK里面的API。再比如也许会增加获取我的微博列表，同样无法使用友盟自带的微博SDK完成。这个时候，即必须要再次导入微信或者微博SDK才能完成。换句话说，友盟等三方分享SDK，仅仅只是为分享和登录服务的，无法完成其他功能。在项目前期使用友盟确实比较方便，但是项目后期，继续使用友盟个人觉得不是很合适。
#### 2、在使用友盟完整版的情况下，要使用微信支付、获取微博列表等这些功能，也无法完成，除非自己再次导入SDK。
#### 3、在第一次打开三方应用时，iOS系统会给用户一个选项，即"是否允许打开xxx"的这个一个弹出框，这个弹出框属于系统级别，开发者无法获取到用户到底是点击了"确定"还是"取消"。如果界面上有一个按钮，点击这个按钮时，会有个loading圈显示，如果这个时候用户点击了"取消"，那么loading圈仍然在继续显示，无法取消，本人已经看到很多APP都有这个问题；另外，即使用户点击了"确定"按钮，跳转到了三方应用了，这个时候，如果用户点击屏幕左上角返回APP，loading圈仍然在加载，因为开发者仍然获取不到用户点击屏幕左上角这个事件。`YHThirdManager`完美的解决了这些问题








