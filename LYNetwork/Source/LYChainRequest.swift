//
//  LYChainRequest.swift
//
//  Copyright (c) 2017 LYNetwork https://github.com/ZakariyyaSv/LYNetwork
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

///  The LYChainRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of chain request finishes.
public protocol LYChainRequestDelegate: class {
  ///  Tell the delegate that the chain request has finished successfully.
  func chainRequestFinished(_ request: LYChainRequest)
  func chainRequestFailed(_ chainRequest: LYChainRequest, failedBaseRequest baseRequest: LYBaseRequest)
}

public typealias LYChainCompletionHandler = (LYChainRequest, LYBaseRequest)->(Void)

///  LYBatchRequest can be used to chain several LYRequest so that one will only starts after another finishes.
///  Note that when used inside LYChainRequest, a single LYRequest will have its own callback and delegate
///  cleared, in favor of the batch request callback.
public class LYChainRequest: LYRequestDelegate {
  
  
  // MARK: - Properties
  // MARK: Public Properties
  ///  The delegate object of the chain request. Default is nil.
  public weak var delegate: LYChainRequestDelegate?
  
  ///  This can be used to add several accossories object. Note if you use `addAccessory` to add acceesory
  public var requestAccessories: [LYRequestAccessory]?
  
  ///  All the requests are stored in this array.
  public private(set) var requestList: [LYBaseRequest]
  
  // MARK: Private Properties
  private var requestHandlerList: [LYChainCompletionHandler]
  
  private var nextRequestIndex: Int
  
  private var emptyHandler: LYChainCompletionHandler
  
  // MARK: - Public Methods
  ///  Start the chain request, adding first request in the chain to request queue.
  public func start() {
    guard self.nextRequestIndex > 0 else {
      lyDebugPrintLog(message: "Error! Chain request has already started.")
      return
    }
    
    if self.requestList.count > 0 {
      self.toggleAccessoriesWillStartCallBack()
      _ = self.startNextRequest()
      LYChainRequestAgent.sharedAgent.addChainRequest(self)
    } else {
      lyDebugPrintLog(message: "Error! Chain request array is empty.")
    }
    
  }
  
  ///  Stop the chain request. Remaining request in chain will be cancelled.
  public func stop() {
    self.toggleAccessoriesWillStopCallBack()
    self.clearRequest()
    LYChainRequestAgent.sharedAgent.removeChainRequest(self)
    self.toggleAccessoriesDidStopCallBack()
  }
  
  ///  Add request to request chain.
  public func addRequest(_ request: LYBaseRequest, completionHandler callback: LYChainCompletionHandler?) {
    self.requestList.append(request)
    if callback != nil {
      self.requestHandlerList.append(callback!)
    } else {
      self.requestHandlerList.append(self.emptyHandler)
    }
  }
  
  // MARK: - Initializer
  init() {
    self.nextRequestIndex = 0
    self.requestList = []
    self.requestHandlerList = []
    self.emptyHandler = { chainRequest,baseRequest in
      // do nothing
    }
  }
  
  // MARK: - Private Methods
  private func startNextRequest() -> Bool {
    if self.nextRequestIndex < self.requestList.count {
      let request = self.requestList[self.nextRequestIndex]
      self.nextRequestIndex += 1
      request.delegate = self
      request.clearCompletionHandler()
      request.start()
      return true
    } else {
      return false
    }
  }
  
  private func clearRequest() {
    let currentRequestIndex = self.nextRequestIndex - 1
    if currentRequestIndex < self.requestList.count {
      let request = self.requestList[currentRequestIndex]
      request.stop()
    }
    self.requestList.removeAll()
    self.requestHandlerList.removeAll()
  }
  
  // MARK: - LYRequestDelegate
  public func requestFinished(_ request: LYBaseRequest) {
    let currentRequestIndex = self.nextRequestIndex - 1
    let callback = self.requestHandlerList[currentRequestIndex]
    callback(self, request)
    
    if !self.startNextRequest() {
      self.toggleAccessoriesWillStopCallBack()
      if self.delegate != nil {
        self.delegate!.chainRequestFinished(self)
        LYChainRequestAgent.sharedAgent.removeChainRequest(self)
      }
      self.toggleAccessoriesDidStopCallBack()
    }
  }
  
  public func requestFailed(_ request: LYBaseRequest) {
    self.toggleAccessoriesWillStopCallBack()
    if self.delegate != nil {
      self.delegate!.chainRequestFailed(self, failedBaseRequest: request)
      LYChainRequestAgent.sharedAgent.removeChainRequest(self)
    }
    self.toggleAccessoriesDidStopCallBack()
  }
  
  // MARK: - Request Accessoies
  private func addAccessory(_ accessory: LYRequestAccessory) {
    if self.requestAccessories == nil {
      self.requestAccessories = []
    }
    self.requestAccessories!.append(accessory)
  }
  
}
