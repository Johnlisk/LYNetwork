//
//  LYChainRequestAnimatingAccessory.swift
//  LYNetwork
//
//  Created by 许浩男 on 2017/7/9.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation
import UIKit

extension LYChainRequest {
  
  public weak var animatingView: UIView? {
    get {
      guard self.animatingRequestAccessory() != nil else {
        return nil
      }
      return self.animatingRequestAccessory()!.animatingView
    }
    set {
      if self.animatingRequestAccessory() == nil {
        self.addAccessory(LYAnimatingRequestAccessoty.accessoryAnimating(newValue!))
      } else {
        self.animatingRequestAccessory()!.animatingView = newValue
      }
    }
  }
  
  public var animatingText: String? {
    get {
      guard self.animatingRequestAccessory() != nil else {
        return nil
      }
      return self.animatingRequestAccessory()!.animatingText
    }
    set {
      if self.animatingRequestAccessory() == nil {
        self.addAccessory(LYAnimatingRequestAccessoty.accessoryAnimating(nil, newValue))
      } else {
        self.animatingRequestAccessory()!.animatingText = newValue
      }
    }
  }
  
  private func animatingRequestAccessory() -> LYAnimatingRequestAccessoty? {
    guard self.requestAccessories != nil else {
      return nil
    }
    for accessory in self.requestAccessories! {
      if accessory is LYAnimatingRequestAccessoty.Type {
        return (accessory as! LYAnimatingRequestAccessoty)
      }
    }
    return nil
  }
}
