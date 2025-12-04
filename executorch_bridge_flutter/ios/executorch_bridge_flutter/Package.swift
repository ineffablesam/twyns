// swift-tools-version: 5.9

// This Package.swift file defines the ExecuTorch dependencies for the plugin.
// 
// IMPORTANT FOR FLUTTER USERS:
// Flutter uses CocoaPods, not SPM directly, so this file won't automatically
// configure your project. You must manually:
// 1. Add ExecuTorch package in Xcode (see README.md)
// 2. Add -all_load to Other Linker Flags in Build Settings
//
// This file is primarily for:
// - Plugin development
// - Direct SPM usage (non-Flutter)
// - Reference for which ExecuTorch products are needed

import PackageDescription

let package = Package(
    name: "executorch_bridge_flutter",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .library(
            name: "executorch-bridge-flutter",
            targets: ["executorch_bridge_flutter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pytorch/executorch",
            branch: "swiftpm-1.0.1"
        )
    ],
    targets: [
        .target(
            name: "executorch_bridge_flutter",
            dependencies: [
                .product(name: "executorch_llm_debug", package: "executorch"),
                .product(name: "kernels_quantized", package: "executorch"),
                .product(name: "kernels_optimized", package: "executorch"),
                .product(name: "executorch_debug", package: "executorch"),
                .product(name: "backend_xnnpack", package: "executorch"),
                .product(name: "kernels_torchao", package: "executorch"),
                .product(name: "backend_mps", package: "executorch"),
                .product(name: "kernels_llm", package: "executorch"),
                .product(name: "backend_coreml", package: "executorch")
            ],
            resources: [],
            linkerSettings: [
                .unsafeFlags(["-all_load"], .when(platforms: [.iOS]))
            ]
        )
    ]
)