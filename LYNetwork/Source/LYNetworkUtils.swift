//
//  LYNetworkUtils.swift
//  LYNetwork
//
//  Created by 许浩男 on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation

class LYNetworkUtils {
  public class func validateJSON(_ json: AnyObject, validator jsonValidator: AnyObject) {
    if json.isKind(of: Dictionary as! AnyClass)  && jsonValidator.isKind(of: Dictionary as! AnyClass){
        
    }
  }
  
  public class func md5String(fromString string: String) -> String {
    assert(string.characters.count > 0, "cannot use blank string")
      
      
  }
  
  public class func appVersionString() -> String {
    guard let infoDict = Bundle.main.infoDictionary else {
      return ""
    }
    return infoDict["CFBundleShortVersionString"] as! String
  }
  
  public class func validateResumeData(_ data: Data) -> Bool {
    guard data.count > 0 else {
      return false
    }
    
    let resumeDictionary = PropertyListSerialization.propertyList(from: data, options: , format: NULL)
    
    guard resumeDictionary != nil else {
      return false
    }
    
    // Before iOS 9
    if #available(iOS 9.0, *) {
      // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
      // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
      // We can only assume that the plist being successfully parsed means the resume data is valid.
      return true
      } else {
      let localFilePath: String? = resumeDictionary["NSURLSessionResumeInfoLocalPath"]
      guard localFilePath != nil && localFilePath!.characters.count > 0 else {
        return false
      }
      return FileManager.default.fileExists(atPath: localFilePath!)

    }
  }
}
