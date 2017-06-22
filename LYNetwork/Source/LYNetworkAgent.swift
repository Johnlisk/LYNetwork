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
  private var jsonResponseSerializer: JSONSerialization
  private var requestsRecord: Dictionary<NSNumber, LYBaseRequest>
  private var allStatusCodes: IndexSet
  private var lock: pthread_mutex_t
  
  //  MARK: Initialization
  init() {
    self.config = LYNetworkConfig()
    self.manager = SessionManager.init(configuration: self.config.sessionConfiguration)
    self.requestsRecord = Dictionary.init()
    self.allStatusCodes = IndexSet.init(integersIn: Range.init(uncheckedBounds: (lower: 100, upper: 500)))
    pthread_mutex_init(&lock, NULL);
    
  }
  
  
  //  MARK: Actions
  public func addRequest(_ request: LYBaseRequest) {
    let customUrlRequest: URLRequest? = request.buildCustomUrlRequest()
    if customUrlRequest != nil {
      self.manager.request(customUrlRequest!)
    }
  }
  public func cancelRequest(_ request: LYBaseRequest) {
    request.requestTask?.cancel()
    self.removeRequestFromRecord(request)
    request.clearCompletionHandler()
    
  }
  public func cancelAllRequest(_ request: LYBaseRequest) {
    self.pthread_lock()
    let allKeys = self.requestsRecord.keys
    self.pthread_unlock()
    if allKeys.count > 0 {
      allKeys.map({ (key) -> Void in
        self.pthread_lock()
        let request = self.requestsRecord[key]
        self.pthread_unlock()
        // We are using non-recursive lock.
        // Do not lock `stop`, otherwise deadlock may occur.
        request?.stop()
      })
    }
  }
  
  public func removeRequestFromRecord(_ request: LYBaseRequest) {
    self.pthread_lock()
    self.requestsRecord[NSNumber.init(integerLiteral: request.requestTask!.taskIdentifier)] = request
    self.pthread_unlock()
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
  
  private func pthread_lock() {
    pthread_mutex_lock(&lock)
  }
  
  private func pthread_unlock() {
    pthread_mutex_unlock(&lock)
  }
  
}
