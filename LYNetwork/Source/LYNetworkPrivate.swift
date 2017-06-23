//
//  LYNetworkPrivate.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/23.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

//  MARK: RequestAccessory
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
