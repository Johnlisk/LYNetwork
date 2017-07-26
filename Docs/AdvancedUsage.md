LYNetwork 使用高级教程
=====================

本教程将讲解 LYNetwork 的高级功能的使用。

## LYUrlFilterProtocol 接口

LYUrlFilterProtocol 接口用于实现对网络请求 URL 或参数的重写，例如可以统一为网络请求加上一些参数，或者修改一些路径。

例如：我们需要为每个网络请求加上客户端的版本号作为参数。所以我们实现了如下一个 `LYUrlArgumentsFilter` 类，实现了 `LYUrlFilterProtocol` 协议 :

```objectivec
class LYUrlArgumentsFilter: LYUrlFilterProtocol {

  private var arguments: Dictionary<String, Any>

  // MARK: Public Methods
  public class func filter(_ arguments: Dictionary<String, Any>) -> LYUrlArgumentsFilter {
    return LYUrlArgumentsFilter.init(arguments)
  }

  func filterUrl(url originalUrl: String, _ request: LYBaseRequest) -> String {
    return self.componentUrlString(originalUrl, appendParameters: self.arguments)
  }

  // MARK: Private Methods
  private init(_ arguments: Dictionary<String, Any>) {
    self.arguments = arguments
  }
}
```

通过以上 `LYUrlArgumentsFilter` 类，我们就可以用以下代码方便地为网络请求增加统一的参数，如增加当前客户端的版本号：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    LYNetworkConfig.shared.baseUrl = "http://api.******.com/"
    LYNetworkConfig.shared.debugLogEnabled = true
    return true
  }

  private func setupRequestFilters() {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let config = LYNetworkConfig.shared
    let urlFilter = LYUrlArgumentsFilter.filter(["version" : appVersion])
    config.addUrlFilter(urlFilter)
  }
```

## LYBatchRequest 类

LYBatchRequest 类：用于方便地发送批量的网络请求，LYBatchRequest 是一个容器类，它可以放置多个 `LYRequest` 子类，并统一处理这多个网络请求的成功和失败。

在如下的示例中，我们发送了 4 个批量的请求，并统一处理这 4 个请求同时成功的回调。

```swift

```

## LYChainRequest 类

用于管理有相互依赖的网络请求，它实际上最终可以用来管理多个拓扑排序后的网络请求。

例如，我们有一个需求，需要用户在登录时，先发送登录的 Api，然后 :
 * 如果登录成功，再发送读取用户信息的 Api。并且，读取用户信息的 Api 需要使用登录成功返回的用户 id 号。
 * 如果登录失败，则不发送读取用户信息的 Api 了。

以下是具体的代码示例，在示例中，我们在 `sendChainRequest` 方法中设置好了 Api 相互的依赖，然后。
我们就可以通过 `chainRequestFinished` 回调来处理所有网络请求都发送成功的逻辑了。如果有任何其中一个网络请求失败了，则会触发 `chainRequestFailed` 回调。

```swift
private func sendChainRequest() {
  let reg = loginApi.init("18510237166", "qwer1234")
  reg.delegate = self
  let chainReq = LYChainRequest()
  chainReq.addRequest(reg) { (chainRequest, baseRequest) -> (Void) in
    let login = baseRequest as! loginApi
    print("login response: \(String(describing: login.responseString))")
    let (userId, ticket) = login.userIdAndticket()
    if userId.characters.count > 0 && ticket.characters.count > 0 {
      let getUser = getUserInfoApi.init(userId, ticket)
      getUser.successCompletionHandler = { (request) in
        print("indexInfo response: \(String(describing: getUser.responseString))")
      }
      chainRequest.addRequest(getUser)
    }
  }
  chainReq.delegate = self
  chainReq.start()
}

func chainRequestFinished(_ request: LYChainRequest) {
  print("request success")
}

func chainRequestFailed(_ chainRequest: LYChainRequest, failedBaseRequest baseRequest: LYBaseRequest) {
  print("request failed")
}
```

## 显示上次缓存的内容

在实际开发中，有一些内容可能会加载很慢，我们想先显示上次的内容，等加载成功后，再用最新的内容替换上次的内容。也有时候，由于网络处于断开状态，为了更加友好，我们想显示上次缓存中的内容。这个时候，可以使用 LYReqeust 的直接加载缓存的高级用法。

具体的方法是直接使用 `LYRequest` 的 `loadCacheWithError` 方法，即可获得上次缓存的内容。当然，你需要把 `cacheTimeInSeconds` 覆盖，返回一个大于等于 0 的值，这样才能开启 LYRequest 的缓存功能，否则默认情况下，缓存功能是关闭的。

以下是一个示例，我们在加载用户信息前，先取得上次加载的内容，然后再发送请求，请求成功后再更新界面：

```swift
func loadCacheData() {
  let getUserApi = getUserInfoApi.init("1", "1234")
  do {
    let success = try getUserApi.loadCache()
    if success {
      return
    }
  } catch {

  }
  getUserApi.startWithCompletionHandler(success: { (request) -> (Void) in
    //  request successful
  }, failure: { (request) -> (Void) in
    //  request failed
  })
}

```

## 定制网络请求的 HeaderField

通过覆盖 `requestHeaderFieldValueDictionary` 方法返回一个 dictionary 对象来自定义请求的 HeaderField，返回的 dictionary，其 key 即为 HeaderField 的 key，value 为 HeaderField 的 Value，需要注意的是 key 和 value 都必须为 string 对象。若需要统一为所有请求添加自定义请求的 HeaderField，建议在 LYNetworkConfig的 requestHTTPHeaders 属性中添加。
