//
//  LYNetworkUtils.swift
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
  
  public class func md5String(fromString string: String) -> String {
    assert(string.characters.count > 0, "cannot use blank string")
    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digest = [UInt8](repeating: 0, count: length)
    // NSData is better and safer(in ARC) than a C string, because C strings cannot contain 0 bytes
    if let d = string.data(using: String.Encoding.utf8) {
      _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
        CC_MD5(body, CC_LONG(d.count), &digest)
      }
    }
    return (0..<length).reduce("") {
      $0 + String(format: "%02x", digest[$1])
    }
  }
  
  public class func appVersionString() -> String {
    guard let infoDict = Bundle.main.infoDictionary else {
      return ""
    }
    return infoDict["CFBundleShortVersionString"] as! String
  }
  
  public class func addDoNotBackupAttribute(_ path: String) {
    let url = NSURL.init(fileURLWithPath: path)
    do {
      try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
    } catch {
      lyDebugPrintLog(message: "error to set do not backup attribute, error = \(error)")
    }
  }
  
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




