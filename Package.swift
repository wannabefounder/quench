// swift-tools-version:5.9
import PackageDescription

// QuenchEngine is pure Foundation and builds everywhere (CI runs it on Linux).
// The macOS app target + GRDB only exist when the manifest is evaluated on macOS.
var targets: [Target] = [
    .target(name: "QuenchEngine", path: "QuenchApp/Engine"),
    .testTarget(name: "QuenchTests", dependencies: ["QuenchEngine"], path: "QuenchTests"),
]
var deps: [Package.Dependency] = []
var products: [Product] = [.library(name: "QuenchEngine", targets: ["QuenchEngine"])]

#if os(macOS)
deps.append(.package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"))
targets.append(.executableTarget(
    name: "QuenchApp",
    dependencies: ["QuenchEngine", .product(name: "GRDB", package: "GRDB.swift")],
    path: "QuenchApp",
    exclude: ["Engine", "Resources"]
))
targets.append(.executableTarget(
    name: "QuenchBrowserBridge",
    dependencies: [],
    path: "QuenchBrowserBridge"
))
products.append(.executable(name: "QuenchApp", targets: ["QuenchApp"]))
products.append(.executable(name: "QuenchBrowserBridge", targets: ["QuenchBrowserBridge"]))
#endif

let package = Package(
    name: "Quench",
    platforms: [.macOS(.v14)],
    products: products,
    dependencies: deps,
    targets: targets
)
