# LvDBWrapper

A Objective-C++ wrapper for leveldb.

## Usage

Package.swift  
(you can also use SPM from Xcode)
```swift
let package = Package(
    name: "Demo",
    platforms: [
        .macOS(.v12),
        .iOS(.v12)
    ],
    products: [
        .executable(name: "demo", targets: ["Demo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yechentide/LvDBWrapper", branch: "main")
    ],
    targets: [
        .executableTarget(name: "Demo", dependencies: [
            .product(name: "LvDBWrapper", package: "LvDBWrapper")
        ]),
    ]
)
```

import & use
```swift
import LvDBWrapper

guard let db = LvDB(dbPath: "db-dir-path") else { ... }
guard let keyDataArray = db.getAllKeys() as? [Data] else { ... }
```

## Support

This package wrapped 2 c++ libraries: libz & libleveldb.  
Each xcframework contains 3 static .a files, which for iOS(arm64), MacOS(intel), and MacOS(apple silicon).

|                        | iOS(arm64) | MacOS(x86_64) | MacOS(arm64) | Simulator(x86) | Simulator(arm64) |
| ---------------------- | :--------: | :-----------: | :----------: | :------------: | :--------------: |
| libz.xcframework       |     ✔︎      |       ✔︎       |      ✔︎       |       ✔︎        |        ×         |
| libleveldb.xcframework |     ✔︎      |       ✔︎       |      ✔︎       |       ✔︎        |        ×         |

### attention

For MacOS projects, you can use this package directly.

For iOS projects, you need to do some additional work.  
The static libraries for iOS platform, are built with my personal apple team account.  
Maybe my account will expire some day and I can't and won't offer any guarantees.  
So if your projects is for iOS, you must rebuild libz.a and libleveldb.a for iOS.  
In this case, please replace the following files:  
`Frameworks/libz.xcframework/ios-arm64/liba.a`  
`Frameworks/libleveldb.xcframework/ios-arm64/libleveldb.a`

### Build XCFramework yourself

Just run the script and add teams or change the minimum version when needed. It's so easy!
```shell
git clone https://github.com/yechentide/LvDBWrapper.git
cd LvDBWrapper/scripts
chmod u+x build.sh
./build.sh
```

If you get the xcframeworks, you can fork this repository, and swap xcframeworks in `Frameworks` directory.
