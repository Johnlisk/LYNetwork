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
  private static let lyrequest_cache_writing_queue: DispatchQueue = {
    return DispatchQueue.init(label: "com.linyue.lyrequest.caching", qos: DispatchQoS.background)
  }()
  
  private var cacheData: Data?
  private var cacheString: String?
  private var cacheJSON: AnyObject?
  private var cacheMetaData: LYCacheMetaData?
  private var dataFromCache: Bool = false
		
  public var ignoreCache: Bool = true
  
  // MARK: Override Properties
  override var responseData: Data? {
    get {
      if cacheData == nil {
        return super.responseData
      } else {
        return cacheData
      }
    }
    set {
      super.responseData = newValue
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
    set {
      super.responseString = newValue
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
    set {
      super.responseJSON = newValue
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
    // Make sure cache time in valid.
    if self.cacheTimeInSeconds() < 0 {
      if error != nil {
        
      }
      return false
    }
    
    // Try load metadata.
    if !self.loadCacheMetadata() {
      if error != nil {
        
      }
      return false
    }
    
    // Check if cache is still valid.
    
  }
  
  private func saveResponseDataToCacheFile(_ data: Data?) {
    if self.cacheTimeInSeconds() > 0 && !self.isDataFromCache() {
      if data != nil {
        // New data will always overwrite old data.
        do {
          try data!.write(to: URL.init(fileURLWithPath: self.cacheFilePath()))
          
          let metaData = LYCacheMetaData()
          metaData.version = self.cacheVersion()
          metaData.sensitiveDataString = self.cacheSensitiveData()?.description
          metaData.stringEncoding = LYNetworkUtils.stringEncodingWithRequest(self)
          metaData.creationDate = Date()
          metaData.appVersionString = LYNetworkUtils.appVersionString()
          if !NSKeyedArchiver.archiveRootObject(metaData, toFile: self.cacheMetadataFilePath()) {
            lyDebugPrintLog(message: "archive metadata to file error")
          }
          
        } catch {
          lyDebugPrintLog(message: "save cache failed")
        }
        
      }
    }
  }
  
  private func loadCacheMetadata() -> Bool {
    let path = self.cacheMetadataFilePath()
    let fileMgr = FileManager.default
    if fileMgr.fileExists(atPath: path, isDirectory: nil) {
      self.cacheMetaData = (NSKeyedUnarchiver.unarchiveObject(withFile: path) as? LYCacheMetaData)
      return (self.cacheMetaData != nil)
    }
    return false
  }
  
  private func loadCacheData() -> Bool {
    let path = self.cacheFilePath()
    let fileMgr = FileManager.default
    
    if fileMgr.fileExists(atPath: path, isDirectory: nil) {
      // TODO
      
    }
    
  }
  
  
  private func clearCacheVariables() {
    self.cacheData = nil
    self.cacheJSON = nil
    self.cacheString = nil
    self.cacheMetaData = nil
    self.dataFromCache = false
  }
  
  // MARK: Cache Path
  private func createDirectoryIfNeeded(_ path: String) {
    let fileManager = FileManager.default
    var isDir: ObjCBool = false
    
    if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
      self.createBaseDirectory(AtPath: path)
    } else {
      if !isDir.boolValue {
        do {
          try fileManager.removeItem(atPath: path)
          self.createBaseDirectory(AtPath: path)
        } catch {
          lyDebugPrintLog(message: "delete file failed, error : \(error)")
        }
      }
    }
    
  }
  
  private func createBaseDirectory(AtPath path: String) {
    do {
      try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
      LYNetworkUtils.addDoNotBackupAttribute(path)
    } catch {
      lyDebugPrintLog(message: "create cache directory failed, error = \(error)")
    }
  }
  
  private func cacheBasePath() -> String {
    let pathOfLibrary = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
    let path = NSString(string: pathOfLibrary).appendingPathComponent("LazyRequestCache")
    
    /// Filter cache base path
    let filters = LYNetworkConfig.shared.cacheDirPathFilters
    if filters.count > 0 {
      for f in filters {
        _ = f.filterCacheDirPath(path: path, self)
      }
    }
    
    self.createDirectoryIfNeeded(path)
    return path
  }
  
  private func cacheFileName() -> String {
    let requestUrl = self.requestUrl()
    let baseUrl = LYNetworkConfig.shared.baseUrl
    let argument = self.cacheFileNameFilterForRequestArgument(self.requestArgument())
    
    var requestInfo: String
    if argument == nil {
      requestInfo = String.init(format: "Method:%ld Host:%@ Url:%@ Argument:%@", self.requestMethod() as! CVarArg, baseUrl, requestUrl, "")
    } else {
      requestInfo = String.init(format: "Method:%ld Host:%@ Url:%@ Argument:%@", self.requestMethod() as! CVarArg, baseUrl, requestUrl, argument!)
    }
    return LYNetworkUtils.md5String(fromString: requestInfo)
    
  }
  
  
  private func cacheFilePath() -> String {
    let cacheFileName = self.cacheFileName()
    let path = self.cacheBasePath()
    
    return NSString(string: path).appendingPathComponent(cacheFileName)
  }
  
  private func cacheMetadataFilePath() -> String {
    let cacheMetadataFileName = String.init(format: "%@.metadata", self.cacheFileName())
    let path = self.cacheBasePath()
    return NSString(string: path).appendingPathComponent(cacheMetadataFileName)
    
  }
  
  // MARK: Network Request Delegate
  override func requestCompletePreprocessor() {
    super.requestCompletePreprocessor()
    
    if self.writeCacheAsynchronously() {
      
    }
  }
  
}

fileprivate class LYCacheMetaData: NSCoding {

  var version: Int?
  var sensitiveDataString: String?
  var stringEncoding: String.Encoding?
  var creationDate: Date?
  var appVersionString: String?
  
  init() {}
  
  required init?(coder aDecoder: NSCoder) {
    self.version = aDecoder.decodeObject(forKey: "version") as? Int
    self.sensitiveDataString = aDecoder.decodeObject(forKey: "sensitiveDataString") as? String
    self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as? Date
    self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as? String
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(self.version, forKey: "version")
    aCoder.encode(self.sensitiveDataString, forKey: "sensitiveDataString")
    aCoder.encode(self.creationDate, forKey: "creationDate")
    aCoder.encode(self.appVersionString, forKey: "appVersionString")
  }
  
  class func supportsSecureCoding() -> Bool {
    return true
  }
}
