//
//  LYChainRequestAgent.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/7/3.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

///  LYChainRequestAgent handles chain request management. It keeps track of all
///  the chain requests.
class LYChainRequestAgent {
  static let sharedAgent = LYChainRequestAgent()
  
  private var requestList: [LYChainRequest] = []
  
  ///  Add a chain request.
  public func addChainRequest(_ request: LYChainRequest) {
    lysynchronized(self) { 
      self.requestList.append(request)
    }
  }
  
  ///  Remove a previously added chain request.
  public func removeChainRequest(_ request: LYChainRequest) {
    lysynchronized(self) { 
      self.requestList.remove(request)
    }
  }
}
