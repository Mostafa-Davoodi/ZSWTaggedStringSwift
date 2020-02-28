import XCTest
@testable import ZSWTaggedStringSwift

final class ZSWTaggedStringSwiftTests: XCTestCase {
	func initialization() {
		let string = ZSWTaggedString(format: "test %@", "a")
		XCTAssertEqual(string.underlyingString, "test bc")
	}

	func initializeByString() {
		let string = ZSWTaggedString(string: "a string")
		XCTAssertEqual(string.underlyingString, "a string")
	}

	func invalidStrings() {
		let string = ZSWTaggedString(string: "<a>moo</aj>")
		do {
			let output = try string.string()
			XCTFail("should have thrown but got \(output)")
		} catch let error as NSError {
			XCTAssertEqual(error.domain, ZSW_TAGGED_STRING_ERROR_DOMAIN)
			XCTAssertEqual(error.code, ZSWTaggedStringErrorCode.invalidTags.rawValue)
		}
	}

	static var allTests = [
		("initialization", initialization),
		("initializeByString", initializeByString),
		("invalidStrings", invalidStrings),
	]
}
