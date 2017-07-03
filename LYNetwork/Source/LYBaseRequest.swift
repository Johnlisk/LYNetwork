//
//  LYBaseRequest.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

public enum LYRequestValidationErrorType: Int {
  case invalidStatusCode = -8
  case invalidJSONFormat = -9
}

public enum LYRequestMethod {
  case GET
  case POST
  case HEAD
  case PUT
  case DELETE
  case PATCH
}

public enum LYRequestSerializerType {
  case HTTP
  case JSON
}

public enum LYResponseSerializerType {
  case HTTP
  case JSON
  case XMLParser
}

public enum LYRequestPriority: Int {
  case Low = -4
  case Default = 0
  case High = 4
}

///  The YTKRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue.
public protocol LYRequestDelegate: class {
  ///  Tell the delegate that the request has finished successfully.
  func requestFinished(_ request: LYBaseRequest)
  ///  Tell the delegate that the request has failed.
  func requestFailed(_ request: LYBaseRequest)
}

///  The YTKRequestAccessory protocol defines several optional methods that can be
///  used to track the status of a request. Objects that conforms this protocol
///  ("accessories") can perform additional configurations accordingly. All the
///  accessory methods will be called on the main queue.
public protocol LYRequestAccessory: class {
  ///  Inform the accessory that the request is about to start.
  ///  before executing `requestFinished` and `successCompletionBlock`.
  func requestWillStart(_ request: AnyObject)
  
  ///  Inform the accessory that the request has already stoped. This method is called
  ///  after executing `requestFinished` and `successCompletionBlock`.
  func requestWillStop(_ request: AnyObject)
  func requestDidStop(_ request: AnyObject)
}

public protocol LYRequestConfiguration: class {
  func requestCompletePreprocessor()
  func requestCompleteFilter()
  func requestFailedPreprocessor()
  func requestFailedFilter()
  func baseUrl() -> String
  func requestUrl() -> String
  func buildCustomUrlRequest() -> URLRequest?
  func cdnUrl() -> String
  func requestTimeoutInterval() -> TimeInterval
  func requestArgument() -> [String: Any]?
  func requestMethod() -> LYRequestMethod
  func requestSerializerType() -> LYRequestSerializerType
  func responseSerializerType() -> LYResponseSerializerType
  func requestAuthorizationHeaderFieldArray() -> Array<String>?
  func requestHeaderFieldValueDictionary() -> Dictionary<String, String>?
  func useCDN() -> Bool
  func allowsCellularAccess() -> Bool
  func jsonValidator() -> AnyObject?
  func statusCodeValidator() -> Array<Int>
  func cacheFileNameFilterForRequestArgument(_ argument: [String: Any]?) -> [String: Any]?
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

public typealias LYBaseRequestCompletionHandler = (LYBaseRequest)->(Void)

///  YTKBaseRequest is the abstract class of network request. It provides many options
///  for constructing request. It's the base class of `YTKRequest`.
open class LYBaseRequest: LYRequestConfiguration {
  //  MARK: - Properties
  //  =========================================================
  //  MARK: Request and Response Information
  ///  The underlying NSURLSessionTask.
  open internal(set) var requestTask: URLSessionTask?
  
  ///  Shortcut for `requestTask.currentRequest`.
  open var currentRequest: URLRequest? {
    get {
      return self.requestTask?.currentRequest
    }
  }
  
  ///  Shortcut for `requestTask.originalRequest`.
  open var originalRequest: URLRequest? {
    get {
      return self.requestTask?.originalRequest
    }
  }
  
  ///  Shortcut for `requestTask.response`.
  private(set) var response: HTTPURLResponse?
  
  ///  The response status code.
  open var responseStatusCode: Int {
    get {
      return (self.response?.statusCode)!
    }
  }
  
  ///  The response header fields.
  open var responseHeaders: Dictionary<AnyHashable, Any> {
    get {
      return (self.response?.allHeaderFields)!
    }
  }
  var responseStatusValidateResult: Bool?
		
  ///  The raw data representation of response. Note this value can be nil if request failed.
  open var responseData: Data?
  open var responseString: String?
  open var responseJSON: Any?
  open var error: Error?
  
  var isCancelled: Bool {
    get {
      guard self.requestTask == nil else {
        return false
      }
      return self.requestTask!.state == .canceling
    }
  }
  var isExecuting: Bool {
    get {
      guard self.requestTask == nil else {
        return false
      }
      return self.requestTask!.state == .running
    }
  }
  
  
  //  MARK: - Request Configuration
  public var tag: Int = 0
  public var userInfo: Dictionary<String, Any>?
  public var successCompletionHandler: LYBaseRequestCompletionHandler?
  public var failureCompletionHandler: LYBaseRequestCompletionHandler?
  public var requestAccessories: [LYRequestAccessory]?
  public weak var delegate: LYRequestDelegate?
  public var requestPriority: LYRequestPriority = .Default
  
  //  MARK: - Request Action
  public func start() {
    self.toggleAccessoriesWillStartCallBack()
    LYNetworkAgent.sharedAgent.addRequest(self)
  }
  
  public func stop() {
    self.toggleAccessoriesWillStopCallBack()
    self.delegate = nil
    LYNetworkAgent.sharedAgent.cancelRequest(self)
    self.toggleAccessoriesDidStopCallBack()
  }
  
  public func startWithCompletionHandler(success successHandler:LYBaseRequestCompletionHandler?, failure failureHandler: LYBaseRequestCompletionHandler?) {
    self.successCompletionHandler = successHandler
    self.failureCompletionHandler = failureHandler
    self.start()
  }
  
  public func clearCompletionHandler() {
    self.successCompletionHandler = nil
    self.failureCompletionHandler = nil
  }
  
}


