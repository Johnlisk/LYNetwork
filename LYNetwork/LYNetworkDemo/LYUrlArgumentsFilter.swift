//
//  LYUrlArgumentsFilter.swift
//  LYNetwork
//
//  Created by XuHaonan on 2017/7/8.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

class LYUrlArgumentsFilter: LYUrlFilterProtocol {
  
  private var arguments: Dictionary<String, Any>
  
  // MARK: Public Methods
  public class func filter(_ arguments: Dictionary<String, Any>) -> LYUrlArgumentsFilter {
    return LYUrlArgumentsFilter.init(arguments)
  }
  
  func filterUrl(url originalUrl: String, _ request: LYBaseRequest) -> String {
    return self.componentUrlString(originalUrl, appendParameters: self.arguments)
  }
  
  
  // MARK: Private Methods
  private init(_ arguments: Dictionary<String, Any>) {
    self.arguments = arguments
  }
  
  private func componentUrlString(_ originUrlString: String, appendParameters parameters: Dictionary<String, Any>) -> String {
    //  add code
    return ""
  }
}
