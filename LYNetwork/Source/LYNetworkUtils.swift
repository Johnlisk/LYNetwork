//
//  LYNetworkUtils.swift
//  LYNetwork
//
//  Created by 许浩男 on 2017/6/22.
//  Copyright © 2017年 yangqianguan.com. All rights reserved.
//

import Foundation
import Darwin

class LYNetworkUtils {
  public class func validateJSON(_ jsonObject: AnyObject, validator jsonValidator: AnyObject) -> Bool {
    if jsonObject is Dictionary<String, AnyObject> && jsonValidator is Dictionary<String, AnyObject>{
      let dict = jsonObject as! Dictionary<String, AnyObject>
      let validator = jsonValidator as! Dictionary<String, AnyObject>
      var result = true
      
      for key in validator.keys {
        let value = dict[key]
        let format = validator[key]
        if value is Dictionary<String, AnyObject> || value is Array<AnyObject> {
          result = self.validateJSON(value!, validator: format!)
          if !result {
            break
          }
        } else {
          
          if !(jsonObject.isKind(of: type(of: format) as! AnyClass)) || !(value is NSNull) {
            result = false
            break
          }
        }
      }
      return result
    } else if jsonObject is Array<AnyObject> && jsonValidator is Array<AnyObject> {
      let validatorList = jsonValidator as! Array<AnyObject>
      if validatorList.count > 0 {
        let jsonList = jsonObject as! Array<AnyObject>
        let validatorDict = jsonValidator.firstObject as! Dictionary<String, AnyObject>
        for item in jsonList {
          let result: Bool = self.validateJSON(item, validator: validatorDict as AnyObject)
          if !result {
            return false
          }
        }
      }
      return true
    } else if jsonObject.isKind(of: type(of: jsonValidator) ) {
      return true
    } else {
      return false
    }
  }
  
//  public class func md5String(fromString string: String) -> String {
//    assert(string.characters.count > 0, "cannot use blank string")
//    let length = Int(CC_MD5_DIGEST_LENGTH)
//    var digest = [UInt8](repeating: 0, count: length)
//    // NSData is better and safer(in ARC) than a C string, because C strings cannot contain 0 bytes
//    if let d = string.data(using: String.Encoding.utf8) {
//      _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
//        CC_MD5(body, CC_LONG(d.count), &digest)
//      }
//    }
//    return (0..<length).reduce("") {
//      $0 + String(format: "%02x", digest[$1])
//    }
//  }
  
  public class func appVersionString() -> String {
    guard let infoDict = Bundle.main.infoDictionary else {
      return ""
    }
    return infoDict["CFBundleShortVersionString"] as! String
  }
  
//  public class func validateResumeData(_ data: Data) -> Bool {
//    guard data.count > 0 else {
//      return false
//    }
//    
//    var resumeDictionary: PropertyListSerialization?
//    do {
//      try resumeDictionary = PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions.mutableContainers, format: nil) as? PropertyListSerialization
//    } catch error {
//      print(error)
//    }
    
    
//    
//    guard resumeDictionary != nil else {
//      return false
//    }
//    
//    // Before iOS 9
//    if #available(iOS 9.0, *) {
//      // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
//      // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
//      // We can only assume that the plist being successfully parsed means the resume data is valid.
//      return true
//      } else {
//      let localFilePath: String? = resumeDictionary["NSURLSessionResumeInfoLocalPath"]
//      guard localFilePath != nil && localFilePath!.characters.count > 0 else {
//        return false
//      }
//      return FileManager.default.fileExists(atPath: localFilePath!)
//    }
//  }
  
  public class func stringEncodingWithRequest(_ request: LYBaseRequest) -> String.Encoding {
    var stringEncoding = String.Encoding.utf8
    if let textEncodingName = request.response?.textEncodingName {
      let encoding = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
      if encoding != kCFStringEncodingInvalidId {
        stringEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
      }
    }
    return stringEncoding
  }
}




