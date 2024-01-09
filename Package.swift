// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PublicCodingKeys",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PublicCodingKeys",
            targets: ["PublicCodingKeys"]
        ),
        .executable(
            name: "PublicCodingKeysClient",
            targets: ["PublicCodingKeysClient"]
        )
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", .upToNextMajor(from: "0.2.2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "PublicCodingKeysMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "PublicCodingKeys", dependencies: ["PublicCodingKeysMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "PublicCodingKeysClient", dependencies: ["PublicCodingKeys"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "PublicCodingKeysTests",
            dependencies: [
                "PublicCodingKeysMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing")
            ]
        ),
    ]
)
