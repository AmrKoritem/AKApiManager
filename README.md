[![Swift](https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.0+-Orange?style=flat-square)
[![iOS](https://img.shields.io/badge/iOS-Platform-blue?style=flat-square)](https://img.shields.io/badge/iOS-Platform-Blue?style=flat-square)
[![tvOS](https://img.shields.io/badge/tvOS-Platform-blue?style=flat-square)](https://img.shields.io/badge/tvOS-Platform-Blue?style=flat-square)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-Support-yellow?style=flat-square)](https://img.shields.io/badge/CocoaPods-Support-Yellow?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-Support-yellow?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-Support-Yellow?style=flat-square)

# AKApiManager

AKApiManager is a layer built on top of Alamofire to facilitate using restful api requests. This pod suits small and medium sized applications best.<br>

## Installation

AKApiManager can be installed using [CocoaPods](https://cocoapods.org). Add the following lines to your Podfile:
```ruby
pod 'AKApiManager'
```

You can also install it using [swift package manager](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) as well.
```swift
dependencies: [
    .package(url: "https://github.com/AmrKoritem/AKApiManager.git", .upToNextMajor(from: "1.1.0"))
]
```

## Setup

All you need is to set your base url before usage. For example, you can set it in the `AppDelegate.application(_:didFinishLaunchingWithOptions:)` method.
```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AKApiManager.shared.baseUrl = "https://www.example.com"
        return true
    }
```

## Usage

For a simple api you can do just that:
```swift
    let request = DataRequest(
        url: "url-path",
        method: .post // Any http method.
    )
    AKApiManager.shared.request(request)
```

You can also pass your body parameters as well as the api headers:
```swift
    let request = DataRequest(
        url: "url-path",
        method: .post, // Any http method.
        parameters: ["param1-key": "param1-value"],
        headers: ["auth": "token"]
    )
    AKApiManager.shared.request(request) { responseStatus, response in
        // Deal with the response here.
    }
```

You can upload any data using:
```swift
    let request = UploadRequest(
        url: "url-path",
        data: Data(),
        fileName: "name",
        mimeType: "file-type"
    )
    AKApiManager.shared.upload(request) { responseStatus, response in
        // Deal with the response here.
    }
```

## Examples

You can check the example project here to see AKApiManager in action 🥳.<br>
You can check a full set of examples [here](https://github.com/AmrKoritem/AKLibrariesExamples) as well.

## Contribution 🎉

All contributions are welcome. Feel free to check the [Known issues](https://github.com/AmrKoritem/AKKeychainManager#known-issues) and [Future plans](https://github.com/AmrKoritem/AKKeychainManager#future-plans) sections if you don't know where to start. And of course feel free to raise your own issues and create PRs for them 💪

## Known issues 🫣

Thankfully, there are no known issues at the moment.

## Future plans 🧐

1 - Add a way for request cancelation.

## Find me 🥰

[LinkedIn](https://www.linkedin.com/in/amr-koritem-976bb0125/)

## License

Please check the license file.
