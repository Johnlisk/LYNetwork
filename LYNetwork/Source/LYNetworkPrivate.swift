//
//  LYNetworkPrivate.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/23.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

// MARK: - Debug Logger
func lyDebugPrintLog<T>(message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line) {
  #if DEBUG
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
      case -999: // kCFURLErrorCancelled The connection was cancelled.
        return ""
      case -1008..<(-999): // CFURLConnection & CFURLProtocol Errors
        return "网络异常，请重试（错误代码:\(self.code))"
      case -1009: // kCFURLErrorNotConnectedToInternet The connection failed because the device is not connected to the internet.
        return "网络连接错误,请检查网络设置"
      case -1010: // The connection was redirected to a nonexistent location
        return "网络异常，请重试（错误代码:\(self.code))"
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
    case NSCocoaErrorDomain:
      if self.code == 3840 {
        return "服务器正在维护，请稍候"
      } else {
        return self.localizedDescription
      }
    default:
      return self.localizedDescription
    }
  }
}


