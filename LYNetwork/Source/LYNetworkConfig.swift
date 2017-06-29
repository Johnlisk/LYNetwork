//
//  LYNetworkConfig.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

public protocol LYUrlFilterProtocol: class {
  func filterUrl(url originalUrl: String,_ request: LYBaseRequest) -> String
}


class LYNetworkConfig {
  // MARK: Properties
  static let sharedConfig: LYNetworkConfig = LYNetworkConfig()
  public var baseUrl: String
  public var cdnUrl: String
  public var debugLogEnabled: Bool
  public private(set) var urlFilters: Array<LYUrlFilterProtocol>
  public private(set) var sessionConfiguration: URLSessionConfiguration
  /// The default value is 60 seconds.
  public var requestTimeoutInterval: TimeInterval {
    get {
      return self.sessionConfiguration.timeoutIntervalForRequest
    }
    set {
      self.sessionConfiguration.timeoutIntervalForRequest = newValue
    }
  }
  public var requestHTTPHeaders: [String: String?]?
  
  //  MARK: Initialization
  private init() {
    self.baseUrl = ""
    self.cdnUrl = ""
    self.debugLogEnabled = false
    self.urlFilters = []
    self.sessionConfiguration = URLSessionConfiguration()
  }
  
  //  MARK: Actions
  public func addUrlFilter(_ filter: LYUrlFilterProtocol) {
    self.urlFilters.append(filter)
  }
  public func clearUrlFilter() {
    self.urlFilters.removeAll()
  }
  
  //  MARK: Description
  open var description: String {
    return String.init(format: "<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass(LYNetworkConfig.self), self as! CVarArg, self.baseUrl, self.cdnUrl)
  }
  
  
}
