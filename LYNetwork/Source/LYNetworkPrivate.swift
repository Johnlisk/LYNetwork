//
//  LYNetworkPrivate.swift
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
import CommonCrypto

// MARK: - Debug Logger
func lyDebugPrintLog<T>(message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line) {
  #if DEBUG
    if !LYNetworkConfig.shared.debugLogEnabled {
      return
    }
    print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
  #endif
}

//  MARK: - RequestAccessory
extension LYBaseRequest {
  public func toggleAccessoriesWillStartCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestWillStart(self)
      })
    }
  }
  
  public func toggleAccessoriesWillStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestWillStop(self)
      })
    }
  }
  
  public func toggleAccessoriesDidStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestDidStop(self)
      })
    }
  }
}


extension LYBatchRequest {
  public func toggleAccessoriesWillStartCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestWillStart(self)
      })
    }
  }
  
  public func toggleAccessoriesWillStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestWillStop(self)
      })
    }
  }
  
  public func toggleAccessoriesDidStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestDidStop(self)
      })
    }
  }
}

extension LYChainRequest {
  public func toggleAccessoriesWillStartCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories?.forEach({ (accessory) in
        accessory.requestWillStart(self)
      })
    }
  }
  
  public func toggleAccessoriesWillStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestWillStop(self)
      })
    }
  }
  
  public func toggleAccessoriesDidStopCallBack() {
    if self.requestAccessories != nil {
      self.requestAccessories!.forEach({ (accessory) in
        accessory.requestDidStop(self)
      })
    }
  }
  
}

// MARK: - Equatable
extension Array where Element: Equatable {
  
  // Remove first collection element that is equal to the given `object`:
  mutating func remove(_ object: Element) {
    if let index = index(of: object) {
      remove(at: index)
    }
  }
}

extension LYBatchRequest: Equatable {
  public static func ==(lhs: LYBatchRequest, rhs: LYBatchRequest) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
}

extension LYChainRequest: Equatable {
  public static func ==(lhs: LYChainRequest, rhs: LYChainRequest) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
}

// MARK: - LYNetworkError
open class LYNetworkError {
  open class func summaryFrom(error: Error, response: HTTPURLResponse?) -> String {
    if let statusCode = response?.statusCode {
      switch statusCode {
      case 400..<500: // Client Errors
        return "客户端错误（HTTP错误代码: \(statusCode)）"
      case 500..<600: // Server Errors
        return "网络异常，请重试（HTTP错误代码: \(statusCode)）"
      default:
        break
      }
    }
    let nsError: NSError = error as NSError
    return nsError.lyDescription()
  }
}

public extension String {
  public func MD5String() -> String? {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digest = [UInt8](repeating: 0, count: length)
    
    if let d = self.data(using: String.Encoding.utf8) {
      _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
        CC_MD5(body, CC_LONG(d.count), &digest)
      }
    }
    
    return (0..<length).reduce("") {
      $0 + String(format: "%02x", digest[$1])
    }
  }
}

public extension NSError {
  // This description should cover NSURLErrorDomain & CFNetworkErrors and
  // give a easy understanding description with error code.
  // view the details on http://nshipster.com/nserror/
  func lyDescription() -> String {
    switch self.domain {
    case NSURLErrorDomain:
      switch self.code {
      case -1..<110: // Network Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case 110..<119: //SOCKS4 Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case 120..<130: //SOCKS5 Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case 200..<300: // FTP Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case 300..<400: // HTTP Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case -998: // kCFURLErrorUnknown An unknown error occurred.
        return "网络异常，请重试（错误代码:\(self.code))"
      case -999: // kCFURLErrorCancelled/NSURLErrorCancelled The connection was cancelled.
        return ""
      case -1000: // kCFURLErrorBadURL/NSURLErrorBadURL
        return ""
      case -1001: // kCFURLErrorTimedOut/NSURLErrorTimedOut
        return ""
      case -1002: // kCFURLErrorUnsupportedURL/NSURLErrorUnsupportedURL
        return ""
      case -1003: // kCFURLErrorCannotFindHost/NSURLErrorCannotFindHost
        return ""
      case -1004: // kCFURLErrorCannotConnectToHost/NSURLErrorCannotConnectToHost
        return ""
      case -1005: // kCFURLErrorNetworkConnectionLost/NSURLErrorNetworkConnectionLost
        return ""
      case -1006: // kCFURLErrorDNSLookupFailed/NSURLErrorDNSLookupFailed
        return ""
      case -1007: // kCFURLErrorHTTPTooManyRedirects/NSURLErrorHTTPTooManyRedirects
        return ""
      case -1008..<(-999): // CFURLConnection & CFURLProtocol Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case -1009: // kCFURLErrorNotConnectedToInternet/NSURLErrorNotConnectedToInternet The connection failed because the device is not connected to the internet.
        return "网络连接错误,请检查网络设置"
      case -1010: // kCFURLErrorRedirectToNonExistentLocation/NSURLErrorRedirectToNonExistentLocation The connection was redirected to a nonexistent location
        return "网络异常，请重试（错误代码:\(self.code))"
      case -1011: // kCFURLErrorBadServerResponse/NSURLErrorBadServerResponse
        return ""
      case -1012: // kCFURLErrorUserCancelledAuthentication/NSURLErrorUserCancelledAuthentication
        return ""
      case -1013: // kCFURLErrorUserAuthenticationRequired/NSURLErrorUserAuthenticationRequired
        return ""
      case -1014: // kCFURLErrorZeroByteResource/NSURLErrorZeroByteResource
        return ""
      case -1015: // kCFURLErrorCannotDecodeRawData/NSURLErrorCannotDecodeRawData
        return ""
      case -1016: // kCFURLErrorCannotDecodeContentData/NSURLErrorCannotDecodeContentData
        return ""
      case -1017: // kCFURLErrorCannotParseResponse/NSURLErrorCannotParseResponse
        return ""
      case -1018: // kCFURLErrorInternationalRoamingOff 国际漫游
        return ""
      case -1019: // kCFURLErrorCallIsActive
        return ""
      case -1020: // kCFURLErrorDataNotAllowed
        return ""
      case -1021: // kCFURLErrorRequestBodyStreamExhausted
        return ""
      case -1022: // kCFURLErrorAppTransportSecurityRequiresSecureConnection
        return ""
      case -1103..<(-1099): // FTP Errors
        return "手机系统异常，请重装应用（错误代码:\(self.code))"
      case -1999..<(-1199): // SSL Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case -3007..<(-1999): // Download and File I/O Errors
        return "手机系统异常，请重装应用（错误代码:\(self.code))"
      case -4000: // Cookie errors
        return "网络异常，请重启应用（错误代码:\(self.code))"
      case -73000..<(-71000): // CFNetServices Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      default:
        return self.localizedDescription
      }
    default:
      return self.localizedDescription
    }
  }
}


