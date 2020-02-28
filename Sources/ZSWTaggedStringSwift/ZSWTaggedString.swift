import Foundation

public let ZSW_TAGGED_STRING_ERROR_DOMAIN = "ZSWTaggedStringErrorDomain"

public enum ZSWTaggedStringErrorCode: Int {
	case invalidTags = 100
}

public struct ZSWTaggedString {
	public let underlyingString: String
	
	public init(format: String, _ arguments: CVarArg...) {
		let string = String(format: format, arguments: arguments)
		self.init(string: string)
	}
	
	public init(string: String) {
		underlyingString = string
	}
	
	// MARK: Generation
	
	public func string(with options: ZSWTaggedStringOptions = .default) throws -> String {
		let parser = try ZSWStringParser(
			with: self,
			options: options,
			parseTagAttributes: false
		)
		return parser.string
	}
	
	public func attributedString(with options: ZSWTaggedStringOptions = .default) throws -> NSAttributedString {
		let parser = try ZSWStringParser(
			with: self,
			options: options,
			parseTagAttributes: true
		)
		return parser.attributedString
	}
}
