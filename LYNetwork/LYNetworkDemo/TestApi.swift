//
//  TestApi.swift
//  LYNetwork
//
//  Created by XuHaonan on 2017/7/9.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

class loginApi: LYRequest {
  
  private var phone: String
  private var password: String
  
  public init(_ username: String, _ password: String) {
    self.phone = username
    self.password = password
    super.init()
  }
  
  public func userIdAndticket() -> (String, String) {
    guard let response = (self.responseJSON as? Dictionary<String, Any>) else {
      return ("", "")
    }
    return (response["userId"] as! String, response["ticket"] as! String)
  }
  
  override func requestUrl() -> String {
    return "login"
  }
  
  override func requestMethod() -> LYRequestMethod {
    return .POST
  }
  
  override func responseSerializerType() -> LYResponseSerializerType {
    return .JSON
  }
  
  override func requestArgument() -> [String : Any]? {
    return ["phone" : self.phone, "password" : self.password]
  }
  
}

class getUserInfoApi: LYRequest {
  private var userId: String
  private var ticket: String
  
  public init(_ userId: String, _ ticket: String) {
    self.userId = userId
    self.ticket = ticket
    super.init()
  }
  
  override func requestUrl() -> String {
    return "get_index_info"
  }
  
  override func requestArgument() -> [String : Any]? {
    return ["userId" : self.userId, "ticket" : self.ticket]
  }
  
  override func cacheTimeInSeconds() -> Int {
    return 60 * 3
  }
}

class getImageApi: LYRequest {
  private var imageId: String
  
  public init(_ imageId: String) {
    self.imageId = imageId
    super.init()
  }
  
  override func requestUrl() -> String {
    return "/iphone/images/" + self.imageId
  }
  
  override func useCDN() -> Bool {
    return true
  }
  
}


