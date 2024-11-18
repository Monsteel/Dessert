// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "Dessert",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
    .custom("visionOS", versionString: "1.0")
  ],
  products: [
    .library(
      name: "Dessert",
      targets: ["Dessert"]
    ),
    .library(
      name: "CombineDessert",
      targets: ["CombineDessert"]
    ),
    .library(
      name: "RxDessert",
      targets: ["RxDessert"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
  ],
  targets: [
    .target(
      name: "Dessert",
      dependencies: []
    ),
    .target(
      name: "CombineDessert",
      dependencies: ["Dessert"]
    ),
    .target(
      name: "RxDessert",
      dependencies: ["Dessert", "RxSwift"]
    ),
  ]
)
