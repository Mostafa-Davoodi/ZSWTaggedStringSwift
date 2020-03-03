// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ZSWTaggedStringSwift",
	products: [
		.library(
			name: "ZSWTaggedStringSwift",
			targets: ["ZSWTaggedStringSwift"]
		),
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "ZSWTaggedStringSwift",
			dependencies: []
		),
		.testTarget(
			name: "ZSWTaggedStringSwiftTests",
			dependencies: [
				"ZSWTaggedStringSwift",
			]
		),
	]
)
