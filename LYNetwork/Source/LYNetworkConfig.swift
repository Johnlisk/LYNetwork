//
//  LYNetworkConfig.swift
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

///  LYUrlFilterProtocol can be used to append common parameters to requests before sending them.
public protocol LYUrlFilterProtocol: class {
///  Preprocess request URL before actually sending them.
  func filterUrl(url originalUrl: String,_ request: LYBaseRequest) -> String
}

///  LYCacheDirPathFilterProtocol can be used to append common path components when caching response results
public protocol LYCacheDirPathFilterProtocol: class {
///  Preprocess cache path before actually saving them.
  func filterCacheDirPath(path originPath: String, _ request: LYBaseRequest) -> String
}


class LYNetworkConfig {
  // MARK: Properties
  static let shared: LYNetworkConfig = LYNetworkConfig()
  public var baseUrl: String
  public var cdnUrl: String
  public var debugLogEnabled: Bool
  public private(set) var urlFilters: Array<LYUrlFilterProtocol>
  public private(set) var cacheDirPathFilters: Array<LYCacheDirPathFilterProtocol>
  public private(set) var sessionConfiguration: URLSessionConfiguration
  
/// The default value is 60 seconds.
  public var requestTimeoutInterval: TimeInterval {
    get {
      return self.sessionConfiguration.timeoutIntervalForRequest
    }
    set {
      self.sessionConfiguration.timeoutIntervalForRequest = newValue
    }
  }
  public var requestHTTPHeaders: [String: String?]?
  
  //  MARK: Initialization
  private init() {
    self.baseUrl = ""
    self.cdnUrl = ""
    self.debugLogEnabled = false
    self.urlFilters = []
    self.cacheDirPathFilters = []
    self.sessionConfiguration = URLSessionConfiguration()
  }
  
  //  MARK: Actions
  public func addUrlFilter(_ filter: LYUrlFilterProtocol) {
    self.urlFilters.append(filter)
  }
  
  public func clearUrlFilter() {
    self.urlFilters.removeAll()
  }
  
  public func addCacheDirPathFilter(_ filter: LYCacheDirPathFilterProtocol) {
    self.cacheDirPathFilters.append(filter)
  }
  
  public func clearCacheDirPathFilters() {
    self.cacheDirPathFilters.removeAll()
  }
  
  //  MARK: Description
  open var description: String {
    return String.init(format: "<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass(LYNetworkConfig.self), self as! CVarArg, self.baseUrl, self.cdnUrl)
  }
  
  
}
