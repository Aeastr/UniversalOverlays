// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "UniversalOverlays",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "UniversalOverlays",
            targets: ["UniversalOverlays"]),
    ],
    targets: [
        .target(name: "UniversalOverlays"),
    ]
)
