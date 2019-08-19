// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "AWSSDKSwiftCore",
    platforms: [ .iOS(.v12), .macOS(.v10_14), .tvOS(.v12) ],
    products: [
        .library(name: "AWSSDKSwiftCore", targets: ["AWSSDKSwiftCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from:"2.1.0")),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-aws/Perfect-INIParser.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/swift-aws/HypertextApplicationLanguage.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(
            name: "AWSSDKSwiftCore",
            dependencies: [
                "HypertextApplicationLanguage",
                "NIO",
                "NIOHTTP1",
                "NIOFoundationCompat",
                "NIOTransportServices",
                "INIParser"
            ], path: "./Sources/AWSSDKSwiftCore"),
        .testTarget(name: "AWSSDKSwiftCoreTests", dependencies: ["AWSSDKSwiftCore"], path: "./Tests/AWSSDKSwiftCoreTests")
    ]
)
