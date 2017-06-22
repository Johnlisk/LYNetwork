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
  
  //  MARK: Initialization
  init() {
    self.config = LYNetworkConfig()
    self.manager = SessionManager.init(configuration: self.config.sessionConfiguration)
    self.requestsRecord = Dictionary.init()
    self.allStatusCodes = IndexSet.init(integersIn: Range.init(uncheckedBounds: (lower: 100, upper: 500)))
    
  }
  
  
  //  MARK: Actions
  public func addRequest(_ request: LYBaseRequest) {
    let customUrlRequest: URLRequest? = request.buildCustomUrlRequest()
    if customUrlRequest != nil {
      self.manager.request(customUrlRequest) as! (URLRequestConvertible)
    }
  }
  public func cancelRequest(_ request: LYBaseRequest) {}
  public func cancelAllRequest(_ request: LYBaseRequest) {}
  
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
  
}
