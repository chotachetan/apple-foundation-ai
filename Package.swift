// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppleFoundationAIDemo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "AppleFoundationAIDemo",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "StableDiffusion", package: "mlx-swift-examples")
            ]
        )
    ]
)
