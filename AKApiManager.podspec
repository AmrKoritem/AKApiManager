Pod::Spec.new do |s|

s.name = "AKApiManager"
s.summary = "AKApiManager is a layer built on top of Alamofire to facilitate restful api requests."
s.requires_arc = true

s.version = "1.1.0"
s.license = { :type => "MIT", :file => "LICENSE" }
s.author = { "Amr Koritem" => "amr.koritem92@gmail.com" }
s.homepage = "https://github.com/AmrKoritem/AKApiManager"
s.source = { :git => "https://github.com/AmrKoritem/AKApiManager.git",
             :tag => "v#{s.version}" }

s.framework = "UIKit"
s.source_files = "Sources/AKApiManager/**/*.{swift}"
s.dependency 'Alamofire', '~> 5.6.2'
s.swift_version = "5.0"
s.ios.deployment_target = '13.0'
s.tvos.deployment_target = '13.0'

end
