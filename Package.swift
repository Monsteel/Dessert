// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "NetworkKit",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
    .custom("visionOS", versionString: "1.0")
  ],
  products: [
    .library(
      name: "NetworkKit",
      targets: ["NetworkKit","CombineNetworkKit", "RxNetworkKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
  ],
  targets: [
    .target(
      name: "NetworkKit",
      dependencies: []
    ),
    .target(
      name: "CombineNetworkKit",
      dependencies: ["NetworkKit"]
    ),
    .target(
      name: "RxNetworkKit",
      dependencies: ["NetworkKit", "RxSwift"]
    ),
  ]
)
