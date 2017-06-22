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
  public var sessionConfiguration: URLSessionConfiguration
  
  //  MARK: Initialization
  init() {
    self.baseUrl = ""
    self.cdnUrl = ""
    self.debugLogEnabled = false
    self.urlFilters = []
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
