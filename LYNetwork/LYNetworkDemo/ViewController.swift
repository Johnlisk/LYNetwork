//
//  ViewController.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController, LYRequestDelegate, LYChainRequestDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    self.sendChainRequest()
  }

  private func sendChainRequest() {
    let reg = loginApi.init("18510237166", "qwer1234")
    reg.delegate = self
    let chainReq = LYChainRequest()
    chainReq.addRequest(reg) { (chainRequest, baseRequest) -> (Void) in
      let login = baseRequest as! loginApi
      print("login response: \(String(describing: login.responseString))")
      let (userId, ticket) = login.userIdAndticket()
      if userId.characters.count > 0 && ticket.characters.count > 0 {
        let getUser = getUserInfoApi.init(userId, ticket)
        getUser.successCompletionHandler = { (request) in
          print("indexInfo response: \(String(describing: getUser.responseString))")
        }
        chainRequest.addRequest(getUser)
      }
    }
    chainReq.delegate = self
    chainReq.start()
  }
  
  func chainRequestFinished(_ request: LYChainRequest) {
    print("request success")
  }
  
  func chainRequestFailed(_ chainRequest: LYChainRequest, failedBaseRequest baseRequest: LYBaseRequest) {
    print("request failed")
  }
  
  func requestFinished(_ request: LYBaseRequest) {
    
  }
  
  func requestFailed(_ request: LYBaseRequest) {
    
  }
  
  func loadCacheData() {
    let getUserApi = getUserInfoApi.init("1", "1234")
    do {
      let success = try getUserApi.loadCache()
      if success {
        return
      }
    } catch {
      
    }
    getUserApi.startWithCompletionHandler(success: { (request) -> (Void) in
      
    }, failure: { (request) -> (Void) in
      
    })

  }
  
  func sendBatchRequest() {
    let a = getImageApi.init("1.jpg")
    let b = getImageApi.init("2.jpg")
    let c = getImageApi.init("3.jpg")
    let d = getUserInfoApi.init("123", "123456")
    
    let batchRequest = LYBatchRequest.init(requestList: [a, b, c, d])
    
    batchRequest.startWithCompletionHandler(success: { (batchReq) -> (Void) in
      print("success")
      let requestList = batchRequest.requestList
      let a = requestList[0] as! getImageApi
      let b = requestList[1] as! getImageApi
      let c = requestList[2] as! getImageApi
      let d = requestList[3] as! getUserInfoApi
      
      //  deal with request result
    }, failure: { (batchReq) -> (Void) in
        print("failed")
      })
  }
  
}

