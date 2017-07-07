//
//  LYBatchRequestAgent.swift
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

///  LYBatchRequestAgent handles batch request management. It keeps track of all
///  the batch requests.
public class LYBatchRequestAgent {
  // MARK: - Properties
  // MARK: Singleton
  ///  Get the shared batch request agent.
  static let sharedAgent: LYBatchRequestAgent = LYBatchRequestAgent()
 
  // MARK: Private Properties
  private var requestList: [LYBatchRequest]
  
  // MARK: - Methods
  // MARK: Public Methods
  ///  Add a batch request.
  public func addBatchRequest(_ request: LYBatchRequest) {
    lysynchronized(self) {
      self.requestList.append(request)
    }
  }
  
  ///  Remove a previously added batch request.
  public func removeBatchRequest(_ request: LYBatchRequest) {
    lysynchronized(self) { 
      self.requestList.remove(request)
    }
  }
  
  // MARK: Initializer
  private init() {
    self.requestList = []
  }
  
}


