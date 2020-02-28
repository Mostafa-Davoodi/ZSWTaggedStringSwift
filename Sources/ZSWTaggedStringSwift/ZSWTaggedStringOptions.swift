import Foundation

public struct ZSWTaggedStringOptions {
	public private(set) static var `default` = ZSWTaggedStringOptions()
	
	public static func registerDefaultOptions(_ options: ZSWTaggedStringOptions) {
		`default` = options
	}
	
	public var baseAttributes: [NSAttributedString.Key: Any] = [:]
	private var _private_tagToAttributesMap: [String: ZSWDynamicAttribute] = [:]
	private var _private_unknownTagWrapper: ZSWDynamicAttribute?
	
	public var unknownTagDynamicAttributes: ZSWDynamicAttributes? {
		if case let .dynamic(dynamicAttrs) = _private_unknownTagWrapper {
			return dynamicAttrs
		}
		return nil
	}
	
	/**
	 Attributes to be applied for an unknown tag.
	 
	 For example, if you do not specify attributes for the tag `"a"` and your
	 string contains it, these attributes would be invoked for it.
	 */
	public var unknownTagAttributes: ZSWDynamicAttribute? {
		get {
			return _private_unknownTagWrapper
		}
		set {
			_private_unknownTagWrapper = newValue
		}
	}
	
	/**
	 Attributes for a given tag name.
	 
	 For example, use the subscript `"a"` to set the attributes for that tag.
	 */
	public subscript(tagName: String) -> ZSWDynamicAttribute? {
		get {
			return _private_tagToAttributesMap[tagName.lowercased()]
		}
		set {
			if let attributes = newValue {
				_private_tagToAttributesMap[tagName.lowercased()] = attributes
			}
		}
	}
	
	public init(with attributes: [NSAttributedString.Key: Any] = [:]) {
		baseAttributes = attributes
	}
	
	// MARK: Internal/updating
	
	func updateAttributedString(string: NSMutableAttributedString, updatedWith tags: [ZSWStringParserTag]) {
		// For example, a string like '<blah></blah>' has no content, so we can 't
		// adjust what's inside based on tags. All we can do is base attributes.
		// For dynamic attributes below, we may end up calling out of bounds trying
		// to get existing attributes at index 0, which doesn't exist.
		guard string.length > 0 else { return }
		
		string.setAttributes(baseAttributes, range: NSMakeRange(0, string.length))
		
		tags.forEach { tag in
			let tagValue = self[tag.tagName.lowercased()] ?? unknownTagAttributes
			if let attributes = tagValue?.attributes(for: tag, attributedString: string) {
				string.addAttributes(attributes, range: tag.tagRange)
			}
		}
	}
}
