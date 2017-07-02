//
//  LYBatchRequestAgent.swift
//  LYNetwork
//
//  Created by 许浩男 on 2017/7/2.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

public class LYBatchRequestAgent {
  static let sharedAgent: LYBatchRequestAgent = LYBatchRequestAgent()
  
  private var requestList: [LYBatchRequest]
  
  public func addBatchRequest(_ request: LYBatchRequest) {
    lysynchronized(self) {
      self.requestList.append(request)
    }
  }
  
  public func removeBatchRequest(_ request: LYBatchRequest) {
    lysynchronized(self) { 
      self.requestList.remove(request)
    }
  }
  
  private init() {
    self.requestList = []
  }
  
}


