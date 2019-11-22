## Now that AWSSDK Swift supports iOS and macOS as first class citizens, AWSSDK AppleOS has been deprecated. It will not receive any new updates. Please move to using AWSSDKSwift to keep up to date with changes.

# AWSSDK AppleOS Core

[<img src="http://img.shields.io/badge/swift-5.0-brightgreen.svg" alt="Swift 5.0" />](https://swift.org)
[<img src="https://travis-ci.org/swift-aws/aws-sdk-appleos-core.svg?branch=master">](https://travis-ci.org/swift-aws/aws-sdk-appleos-core)


A Core Framework for [AWSSDKAppleOS](https://github.com/swift-aws/aws-sdk-appleos)

This is the underlying driver for executing requests to AWS, but you should likely use one of the libraries provided by the package above instead of this! The code for this is based on [AWSSDKSwiftCore](https://github.com/swift-aws/aws-sdk-swift-core).


## Swift NIO

This client utilizes [Swift NIO](https://github.com/apple/swift-nio#conceptual-overview) to power its interactions with AWS. It returns an [`EventLoopFuture`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) in order to allow non-blocking frameworks to use this code. This version of aws-adk-swift-core uses the NIOTransportServices to provide network connectivity. The NIOTransportServices package is reliant on Network.framework. This means it can support all Apple platforms but is not available for Linux. Please see the Swift NIO documentation for more details, and please let us know via an Issue if you have questions!

## Including AWSSDKAppleOS in your project

AWSSDKAppleOS is built using the Swift Package Manager. If you are building a macOS console application then you can continue to use the SPM to build your application.  

### Example Package.swift

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MyAWSTool",
    platforms: [ .iOS("12.2"), .macOS(.v10_14), .tvOS("12.2") ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-appleos", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MyAWSTool",
            dependencies: ["CloudFront", "ELB", "ELBV2", "IAM"]),
        .testTarget(
            name: "MyAWSToolTests",
            dependencies: ["MyAWSTool"]),
    ]
)
```

If you are building a Cocoa app or an iOS target then you need to generate a xcodeproj file to include in your iOS/Cocoa app xcodeproj. You can generate a xcodeproj file as follows ```swift package generate-xcodeproj```. When including your project make sure you include all the frameworks you use in the Embedded Binaries section of the project settings.

## License

`aws-sdk-appleos-core` is released under the MIT license. See LICENSE for details.
