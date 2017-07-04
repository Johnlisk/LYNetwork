//
//  LYBatchRequest.swift
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

///  The LYBatchRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of batch request finishes.
public protocol LYBatchRequestDelegate: class {
  ///  Tell the delegate that the batch request has finished successfully/
  ///
  ///  @param batchRequest The corresponding batch request.
  func batchRequestFinished(_ request: LYBatchRequest)
  
  ///  Tell the delegate that the batch request has failed.
  ///
  ///  @param batchRequest The corresponding batch request.
  func batchRequestFailed(_ request: LYBatchRequest)
}

public typealias LYBatchRequestCompletionHandler = (LYBatchRequest)->(Void)

///  LYBatchRequest can be used to batch several LYRequest. Note that when used inside LYBatchRequest, a single
///  LYRequest will have its own callback and delegate cleared, in favor of the batch request callback.
public class LYBatchRequest: LYRequestDelegate {
  
  public weak var delegate: LYBatchRequestDelegate?
  public var successCompletionHandler: LYBatchRequestCompletionHandler?
  public var failureCompletionHandler: LYBatchRequestCompletionHandler?
  public var tag: Int = 0
  public private(set) var requestList: [LYRequest] = []
  public var requestAccessories: [LYRequestAccessory]?
  public private(set) var failedRequest: LYRequest?
  
  private var finishedCount: Int = 0

  // MARK: - Initializer
  public func `init`(_ requestList: [LYRequest]) {
    self.requestList = requestList
  }
  
  deinit {
    self.clearRequest()
  }
  
  // MARK: - Public Methods
  public func setCompletionHandler(success successHandler: LYBatchRequestCompletionHandler?, failure failureHandler: LYBatchRequestCompletionHandler?) {
    self.successCompletionHandler = successHandler
    self.failureCompletionHandler = failureHandler
  }
  
  public func clearCompletionHandler() {
    // nil out to break the retain cycle.
    self.successCompletionHandler = nil
    self.failureCompletionHandler = nil
  }
  
  public func start() {
    guard self.finishedCount == 0 else {
      lyDebugPrintLog(message: "Error! Batch request has already started.")
      return
    }
    self.failedRequest = nil
    LYBatchRequestAgent.sharedAgent.addBatchRequest(self)
    self.toggleAccessoriesWillStartCallBack()
    for req in self.requestList {
      req.delegate = self
      req.clearCompletionHandler()
      req.start()
    }
    
  }
  
  public func stop() {
    self.toggleAccessoriesWillStopCallBack()
    self.delegate = nil
    self.clearRequest()
    self.toggleAccessoriesDidStopCallBack()
    LYBatchRequestAgent.sharedAgent.removeBatchRequest(self)
  }
  
  public func startWithCompletionHandler(success successHandler: LYBatchRequestCompletionHandler?, failure failureHandler: LYBatchRequestCompletionHandler?) {
    self.setCompletionHandler(success: successHandler, failure: failureHandler)
    self.start()
  }
  
  public func isDataFromCache() -> Bool {
    var result = true
    for req in self.requestList {
      if !req.isDataFromCache() {
        result = false
        break
      }
    }
    return result
  }
  
  // MARK: - Private Methods
  private func clearRequest() {
    for req in self.requestList {
      req.stop()
    }
    self.clearCompletionHandler()
  }
  
  // MARK: - LYRequestDelegate
  public func requestFinished(_ request: LYBaseRequest) {
    self.finishedCount += 1
    if self.finishedCount == self.requestList.count {
      self.toggleAccessoriesWillStopCallBack()
      if self.delegate != nil  {
        self.delegate?.batchRequestFinished(self)
      }
      
      if self.successCompletionHandler != nil {
        self.successCompletionHandler!(self)
      }
      
      self.clearCompletionHandler()
      self.toggleAccessoriesDidStopCallBack()
      LYBatchRequestAgent.sharedAgent.removeBatchRequest(self)
    }
  }
  
  public func requestFailed(_ request: LYBaseRequest) {
    self.failedRequest = request as? LYRequest
    self.toggleAccessoriesWillStopCallBack()
    // Stop
    for req in self.requestList {
      req.stop()
    }
    // Callback
    if self.delegate != nil {
      self.delegate!.batchRequestFailed(self)
    }
    
    if self.failureCompletionHandler != nil {
      self.failureCompletionHandler!(self)
    }
    
    self.clearCompletionHandler()
    
    self.toggleAccessoriesDidStopCallBack()
    LYBatchRequestAgent.sharedAgent.removeBatchRequest(self)
    
  }
  
  // MARK: - Request Accessoies
  public func addAccessory(_ accessory: LYRequestAccessory) {
    if self.requestAccessories == nil {
      self.requestAccessories = []
    }
    self.requestAccessories!.append(accessory)
  }
  
}

