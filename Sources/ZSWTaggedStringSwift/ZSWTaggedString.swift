import Foundation

public let ZSW_TAGGED_STRING_ERROR_DOMAIN = "ZSWTaggedStringErrorDomain"

public enum ZSWTaggedStringErrorCode: Int {
	case invalidTags = 100
}

open class ZSWTaggedString: NSObject, NSSecureCoding {
	public let underlyingString: String
	
	open func commonInit() {}
	
	public convenience init(format: String, _ args: CVarArg...) {
		let combinedString = String(format: format, args)
		self.init(string: combinedString)
	}
	
	public init(string: String) {
		underlyingString = string
		super.init()
		commonInit()
	}
	
	open override func copy() -> Any {
		let taggedString = ZSWTaggedString(string: underlyingString)
		return taggedString
	}
	
	open override func isEqual(_ object: Any?) -> Bool {
		if let taggedString = object as? ZSWTaggedString {
			return taggedString.underlyingString == underlyingString
		} else {
			return false
		}
	}
	
	open override var hash: Int {
		return underlyingString.hash
	}
	
	open override var description: String {
		return String(format: "<%@: %p; underlying: \"%@\">", NSStringFromClass(Self.self), self, underlyingString)
	}
	
	// MARK: NSSecureCoding
	
	public required init?(coder: NSCoder) {
		guard let string = coder.decodeObject(of: NSString.self, forKey: Self._codingKey()) as String? else { return nil }
		underlyingString = string
		super.init()
		commonInit()
	}
	
	public static var supportsSecureCoding: Bool {
		return true
	}
	
	open func encode(with coder: NSCoder) {
		coder.encode(underlyingString, forKey: Self._codingKey())
	}
	
	// MARK: Generation
	
	open func string(with options: ZSWTaggedStringOptions = .default) throws -> String {
		let parser = try ZSWStringParser(
			with: self,
			options: options,
			parseTagAttributes: false
		)
		return parser.string
	}
	
	open func attributedString(with options: ZSWTaggedStringOptions = .default) throws -> NSAttributedString {
		let parser = try ZSWStringParser(
			with: self,
			options: options,
			parseTagAttributes: true
		)
		return parser.attributedString
	}
}

extension ZSWTaggedString {
	private static func _codingKey() -> String {
		return NSStringFromClass(Self.self)
	}
}
