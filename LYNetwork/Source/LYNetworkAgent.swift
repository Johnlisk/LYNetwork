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
  private var processingQueue: DispatchQueue
  private var allStatusCodes: IndexSet
  
  //  MARK: Initialization
  convenience init() {
    self.config = LYNetworkConfig()
    self.manager = SessionManager.init(configuration: self.config.sessionConfiguration)
    self.requestsRecord = Dictionary.init()
    self.processingQueue = DispatchQueue.init(label: "com.yangqianguan.network.processing")
    self.allStatusCodes = IndexSet.init(integersIn: Range.init(uncheckedBounds: (lower: 100, upper: 500)))
  }
  
  
  //  MARK: Actions
  public func addRequest(_ request: LYBaseRequest) {}
  public func cancelRequest(_ request: LYBaseRequest) {}
  public func cancelAllRequest(_ request: LYBaseRequest) {}
  public func buildRequestUrl(_ reuqest: LYBaseRequest) -> String { return "" }
  
}
