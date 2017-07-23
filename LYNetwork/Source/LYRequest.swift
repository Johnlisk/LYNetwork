//
//  LYRequest.swift
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

/// Load Cache Error Type
public enum LYRequestCacheError: Error {
  case InvalidCacheTime
  case InvalidMetaData
  case InvalidCacheData
}

/// Validate Cache Error Type
public enum LYValidateCacheError: Error {
  case CacheExpired
  case CacheVersionMismatch
  case CacheSenstiveDataMismatch
}

///  LYRequest is the base class you should inherit to create your own request class.
///  Based on LYBaseRequest, LYRequest adds local caching feature.
public class LYRequest: LYBaseRequest {
  
  // MARK: - Properties
  //==========================================================
  // MARK: Public Properties
  ///  Whether to use cache as response or not.
  ///  Default is NO, which means caching will take effect with specific arguments.
  ///  Note that `cacheTimeInSeconds` default is -1. As a result cache data is not actually
  ///  used as response unless you return a positive value in `cacheTimeInSeconds`.
  ///
  ///  Also note that this option does not affect storing the response, which means response will always be saved
  ///  even `ignoreCache` is YES.
  public var ignoreCache: Bool = true
  
  // MARK: Override Properties
  override public var responseData: Data? {
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
  
  override public var responseString: String? {
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
  
  override public var responseJSON: Any? {
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
  
  // MARK: Private Properties
  private static let lyrequest_cache_writing_queue: DispatchQueue = {
    return DispatchQueue.init(label: "com.lingyue.lyrequest.caching", qos: DispatchQoS.background)
  }()
  
  private var cacheData: Data?
  private var cacheString: String?
  private var cacheJSON: Any?
  private var cacheMetaData: LYCacheMetaData?
  private var dataFromCache: Bool = false
  
  // MARK: - Methods
  // ================================================================
  // MARK: Subclass Override
  ///  Whether cache is asynchronously written to storage. Default is YES.
  open func writeCacheAsynchronously() -> Bool {
    return true
  }
  
  ///  This can be used as additional identifier that tells the cache needs updating.
  open func cacheSensitiveData() -> AnyObject? {
    return nil
  }
  
  ///  The max time duration that cache can stay in disk until it's considered expired.
  ///  Default is -1, which means response is not actually saved as cache.
  open func cacheTimeInSeconds() -> Int {
    return -1
  }
  
  ///  Version can be used to identify and invalidate local cache. Default is 0.
  open func cacheVersion() -> Int {
    return 0
  }
  
  // MARK: Public Methods
  ///  Whether data is from local cache.
  public func isDataFromCache() -> Bool {
    return dataFromCache
  }
  
  ///  Start request without reading local cache even if it exists. Use this to update local cache.
  public func startWithoutCache() {
    self.clearCacheVariables()
    super.start()
  }
  
  override public func start() {
    guard !self.ignoreCache else {
      self.startWithoutCache()
      return
    }
    
    var result = false
    do {
      result = try self.loadCache()
    } catch  {
      lyDebugPrintLog(message: "load cache error \(error)")
    }
    
    guard result else {
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
  
  ///  Manually load cache from storage.
  public func loadCache() throws -> Bool {
    // Make sure cache time in valid.
    if self.cacheTimeInSeconds() < 0 {
      throw LYRequestCacheError.InvalidCacheTime
    }
    
    // Try load metadata.
    if !self.loadCacheMetadata() {
      throw LYRequestCacheError.InvalidMetaData
    }
    
    // Check if cache is still valid.
    do {
      if try self.validateCache() {
        return false
      }
    } catch  {
      lyDebugPrintLog(message: "validate error: \(error)")
    }
    
    // Try load cache.
    if !self.loadCacheData() {
      throw LYRequestCacheError.InvalidCacheData
    }
    return true
    
  }
  
  ///  Save response data (probably from another request) to this request's cache location
  public func saveResponseDataToCacheFile(_ data: Data?) {
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
  
  // MARK: Cache Related Actions
  private func validateCache() throws -> Bool {
    guard self.cacheMetaData != nil else {
      return false
    }
    // Date
    let creationDate = self.cacheMetaData!.creationDate
    let dutation = -creationDate!.timeIntervalSinceNow
    
    if dutation < 0 || dutation > Double(self.cacheTimeInSeconds()) {
      throw LYValidateCacheError.CacheExpired
    }
    
    // Version
    let cacheVersionFileContent = self.cacheMetaData!.version
    if cacheVersionFileContent != self.cacheVersion() {
      throw LYValidateCacheError.CacheSenstiveDataMismatch
    }
    
    // Sensitive data
    let sensitiveDataString = self.cacheMetaData!.sensitiveDataString
    let currentSensitiveDataString = self.cacheSensitiveData()?.description
    if sensitiveDataString != nil || currentSensitiveDataString != nil {
      // If one of the strings is nil, short-circuit evaluation will trigger
      if sensitiveDataString!.characters.count != currentSensitiveDataString!.characters.count || sensitiveDataString! != currentSensitiveDataString! {
        return false
      }
    }
    
    // App version
    let appVersionString = self.cacheMetaData!.appVersionString
    let currentAppVersionString = LYNetworkUtils.appVersionString()
    if appVersionString != nil {
      if appVersionString!.characters.count != currentAppVersionString.characters.count || appVersionString != currentAppVersionString {
        throw LYValidateCacheError.CacheVersionMismatch
      }
    }
    return true
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
      do {
        let data = try Data.init(contentsOf: URL.init(fileURLWithPath: path))
        self.cacheData = data
        self.cacheString = String.init(data: self.cacheData!, encoding: self.cacheMetaData!.stringEncoding!)
      } catch {
        lyDebugPrintLog(message: "Read data from file failed, error: \(error)")
      }
      switch self.responseSerializerType() {
      case .HTTP:
        // Do nothing.
        return true
      case .JSON:
        do {
          self.cacheJSON = try JSONSerialization.jsonObject(with: self.cacheData!, options: JSONSerialization.ReadingOptions.allowFragments)
          return true
        } catch {
          lyDebugPrintLog(message: "json serialized failed, error: \(error)")
        }
      default:
        return true
      }
    }
    return false
  }
  
  private func clearCacheVariables() {
    self.cacheData = nil
    self.cacheJSON = nil
    self.cacheString = nil
    self.cacheMetaData = nil
    self.dataFromCache = false
  }
  
  // MARK: Cache Path Methods
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
    
    // Filter cache base path
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
      requestInfo = String.init(format: "Method:%ld Host:%@ Url:%@ Argument:%@", self.requestMethod().rawValue, baseUrl, requestUrl, "")
    } else {
      requestInfo = String.init(format: "Method:%ld Host:%@ Url:%@ Argument:%@", self.requestMethod().rawValue , baseUrl, requestUrl, argument!)
    }
    return requestInfo
    
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
  
  // MARK: - Network Request Delegate
  public override func requestCompletePreprocessor() {
    super.requestCompletePreprocessor()
    
    if self.writeCacheAsynchronously() {
      LYRequest.lyrequest_cache_writing_queue.async {
        self.saveResponseDataToCacheFile(super.responseData)
      }
    } else {
      self.saveResponseDataToCacheFile(super.responseData)
    }
  }
  
}

fileprivate class LYCacheMetaData: NSObject, NSCoding {

  var version: Int = 0
  var sensitiveDataString: String?
  var stringEncoding: String.Encoding?
  var creationDate: Date?
  var appVersionString: String?
  
  override init() {}
  
  required init?(coder aDecoder: NSCoder) {
    self.version = aDecoder.decodeObject(forKey: "version") as! Int
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
