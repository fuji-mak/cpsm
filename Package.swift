// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cpsm",
    platforms: [.macOS("13.5")],
    products: [
        .executable(name: "cpsm", targets: ["CapsomniaCLI"]),
        .library(name: "CapsomniaControl", targets: ["CapsomniaControl"])
    ],
    targets: [
        .target(name: "CapsomniaControl"),
        .executableTarget(name: "CapsomniaCLI", dependencies: ["CapsomniaControl"]),
        .testTarget(name: "CapsomniaCLITests", dependencies: ["CapsomniaControl", "CapsomniaCLI"])
    ],
    swiftLanguageVersions: [.v5]
)
