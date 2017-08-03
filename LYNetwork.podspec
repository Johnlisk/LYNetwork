Pod::Spec.new do |s|

  s.name         = "LYNetwork"
  s.version      = "0.0.1"
  s.summary      = "A high level request util based on Alamofire."
  s.homepage     = "https://github.com/ZakariyyaSv/LYNetwork"
  s.license      = "MIT"
  s.author       = { "ZakariyyaSv" => "http://zakariyyasv.pub" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "https://github.com/ZakariyyaSv/LYNetwork.git", :tag => "#{s.version}" }
  s.xcconfig         = { 'HEADER_SEARCH_PATHS' =>  '$(SDKROOT)/usr/include/CommonCrypto/CommonCrypto.h'
  s.source_files  = "LYNetwork/Source/*.{swift}"

  s.requires_arc = true
  s.dependency "Alamofire", "~> 4.4.0"

end
