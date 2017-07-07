//
//  LYBaseRequest.swift
//
//  Copyright (c) 2017 LYNetwork https://github.com/ZakariyyaSv/LYNetwork
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

public enum LYRequestValidationErrorType: Int {
  case invalidStatusCode = -8
  case invalidJSONFormat = -9
}

///  HTTP Request method.
public enum LYRequestMethod {
  case GET
  case POST
  case HEAD
  case PUT
  case DELETE
  case PATCH
}

///  Request serializer type.
public enum LYRequestSerializerType {
  case HTTP
  case JSON
}

///  Response serializer type, which determines response serialization process and
///  the type of `responseObject`.
public enum LYResponseSerializerType {
  case HTTP
  case JSON
  case XMLParser
}

/// Request priority, which determines URLSessionTask priority
public enum LYRequestPriority: Int {
  case Low = -4
  case Default = 0
  case High = 4
}

///  The LYRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be 
///  called on the main queue.
public protocol LYRequestDelegate: class {
  ///  Tell the delegate that the request has finished successfully.
  func requestFinished(_ request: LYBaseRequest)
  ///  Tell the delegate that the request has failed.
  func requestFailed(_ request: LYBaseRequest)
}

///  The LYRequestAccessory protocol defines several optional methods that can be
///  used to track the status of a request. Objects that conforms this protocol
///  ("accessories") can perform additional configurations accordingly. All the
///  accessory methods will be called on the main queue.
public protocol LYRequestAccessory: class {
  ///  Inform the accessory that the request is about to start.
  ///  before executing `requestFinished` and `successCompletionBlock`.
  func requestWillStart(_ request: AnyObject)
  
  ///  Inform the accessory that the request is about to stop. This method is called
  ///  before executing `requestFinished` and `successCompletionBlock`.
  func requestWillStop(_ request: AnyObject)
  
  ///  Inform the accessory that the request has already stoped. This method is called
  ///  after executing `requestFinished` and `successCompletionBlock`.
  func requestDidStop(_ request: AnyObject)
}

public protocol LYRequestConfiguration: class {
  ///  Called on background thread after request succeded but before switching to main thread. Note if
  ///  cache is loaded, this method WILL be called on the main thread, just like `requestCompleteFilter`.
  func requestCompletePreprocessor()
  
  ///  Called on the main thread after request succeeded.
  func requestCompleteFilter()
  
  ///  Called on background thread after request succeded but before switching to main thread. See also
  ///  `requestCompletePreprocessor`.
  func requestFailedPreprocessor()
  
  ///  Called on the main thread when request failed.
  func requestFailedFilter()
  
  ///  The baseURL of request. This should only contain the host part of URL, e.g., http://www.example.com.
  ///  See also `requestUrl`
  func baseUrl() -> String
  
  ///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrl`.
  ///
  ///  @discussion This will be concated with `baseUrl` using URL.init(relativeTo: baseUrl).
  ///              Because of this, it is recommended that the usage should stick to rules stated above.
  ///              Otherwise the result URL may not be correctly formed. See also `URLString:relativeToURL`
  ///              for more information.
  ///
  ///              Additionaly, if `requestUrl` itself is a valid URL, it will be used as the result URL and
  ///              `baseUrl` will be ignored.
  func requestUrl() -> String
  
  ///  Use this to build custom request. If this method return non-nil value, `requestUrl`, `requestTimeoutInterval`,
  ///  `requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` will all be ignored.
  func buildCustomUrlRequest() -> URLRequest?
  
  ///  Optional CDN URL for request.
  func cdnUrl() -> String
  
  ///  Requset timeout interval. Default is 60s.
  func requestTimeoutInterval() -> TimeInterval
  
  ///  Additional request argument.
  func requestArgument() -> [String: Any]?
  
  ///  HTTP request method.
  func requestMethod() -> LYRequestMethod
  
  ///  Request serializer type.
  func requestSerializerType() -> LYRequestSerializerType
  
  ///  Response serializer type. See also `responseObject`.
  func responseSerializerType() -> LYResponseSerializerType
  
  ///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
  func requestAuthorizationHeaderFieldArray() -> Array<String>?
  
  ///  Additional HTTP request header field.
  func requestHeaderFieldValueDictionary() -> Dictionary<String, String>?
  
  ///  Should use CDN when sending request.
  func useCDN() -> Bool
  
  ///  Whether the request is allowed to use the cellular radio (if present). Default is YES.
  func allowsCellularAccess() -> Bool
  
  ///  The validator will be used to test if `responseJSONObject` is correctly formed.
  func jsonValidator() -> AnyObject?
  
  ///  This validator will be used to test if `responseStatusCode` is valid.
  func statusCodeValidator() -> Array<Int>
  
  ///  Override this method to filter requests with certain arguments when caching.
  func cacheFileNameFilterForRequestArgument(_ argument: [String: Any]?) -> [String: Any]?
}

public typealias LYBaseRequestCompletionHandler = (LYBaseRequest)->(Void)

///  LYBaseRequest is the abstract class of network request. It provides many options
///  for constructing request. It's the base class of `LYRequest`.
open class LYBaseRequest: LYRequestConfiguration {
  //  MARK: - Properties
  //  =========================================================
  //  MARK: Request and Response Information
  ///  The underlying NSURLSessionTask.
  open internal(set) var requestTask: URLSessionTask?
  
  ///  Shortcut for `requestTask.currentRequest`.
  public private(set) var currentRequest: URLRequest? {
    get {
      return self.requestTask?.currentRequest
    }
    set {
      self.currentRequest = newValue
    }
  }
  
  ///  Shortcut for `requestTask.originalRequest`.
  public private(set) var originalRequest: URLRequest? {
    get {
      return self.requestTask?.originalRequest
    }
    set {
      self.originalRequest = newValue
    }
  }
  
  ///  Shortcut for `requestTask.response`.
  public private(set) var response: HTTPURLResponse? {
    get {
      return self.requestTask?.response as? HTTPURLResponse
    }
    set {
      self.response = newValue
    }
  }
  
  ///  The response status code.
  public private(set) var responseStatusCode: Int {
    get {
      return (self.response?.statusCode)!
    }
    set {
      self.responseStatusCode = newValue
    }
  }
  
  ///  The response header fields.
  public private(set) var responseHeaders: Dictionary<AnyHashable, Any> {
    get {
      return (self.response?.allHeaderFields)!
    }
    set {
      self.responseHeaders = newValue
    }
  }
  var responseStatusValidateResult: Bool?
		
  ///  The raw data representation of response. Note this value can be nil if request failed.
  open var responseData: Data?
  
  ///  The string representation of response. Note this value can be nil if request failed.
  open var responseString: String?
  
  ///  If you use `Alamofire.responseJSON`, this is a convenience (and sematic) getter
  ///  for the response object. Otherwise this value is nil.
  open var responseJSON: Any?
  
  ///  This error can be either serialization error or network error. If nothing wrong happens
  ///  this value will be nil.
  open var error: Error?
  
  ///  Return cancelled state of request task.
  var isCancelled: Bool {
    get {
      guard self.requestTask != nil else {
        return false
      }
      return self.requestTask!.state == .canceling
    }
  }
  
  ///  Executing state of request task.
  var isExecuting: Bool {
    get {
      guard self.requestTask != nil else {
        return false
      }
      return self.requestTask!.state == .running
    }
  }
  
  
  //  MARK: Request Configuration
  ///  Tag can be used to identify request. Default value is 0.
  public var tag: Int = 0
  
  ///  The userInfo can be used to store additional info about the request. Default is nil.
  public var userInfo: Dictionary<String, Any>?
  
  ///  The delegate object of the request. If you choose block style callback you can ignore this.
  ///  Default is nil.
  public weak var delegate: LYRequestDelegate?
  
  ///  The success callback. Note if this value is not nil and `requestFinished` delegate method is
  ///  also implemented, both will be executed but delegate method is first called. This block
  ///  will be called on the main queue.
  public var successCompletionHandler: LYBaseRequestCompletionHandler?
  
  ///  The failure callback. Note if this value is not nil and `requestFailed` delegate method is
  ///  also implemented, both will be executed but delegate method is first called. This block
  ///  will be called on the main queue.
  public var failureCompletionHandler: LYBaseRequestCompletionHandler?
  
  ///  This can be used to add several accossories object. Note if you use `addAccessory` to add acceesory
  ///  this array will be automatically created. Default is nil.
  public var requestAccessories: [LYRequestAccessory]?
  
  ///  The priority of the request. Effective only on iOS 8+. Default is `YTKRequestPriorityDefault`.
  public var requestPriority: LYRequestPriority = .Default
  
  //  MARK: - Methods
  //  =========================================================
  //  MARK: Request Action
  ///  Append self to request queue and start the request.
  public func start() {
    self.toggleAccessoriesWillStartCallBack()
    LYNetworkAgent.sharedAgent.addRequest(self)
  }
  
  ///  Remove self from request queue and cancel the request.
  public func stop() {
    self.toggleAccessoriesWillStopCallBack()
    self.delegate = nil
    LYNetworkAgent.sharedAgent.cancelRequest(self)
    self.toggleAccessoriesDidStopCallBack()
  }
  
  ///  Convenience method to start the request with block callbacks.
  public func startWithCompletionHandler(success successHandler:LYBaseRequestCompletionHandler?, failure failureHandler: LYBaseRequestCompletionHandler?) {
    self.successCompletionHandler = successHandler
    self.failureCompletionHandler = failureHandler
    self.start()
  }
  
  ///  Nil out both success and failure callback blocks.
  public func clearCompletionHandler() {
    self.successCompletionHandler = nil
    self.failureCompletionHandler = nil
  }
}


extension LYRequestConfiguration {
  public func requestCompletePreprocessor() {}
  public func requestCompleteFilter() {}
  public func requestFailedPreprocessor() {}
  public func requestFailedFilter() {}
  public func baseUrl() -> String { return "" }
  public func requestUrl() -> String { return "" }
  public func buildCustomUrlRequest() -> URLRequest? { return nil }
  public func cdnUrl() -> String { return "" }
  public func requestTimeoutInterval() -> TimeInterval { return LYNetworkConfig.shared.requestTimeoutInterval }
  public func requestArgument() -> [String: Any]? { return nil }
  public func requestMethod() -> LYRequestMethod { return .GET }
  public func requestSerializerType() -> LYRequestSerializerType { return .HTTP }
  public func responseSerializerType() -> LYResponseSerializerType { return .HTTP }
  public func requestAuthorizationHeaderFieldArray() -> Array<String>? { return nil }
  public func requestHeaderFieldValueDictionary() -> Dictionary<String, String>? { return nil }
  public func useCDN() -> Bool { return false }
  public func allowsCellularAccess() -> Bool { return true }
  public func jsonValidator() -> AnyObject? { return nil }
  public func statusCodeValidator() -> Array<Int> {
    return Array(200..<300)
  }
  public func cacheFileNameFilterForRequestArgument(_ argument: [String: Any]?) -> [String: Any]? {
    return argument
  }
}


