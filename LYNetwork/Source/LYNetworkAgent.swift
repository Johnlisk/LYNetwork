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
  private var allStatusCodes: IndexSet
  private var processingQueue: DispatchQueue
  private var mutex: Mutex
  
  //  MARK: Initialization
  init() {
    self.config = LYNetworkConfig()
    self.manager = SessionManager.init(configuration: self.config.sessionConfiguration)
    self.requestsRecord = Dictionary.init()
    self.allStatusCodes = IndexSet.init(integersIn: Range.init(uncheckedBounds: (lower: 100, upper: 500)))
    self.processingQueue = DispatchQueue.init(label: "com.lynetwork.processing")
    self.mutex = Mutex()
  }
  
  //  MARK: Actions
  public func addRequest(_ request: LYBaseRequest) {
    let customUrlRequest: URLRequest? = request.buildCustomUrlRequest()
    if customUrlRequest != nil {
      
      
      let afRequest = self.manager.request(customUrlRequest!)
      request.requestTask = afRequest.task
      
      
    }
    
    // Set request task priority
    // !!Available on iOS 8 +
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
    
    // Retain request
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
        // We are using non-recursive lock.
        // Do not lock `stop`, otherwise deadlock may occur.
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
    
    // If detailUrl is valid URL
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
    
    // URL slash compability
    var url = URL.init(string: baseUrl)!
    if baseUrl.characters.count > 0 && !baseUrl.hasSuffix("/") {
      url = url.appendingPathComponent("")
    }
    return URL.init(string: detailUrl, relativeTo: url)!.absoluteString
  }
  
  
  
  public func handleRequestResult(sessionTask task: URLSessionTask, _ responseObject: AnyObject, _ error: Error) {
    self.mutex.lock()
    let request = self.requestsRecord[NSNumber.init(integerLiteral: task.taskIdentifier)]
    self.mutex.unlock()
    
    // When the request is cancelled and removed from records, the underlying
    // AFNetworking failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    guard request != nil else {
      return
    }
    
    var requestError: Error?
    let succeed = false
    request!.responseObject = responseObject
    if responseObject.isKind(of: (Data.self as! AnyClass)) {
      request!.responseData = responseObject as? Data
    }
    request!.responseString = String.init(data: responseObject as! Data, encoding: LYNetworkUtils.stringEncodingWithRequest(request!))
    
    switch request!.responseSerializerType() {
    case .HTTP:
      // Default serializer. Do nothing.
      break
    case .JSON:
      break
    default:
      break
    }
    
    
    if succeed {
      self.requestDidSucceed(request!)
    }
    else {
      self.requestDidFailed(request!, requestError!)
    }
    
    DispatchQueue.main.async {
      self.removeRequestFromRecord(request!)
      request!.clearCompletionHandler()
    }
    
  }
  
  public func validateResult(_ request: LYBaseRequest) -> Bool {
    var result: Bool = request.statusCodeValidator()
    
    if !result {
      //  error handling
      return result
    }
    
    let json: AnyObject? = request.responseJSONObject
    let validator: AnyObject? = request.jsonValidator()
    
    guard json != nil && validator != nil else {
      return true
    }
    
    result = LYNetworkUtils.validateJSON(json!, validator: validator!)
    
    return result
  }
  
  private func request( url: URLConvertible, method: LYRequestMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders) -> DataRequest {
    
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
