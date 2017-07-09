//
//  LYUrlArgumentsFilter.swift
//  LYNetwork
//
//  Created by XuHaonan on 2017/7/8.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

class LYUrlArgumentsFilter {
  
  private var arguments: Dictionary<String, Any>
  
  // MARK: Public Methods
  public class func filter(_ arguments: Dictionary<String, Any>) -> LYUrlArgumentsFilter {
    return LYUrlArgumentsFilter.init(arguments)
  }
  
  public func filterRequest(_ request: LYBaseRequest,url originUrl: String) -> String {
    return self.componentUrlString(originUrl, appendParameters: self.arguments)
  }
  
  // MARK: Private Methods
  private init(_ arguments: Dictionary<String, Any>) {
    self.arguments = arguments
  }
  
  private func componentUrlString(_ originUrlString: String, appendParameters parameters: Dictionary<String, Any>) -> String {
    return ""
  }
}
