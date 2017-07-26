LYNetwork 使用教程
=====================

本教程将讲解 LYNetwork 的基本功能的使用。


## LYNetwork 基本组成

LYNetwork 包括以下几个基本的类：

 * LYNetworkConfig 类：用于统一设置网络请求的服务器和 CDN 的地址。
 * LYRequest 类：所有的网络请求类需要继承于 `LYRequest` 类，每一个 `LYRequest` 类的子类代表一种专门的网络请求。

接下来我们详细地来解释这些类以及它们的用法。

### LYNetworkConfig 类

LYNetworkConfig 类有两个作用：

 1. 统一设置网络请求的服务器和 CDN 的地址。
 2. 管理网络请求的 YTKUrlFilterProtocol 实例（在[高级功能教程](ProGuide_cn.md) 中有介绍）。

具体的用法是，在程序刚启动的回调中，设置好 YTKNetworkConfig 的信息，如下所示：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    LYNetworkConfig.shared.baseUrl = "http://api.emodou.com/"
    LYNetworkConfig.shared.debugLogEnabled = true
    return true
  }
```

设置好之后，所有的网络请求都会默认使用 YTKNetworkConfig 中 `baseUrl` 参数指定的地址。

大部分企业应用都需要对一些静态资源（例如图片、js、css）使用 CDN。YTKNetworkConfig 的 `cdnUrl` 参数用于统一设置这一部分网络请求的地址。

当我们需要切换服务器地址时，只需要修改 YTKNetworkConfig 中的 `baseUrl` 和 `cdnUrl` 参数即可。

### LYRequest 类

LYNetwork 的基本的思想是把每一个网络请求封装成对象。所以使用 LYNetwork，你的每一种请求都需要继承 LYRequest 类，通过覆盖父类的一些方法来构造指定的网络请求。把每一个网络请求封装成对象其实是使用了设计模式中的 Command 模式。

每一种网络请求继承 LYRequest 类后，需要用方法覆盖（overwrite）的方式，来指定网络请求的具体信息。如下是一个示例：

假如我们要向网址 `http://api.emodou.com/login` 发送一个 `POST` 请求，请求参数是 phone 和 password。那么，这个类应该如下所示：

```swift
class loginApi: LYRequest {

  private var phone: String
  private var password: String

  public init(_ username: String, _ password: String) {
    self.phone = username
    self.password = password
    super.init()
  }

  public func userIdAndticket() -> (String, String) {
    guard let response = (self.responseJSON as? Dictionary<String, Any>) else {
      return ("", "")
    }
    return (response["userId"] as! String, response["ticket"] as! String)
  }

  override func requestUrl() -> String {
    return "login"
  }

  override func requestMethod() -> LYRequestMethod {
    return .POST
  }

  override func responseSerializerType() -> LYResponseSerializerType {
    return .JSON
  }

  override func requestArgument() -> [String : Any]? {
    return ["phone" : self.phone, "password" : self.password]
  }
}
```

在上面这个示例中，我们可以看到：

 * 我们通过覆盖 LYRequest 类的 `requestUrl` 方法，实现了指定网址信息。并且我们只需要指定除去域名剩余的网址信息，因为域名信息在 YTKNetworkConfig 中已经设置过了。
 * 我们通过覆盖 LYRequest 类的 `requestMethod` 方法，实现了指定 POST 方法来传递参数。
 * 我们通过覆盖 LYRequest 类的 `requestArgument` 方法，提供了 POST 的信息。这里面的参数 `phone` 和 `password` 如果有一些特殊字符（如中文或空格），也会被自动编码。

## 调用 LoginApi

在构造完成 LoginApi 之后，具体如何使用呢？我们可以在登录的 ViewController 中，调用 LoginApi，并用 block 的方式来取得网络请求结果：

```swift
func loginButtonPressed() {
    let phone = self.PhoneTextField.text;
    let password = self.PasswordTextField.text;
    if (phone.characters.count > 0 && password.characters.count > 0) {
        let *api = LoginApi(phone, password);
        api.startWithCompletionHandler(success: { (request) -> (Void) in
            // 你可以直接在这里使用 self
            print(@"succeed");
        }, failure: { (request) -> (Void) in
            // 你可以直接在这里使用 self
            print(@"failed");
        })
    }
}

```

注意：你可以直接在闭包回调中使用 `self`，不用担心循环引用。因为 LYRequest 会在执行完闭包 回调之后，将相应的闭包设置成 nil。从而打破循环引用。

除了 closure 的回调方式外，LYRequest 也支持 delegate 方式的回调：

```swift
func loginButtonPressed() {
    let phone = self.PhoneTextField.text;
    let password = self.PasswordTextField.text;
    if (phone.characters.count > 0 && password.characters.count > 0) {
        let *api = LoginApi(phone, password);
        api.delegate = self
    }
}

func requestFinished(_ request: LYBaseRequest) {
    print("request success")
}

func requestFailed(_ request: LYBaseRequest) {
    print("request failure")
}
```

## 使用 CDN 地址

如果要使用 CDN 地址，只需要覆盖 LYRequest 类的 `- (BOOL)useCDN;` 方法。

例如我们有一个取图片的接口，地址是 `http://fen.bi/image/imageId` ，则我们可以这么写代码 :

```swift
class getImageApi: LYRequest {

  private var imageId: String

  init(_ imageId: String) {
    self.imageId = imageId
    super.init()
  }

  override func requestUrl() -> String {
    return "iphone/images/" + self.imageId
  }

  override func useCDN() -> Bool {
    return true
  }
}
```

## 按时间缓存内容

刚刚我们写了一个 GetUserInfoApi ，这个网络请求是获得用户的一些资料。

我们想像这样一个场景，假设你在完成一个类似微博的客户端，GetUserInfoApi 用于获得你的某一个好友的资料，因为好友并不会那么频繁地更改昵称，那么短时间内频繁地调用这个接口很可能每次都返回同样的内容，所以我们可以给这个接口加一个缓存。

在如下示例中，我们通过覆盖 `cacheTimeInSeconds` 方法，给 GetUserInfoApi 增加了一个 3 分钟的缓存，3 分钟内调用调 Api 的 start 方法，实际上并不会发送真正的请求。

```swift
class getUserInfoApi: LYRequest {
  private var userId: String
  private var ticket: String

  public init(_ userId: String, _ ticket: String) {
    self.userId = userId
    self.ticket = ticket
    super.init()
  }

  override func requestUrl() -> String {
    return "getUserInfo"
  }

  override func requestArgument() -> [String : Any]? {
    return ["userId" : self.userId, "ticket" : self.ticket]
  }

  override func cacheTimeInSeconds() -> Int {
    return 60 * 3
  }
}
```

该缓存逻辑对上层是透明的，所以上层可以不用考虑缓存逻辑，每次调用 GetUserInfoApi 的 start 方法即可。GetUserInfoApi 只有在缓存过期时，才会真正地发送网络请求。
