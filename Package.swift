// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CloutMarket",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CloutMarket", targets: ["CloutMarket"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.0.0")
    ],
    targets: [
        .target(
            name: "CloutMarket",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "StripePaymentSheet", package: "stripe-ios")
            ]
        ),
        .testTarget(
            name: "CloutMarketTests",
            dependencies: ["CloutMarket"]
        ),
    ]
) 