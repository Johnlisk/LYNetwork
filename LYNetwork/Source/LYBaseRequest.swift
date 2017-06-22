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

public protocol LYRequestDelegate: class {
  func requestFinished(_ request: LYBaseRequest)
  func requestFailed(_ request: LYBaseRequest)
}

public protocol LYRequestAccessory: class {
  func requestWillStart(_ request: Any)
  func requestWillStop(_ request: Any)
  func requestDidStop(_ request: Any)
}


public typealias LYRequestCompletionHandler = (LYBaseRequest)->(Void)

open class LYBaseRequest {
  //  MARK: Properties
  //  =========================================================
  //  MARK: Request and Response Information
  private(set) var requestTask: URLSessionTask?
  public var currentRequest: URLRequest? {
    get {
      return self.requestTask.currentRequest
    }
  }
  public var originalRequest: URLRequest? {
    get {
      return self.requestTask.originalRequest
    }
  }
  private(set) var response: HTTPURLResponse
  public var responseStatusCode: Int {
    get {
      return self.response.statusCode
    }
  }
  public var responseHeaders: Dictionary<AnyHashable, Any> {
    get {
      return self.response.allHeaderFields
    }
  }
  private(set) var responseData: Data?
  private(set) var responseString: String?
  private(set) var responseObject: Any?
  private(set) var responseJSONObject: Any?
  private(set) var error: Error?
  
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
  
  
  //  MARK: Request Configuration
  public var tag: Int = 0
  public var userInfo: Dictionary?
  public var successCompletionHandler: LYRequestCompletionHandler?
  public var failureCompletionHandler: LYRequestCompletionHandler?
  public weak var delegate: LYRequestDelegate?
  public var requestPriority: LYRequestPriority?
  
  //  MARK: Request Action
  public func start() {
    
  }
  
  public func stop() {
    
  }
  
  public func startWithCompletionHandler(success successHandler:LYRequestCompletionHandler?, failure: LYRequestCompletionHandler?) {
    
  }
  
  //  MARK: Subclass Override
  public func requestCompletePreprocessor() {}
  public func requestCompleteFilter() {}
  public func requestFailedPreprocessor() {}
  public func requestFailedFilter() {}
  public func baseUrl() -> String { return "" }
  public func requestUrl() -> String { return "" }
  public func cdnUrl() -> String { return "" }
  public func requestTimeoutInterval() -> TimeInterval { return 60 }
  public func requestArgument() -> Any? { return nil }
  public func requestMethod() -> LYRequestMethod { return .GET }
  public func requestSerializerType() -> LYRequestSerializerType { return .HTTP }
  public func responseSerializerType() -> LYResponseSerializerType { return .JSON }
  public func requestAuthorizationHeaderFieldArray() -> Array<String>? { return nil }
  public func requestHeaderFieldValueDictionary() -> Dictionary<String, String>? { return nil }
  public func useCDN() -> Bool { return false }
  public func allowsCellularAccess() -> Bool { return true }
  public func jsonValidator() -> Any? { return nil }
  public func statusCodeValidator() -> Bool {
    let statusCode: Int = self.responseStatusCode
    return statusCode >= 200 && statusCode <= 299
  }
  
  // MARK: Description
  
  
}

