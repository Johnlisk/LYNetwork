//
//  LYNetworkAgent.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

import Alamofire

class LYNetworkAgent {
  
  // MARK: Singleton
  static let sharedAgent = LYNetworkAgent()
  
  // MARK: Private Properties
  private var manager: SessionManager
  private var config: LYNetworkConfig
  private var requestsRecord: Dictionary<NSNumber, LYBaseRequest>
  private var processingQueue: DispatchQueue
  private var mutex: Mutex
  
  //  MARK: Initialization
  init() {
    self.config = LYNetworkConfig.sharedConfig
    self.manager = SessionManager.init(configuration: self.config.sessionConfiguration)
    
    let requestHTTPHeaders = self.config.requestHTTPHeaders
    if requestHTTPHeaders != nil && requestHTTPHeaders!.count > 0 {
      let requestAdapter = LYRequestAdapter()
      requestAdapter.AdditionalHTTPHeaders = requestHTTPHeaders!
      self.manager.adapter = requestAdapter
    }
    self.requestsRecord = Dictionary.init()
    self.processingQueue = DispatchQueue.init(label: "com.lynetwork.processing")
    self.mutex = Mutex()
  }
  
  //  MARK: Actions
  public func addRequest(_ request: LYBaseRequest) {
    let customUrlRequest: URLRequest? = request.buildCustomUrlRequest()
    if customUrlRequest != nil {
      
      let afRequest = self.manager.request(customUrlRequest!)
      request.requestTask = afRequest.task
    } else {
      request.requestTask = self.sessionTaskForRequest(request)
    }
    
    assert(request.requestTask != nil, "requestTask should not be nil")
    /// Set request task priority
    /// !!Available on iOS 8 +
    if #available(iOS 8.0, *) {
      switch request.requestPriority {
      case .High:
        request.requestTask?.priority = URLSessionTask.highPriority
      case .Default:
        request.requestTask?.priority = URLSessionTask.defaultPriority
      case .Low:
        request.requestTask?.priority = URLSessionTask.lowPriority
      }
    }
    
    /// Retain request
    self.addRequestToRecord(request)
    request.requestTask?.resume()
  }
  
  public func cancelRequest(_ request: LYBaseRequest) {
    request.requestTask?.cancel()
    self.removeRequestFromRecord(request)
    request.clearCompletionHandler()
    
  }
  
  public func cancelAllRequest(_ request: LYBaseRequest) {
    
    self.mutex.lock()
    let allKeys = self.requestsRecord.keys
    self.mutex.unlock()
    
    if allKeys.count > 0 {
      _ = allKeys.map({ (key) -> Void in
        self.mutex.lock()
        let request = self.requestsRecord[key]
        self.mutex.unlock()
        /// We are using non-recursive lock.
        /// Do not lock `stop`, otherwise deadlock may occur.
        request?.stop()
      })
    }
  }
  
  public func addRequestToRecord(_ request: LYBaseRequest) {
    self.mutex.lock()
    self.requestsRecord[NSNumber.init(integerLiteral: request.requestTask!.taskIdentifier)] = request
    self.mutex.unlock()
  }
  
  public func removeRequestFromRecord(_ request: LYBaseRequest) {
    self.mutex.lock()
    self.requestsRecord.removeValue(forKey: NSNumber.init(integerLiteral: request.requestTask!.taskIdentifier))
    self.mutex.unlock()
  }
  
  public func buildRequestUrl(_ request: LYBaseRequest) -> String {
    var detailUrl: String = request.requestUrl()
    let temp = URL.init(string: detailUrl)
    
    /// If detailUrl is valid URL
    if temp != nil && temp!.host != nil && temp!.scheme != nil {
      return detailUrl;
    }
    
    for f in self.config.urlFilters {
      detailUrl = f.filterUrl(url: detailUrl, request)
    }
    
    var baseUrl: String = ""
    if request.useCDN() {
      if request.cdnUrl().characters.count > 0 {
        baseUrl = request.cdnUrl()
      }
      else {
        baseUrl = self.config.cdnUrl
      }
    }
    else {
      if request.baseUrl().characters.count > 0 {
        baseUrl = request.baseUrl()
      }
      else {
        baseUrl = self.config.baseUrl
      }
    }
    
    /// URL slash compability
    var url = URL.init(string: baseUrl)!
    if baseUrl.characters.count > 0 && !baseUrl.hasSuffix("/") {
      url = url.appendingPathComponent("")
    }
    return URL.init(string: detailUrl, relativeTo: url)!.absoluteString
  }
  
  
  public func sessionTaskForRequest(_ request: LYBaseRequest) -> URLSessionTask? {
    let method: LYRequestMethod = request.requestMethod()
    let url = self.buildRequestUrl(request)
    let param = request.requestArgument()
    
    self.manager.session.configuration.timeoutIntervalForRequest = request.requestTimeoutInterval()
    self.manager.session.configuration.allowsCellularAccess = request.allowsCellularAccess()
    
    switch method {
    case .GET:
      return self.createDataTask(URLString: url, HTTPMethod: .get, parameters: param, request)
    case .POST:
      return self.createDataTask(URLString: url, HTTPMethod: .post, parameters: param, request)
    case .PUT:
      return self.createDataTask(URLString: url, HTTPMethod: .put, parameters: param, request)
    case .DELETE:
      return self.createDataTask(URLString: url, HTTPMethod: .delete, parameters: param, request)
    case .PATCH:
      return self.createDataTask(URLString: url, HTTPMethod: .patch, parameters: param, request)
    default:
      return nil
    }
    
  }
  
  public func createDataTask(URLString url: String,HTTPMethod method: HTTPMethod, parameters params: [String: Any]?,_ request: LYBaseRequest) -> URLSessionTask? {
    let dataRequest: DataRequest = self.manager.request(url, method: method, parameters: params, headers: request.requestHeaderFieldValueDictionary())
    dataRequest.validate(statusCode: request.statusCodeValidator())
    
    var requestError: Error? = nil
    
    dataRequest.response(queue: processingQueue) { (response) in
      if let error = response.error {
        /// The error encountered while executing or validating the request.
        print(error)
        self.handleRequestResult(request, responseJSONObject: nil, requestError: error)
      }
      
    }
    dataRequest.responseData(queue: processingQueue) { (dataResponse) in
      if let error = dataResponse.error {
        /// Returns the associated error value if the result if it is a failure, `nil` otherwise.
        requestError = error
        self.handleRequestResult(request, responseJSONObject: nil, requestError: requestError)
        print(error)
      } else {
        request.responseData = dataResponse.value
      }
    }
    
    if requestError == nil {
      dataRequest.responseString(queue: processingQueue, encoding: LYNetworkUtils.stringEncodingWithRequest(request)) { (dataResponse) in
        if let error = dataResponse.error {
          /// Returns the associated error value if the result if it is a failure, `nil` otherwise.
          requestError = error
          self.handleRequestResult(request, responseJSONObject: nil, requestError: requestError)
          print(error)
        } else {
          request.responseString = dataResponse.value
        }
      }
    }
    
    if requestError == nil {
      dataRequest.responseJSON(queue: processingQueue, options: JSONSerialization.ReadingOptions.allowFragments) { (dataResponse) in
        if let error = dataResponse.error {
          /// Returns the associated error value if the result if it is a failure, `nil` otherwise.
          requestError = error
          self.handleRequestResult(request, responseJSONObject: nil, requestError: requestError)
          print(error)
        } else {
          request.responseJSON = dataResponse.value
          self.handleRequestResult(request, responseJSONObject: dataResponse.value, requestError: nil)
        }
      }
    }
    return dataRequest.task
    
  }
  
  
  public func handleRequestResult(_ request: LYBaseRequest, responseJSONObject responseJSON: Any?, requestError error: Error? = nil) {
    error == nil ? self.requestDidSucceed(request) : self.requestDidFailed(request, error!)
    
    DispatchQueue.main.async {
      self.removeRequestFromRecord(request)
      request.clearCompletionHandler()
    }
  }
  
  public func validateResult(_ request: LYBaseRequest) -> Bool {
    /// TODO: json is Any not AnyObject
    let json: AnyObject? = request.responseJSON as AnyObject
    let validator: AnyObject? = request.jsonValidator()
    
    guard json != nil && validator != nil else {
      return true
    }
    return LYNetworkUtils.validateJSON(json!, validator: validator!)
  }
  
  
  public func requestDidSucceed(_ request: LYBaseRequest) {
    request.requestCompletePreprocessor()
    
    DispatchQueue.main.async {
      request.toggleAccessoriesWillStopCallBack()
      request.requestCompleteFilter()
      
      if let delegate = request.delegate {
        delegate.requestFinished(request)
      }
      
      if request.successCompletionHandler != nil {
        request.successCompletionHandler!(request)
      }
      request.toggleAccessoriesDidStopCallBack()
    }
  }
  
  public func requestDidFailed(_ request: LYBaseRequest, _ error: Error) {
    request.error = error
    
    /// TODO: handler error
    request.requestCompletePreprocessor()
    
    DispatchQueue.main.async {
      request.toggleAccessoriesWillStopCallBack()
      request.requestCompleteFilter()
      
      if let delegate = request.delegate {
        delegate.requestFinished(request)
      }
      
      if request.failureCompletionHandler != nil {
        request.failureCompletionHandler!(request)
      }
      request.toggleAccessoriesDidStopCallBack()
    }
  }
  
}

// MARK: RequestAdapter
fileprivate class LYRequestAdapter: RequestAdapter {
  var AdditionalHTTPHeaders: [String: String?] = [:]
  func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
    var request = urlRequest
    for (key, value) in AdditionalHTTPHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }
    return request
  }
}
