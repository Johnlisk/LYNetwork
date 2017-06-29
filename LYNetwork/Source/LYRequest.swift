//
//  LYRequest.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/29.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

fileprivate let LYRequestCacheErrorDomain = "com.ly.request.caching"

class LYRequest: LYBaseRequest {
  
  // MARK: Private Properties
  private var cacheData: Data?
  private var cacheString: String?
  private var cacheJSON: AnyObject?
  private var cacheMetaData: LYCacheMetaData?
  private var dataFromCache: Bool = false
		
  public var ignoreCache: Bool
  
  // MARK: Override Properties
  override var responseData: Data? {
    get {
      if cacheData == nil {
        return super.responseData
      } else {
        return cacheData
      }
    }
  }
  
  override var responseString: String? {
    get {
      if cacheString == nil {
        return super.responseString
      } else {
        return cacheString
      }
    }
  }
  
  override var responseJSON: Any? {
    get {
      if cacheJSON == nil {
        return super.responseJSON
      } else {
        return cacheJSON
      }
    }
  }
  
  // MARK: Subclass Override
  open func writeCacheAsynchronously() -> Bool {
    return true
  }
  
  open func cacheSensitiveData() -> AnyObject? {
    return nil
  }
  
  open func cacheTimeInSeconds() -> Int {
    return -1
  }
  
  open func cacheVersion() -> Int {
    return 0
  }
  
  // MARK: Public Methods
  public func isDataFromCache() -> Bool {
    return dataFromCache
  }
  
  public func startWithoutCache() {
    self.clearCacheVariables()
    super.start()
  }
  
  // MARK: Private Methods
  override func start() {
    guard !self.ignoreCache else {
      self.startWithoutCache()
      return
    }
    
    guard self.loadCache(nil) else {
      self.startWithoutCache()
      return
    }
    
    dataFromCache = true
    
    DispatchQueue.main.async {
      self.requestCompletePreprocessor()
      self.requestCompleteFilter()
      let strongSelf = self
      strongSelf.delegate?.requestFinished(strongSelf)
      if strongSelf.successCompletionHandler != nil {
        strongSelf.successCompletionHandler!(strongSelf);
      }
      strongSelf.clearCompletionHandler()
    }
  }
  
  private func loadCache(_ error: Error?) -> Bool {
    /// Make sure cache time in valid.
    if self.cacheTimeInSeconds() < 0 {
      if error != nil {
        
      }
      return false
    }
    
    /// Try load metadata.
    
  }
  
  private func saveResponseDataToCacheFile(_ data: Data) {
    
  }
  
  private func loadCacheMetadata() -> Bool {
    
  }
  
  
  private func cacheMetadataFilePath() -> String {
    
  }
  
  private func cacheFileName() -> String {
    let requestUrl = self.requestUrl()
    let baseUrl = LYNetworkConfig.sharedConfig.baseUrl
    let argument = self.cacheFileNameFilterForRequestArgument(self.requestArgument())
    let requestInfo = String.init(format: "Method:%ld Host:%@ Url:%@ Argument:%@", self.requestMethod() as! CVarArg, baseUrl, requestUrl, argument!)
    
    
    
  }
  
  private func clearCacheVariables() {
    self.cacheData = nil
    self.cacheJSON = nil
    self.cacheString = nil
    self.cacheMetaData = nil
    self.dataFromCache = false
  }
  
  
  // MARK: Network Request Delegate
  override func requestCompletePreprocessor() {
    super.requestCompletePreprocessor()
    
    if self.writeCacheAsynchronously() {
      
    }
  }
  
}

fileprivate class LYCacheMetaData {
//
//  private var version: Int
//  private var sensitiveDataString: String
//  private var stringEncoding: String.Encoding
//  private var creationDate: Date
//  private var appVersionString: String
//  
//  required init?(coder aDecoder: NSCoder) {
//  
//    guard cacheData else {
//      return nil
//    }
//  }
//  
//  
//  class func supportsSecureCoding() -> Bool { return true }
}
