# aws-sdk-swift-core

<div>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.0-brightgreen.svg" alt="Swift 5.0" />
    </a>
    <a href="https://travis-ci.org/swift-aws/aws-sdk-appleos-core">
        <img src="https://travis-ci.org/swift-aws/aws-sdk-appleos-core.svg?branch=master" alt="Travis Build" />
    </a>
</div>

A Core Framework for [AWSSDKSwift](https://github.com/swift-aws/aws-sdk-swift) supporting Apple platforms including iOS as first class citizens.

This is the underlying driver for executing requests to AWS, but you should likely use one of the libraries provided by the package above instead of this! The code for this is based on [AWSSDKSwiftCore](https://github.com/swift-aws/aws-sdk-swift-core). 


## Swift NIO

This client utilizes [Swift NIO](https://github.com/apple/swift-nio#conceptual-overview) to power its interactions with AWS. It returns an [`EventLoopFuture`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) in order to allow non-blocking frameworks to use this code. This version of aws-swift-core uses the NIOTransportServices to provide network connectivity. Please see the Swift NIO documentation for more details, and please let us know via an Issue if you have questions!

## Example Package.swift

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MyAWSTool",
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-appleos", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "MyAWSTool",
            dependencies: ["CloudFront", "ELB", "ELBV2",  "IAM"]),
        .testTarget(
            name: "MyAWSToolTests",
            dependencies: ["MyAWSTool"]),
    ]
)
```

## License

`aws-sdk-appleos-core` is released under the MIT license. See LICENSE for details.
