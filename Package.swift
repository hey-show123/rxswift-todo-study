// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RxTodoApp",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.7.0")
    ],
    targets: [
        .executableTarget(
            name: "RxTodoApp",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift")
            ],
            path: "RxTodoApp"
        )
    ]
)
