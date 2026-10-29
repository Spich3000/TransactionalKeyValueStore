// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TransactionalStore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TransactionalStore", targets: ["TransactionalStore"]),
    ],
    targets: [
        .target(name: "TransactionalStore"),
        .testTarget(name: "TransactionalStoreTests", dependencies: ["TransactionalStore"]),
    ]
)
