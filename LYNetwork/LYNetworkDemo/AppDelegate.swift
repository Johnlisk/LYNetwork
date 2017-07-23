//
//  AppDelegate.swift
//  LYNetwork
//
//  Created by zakariyyasv on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    LYNetworkConfig.shared.baseUrl = "******"
    LYNetworkConfig.shared.debugLogEnabled = true
    return true
  }

  private func setupRequestFilters() {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let config = LYNetworkConfig.shared
    let urlFilter = LYUrlArgumentsFilter.filter(["version" : appVersion])
    config.addUrlFilter(urlFilter as! LYUrlFilterProtocol)
  }

}

