//
//  LYNetworkPrivate.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/23.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

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


