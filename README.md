# LYNetwork

![LYNetwork](https://github.com/ZakariyyaSv/LYNetwork/raw/master/screenshot/logo.jpeg)

![build status](https://travis-ci.org/ZakariyyaSv/LYNetwork.svg?branch=master)
![License MIT](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)
![Pod version](https://img.shields.io/cocoapods/v/LYNetwork.svg?style=flat)
[![Platform](https://img.shields.io/cocoapods/p/LYNetwork.svg?style=flat)](http://cocoadocs.org/docsets/LYNetwork)

LYNetwork is a high level request util based on [Alamofire].

## Features

- [x] Support common base URL and CDN URL
- [x] Validate JSON response
- [x] Support `closure` and `delegate` callback for request
- [x] Batch requests (see `LYBatchRequest`)
- [x] Chain requests (see `LYChainRequest`)
- [x] URL filter, replace part of URL, or append common parameter 
- [x] Response can be cached by expiration time
- [x] Response can be cached by version number
- [ ] Support Upload and download task
- [ ] Support Authentication

## Installation

### Cocoapods

```ruby
    pod 'LYNetwork'
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate LYNetwork into your project manually.

## Usage


## Requirements

| LYNetwork Version | Alamofire Version | Swift Version |  Minimum iOS Target | Note |
|:------------------:|:--------------------:|:--------------------:|:-------------------:|:-----|
| 0.x | 4.3.x & below | swift 3.0 | iOS 8 | Xcode 8+ is required. |

LYNetwork is based on Alamofire. You can find more detail about version compability at [Alamofire].

## Acknowledgements

 * [Alamofire]
 * [YTKNetwork]

 Thanks for their great work.

## License

YTKNetwork is available under the MIT license. See the LICENSE file for more info.

<!-- external links -->
[Alamofire]:https://github.com/Alamofire/Alamofire
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork
