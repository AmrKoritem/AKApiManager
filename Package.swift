// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AKApiManager",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "AKApiManager",
            targets: ["AKApiManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.2"))
    ],
    targets: [
        .target(
            name: "AKApiManager",
            dependencies: [
                "Alamofire"
            ]),
        .testTarget(
            name: "AKApiManagerTests",
            dependencies: ["AKApiManager"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
