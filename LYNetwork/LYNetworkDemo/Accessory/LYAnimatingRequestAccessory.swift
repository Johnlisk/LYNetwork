//
//  LYAnimatingRequestAccessory.swift
//  LYNetwork
//
//  Created by XuHaonan on 2017/7/9.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation
import UIKit

class LYAnimatingRequestAccessoty: LYRequestAccessory {
  public weak var animatingView: UIView?
  public var animatingText: String?
  
  public init(_ animatingView: UIView, _ animatingText: String? = nil) {
    self.animatingView = animatingView
    self.animatingText = animatingText
  }
  
  public class func accessoryAnimating(_ animatingView: UIView, _ animatingText: String? = nil) -> LYAnimatingRequestAccessoty {
    return LYAnimatingRequestAccessoty.init(animatingView, animatingText)
  }
  
  // MARK: - LYRequestAccessory
  func requestWillStart(_ request: AnyObject) {
    if self.animatingView != nil {
      DispatchQueue.main.async {
        // TODO: show loading
      }
    }
  }
  
  func requestWillStop(_ request: AnyObject) {
    if self.animatingView != nil {
      DispatchQueue.main.async {
        // TODO: hide loading
      }
    }
  }
  
  func requestDidStop(_ request: AnyObject) {
    
  }
  
}
