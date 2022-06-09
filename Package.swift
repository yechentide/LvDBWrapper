// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LvDBWrapper",
    platforms: [
        .macOS(.v11),
        .iOS(.v11)
    ],
    products: [
        .library(name: "LvDBWrapper", targets: ["LvDBWrapper"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "libz",
            path: "Frameworks/libz.xcframework"
        ),
        .binaryTarget(
            name: "libleveldb",
            path: "Frameworks/libleveldb.xcframework"
        ),

        .target(name: "LvDBWrapper", dependencies: ["libz", "libleveldb"]),
        //.testTarget(name: "LvDBWrapperTests", dependencies: ["LvDBWrapper"]),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx11
)
