import Foundation

open class ZSWTaggedStringOptions: NSObject, NSCopying {
	public private(set) static var `default` = ZSWTaggedStringOptions()

	public static func registerDefaultOptions(_ options: ZSWTaggedStringOptions) {
		guard let options = options.copy() as? ZSWTaggedStringOptions else { return }
		`default` = options
	}

	open var baseAttributes: [NSAttributedString.Key: Any] = [:]
	private var _private_tagToAttributesMap: [String: ZSWTaggedStringAttribute] = [:]
	private var _private_unknownTagWrapper: ZSWTaggedStringAttribute?

	open var unknownTagDynamicAttributes: ZSWDynamicAttributes? {
		return _private_unknownTagWrapper?.dynamicAttributes
	}

	open func commonInit() {}

	public init(with attributes: [NSAttributedString.Key: Any] = [:]) {
		super.init()
		commonInit()
		baseAttributes = attributes
	}

	public func copy(with zone: NSZone? = nil) -> Any {
		let options = ZSWTaggedStringOptions()
		options.baseAttributes = baseAttributes
		options._private_tagToAttributesMap = _private_tagToAttributesMap
		options._private_unknownTagWrapper = _private_unknownTagWrapper
		return options
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let object = object as? ZSWTaggedStringOptions {
			let baEq = NSDictionary(dictionary: baseAttributes).isEqual(to: object.baseAttributes)
			let tamEq = NSDictionary(dictionary: _private_tagToAttributesMap).isEqual(to: object._private_tagToAttributesMap)
			let utwEq = _private_unknownTagWrapper?.isEqual(object._private_unknownTagWrapper) ?? false
			return baEq && tamEq && utwEq
		}
		return false
	}

	open override var hash: Int {
		return NSDictionary(dictionary: baseAttributes).hash +
			NSDictionary(dictionary: _private_tagToAttributesMap).hash +
			(_private_unknownTagWrapper?.hash ?? 0)
	}

	// MARK:

	private func _private_setWrapper(attribute: ZSWTaggedStringAttribute, for tagName: String) {
		guard let copy = attribute.copy() as? ZSWTaggedStringAttribute else { return }
		_private_tagToAttributesMap[tagName.lowercased()] = copy
	}

	open func set(attributes dict: [NSAttributedString.Key: Any], for tagName: String) {
		precondition(!tagName.isEmpty)

		let attribute = ZSWTaggedStringAttribute()
		attribute.staticDictionary = dict

		_private_setWrapper(attribute: attribute, for: tagName)
	}

	open func set(dynamicAttributes: @escaping ZSWDynamicAttributes, for tagName: String) {
		precondition(!tagName.isEmpty)

		let attribute = ZSWTaggedStringAttribute()
		attribute.dynamicAttributes = dynamicAttributes

		_private_setWrapper(attribute: attribute, for: tagName)
	}

	open func set(unknownTagDynamicAttributes: @escaping ZSWDynamicAttributes) {
		let attribute = ZSWTaggedStringAttribute()
		attribute.dynamicAttributes = unknownTagDynamicAttributes

		_private_unknownTagWrapper = attribute
	}

	// MARK: Internal/updating

	func _private_updateAttributedString(string: NSMutableAttributedString, updatedWith tags: [ZSWStringParserTag]) {
		// For example, a string like '<blah></blah>' has no content, so we can 't
		// adjust what's inside based on tags. All we can do is base attributes.
		// For dynamic attributes below, we may end up calling out of bounds trying
		// to get existing attributes at index 0, which doesn't exist.
		guard string.length > 0 else { return }

		string.setAttributes(baseAttributes, range: NSMakeRange(0, string.length))

		tags.forEach { tag in
			let tagValue = _private_tagToAttributesMap[tag.tagName.lowercased()] ?? _private_unknownTagWrapper
			if let attributes = tagValue?.attributes(for: tag, attributedString: string) {
				string.addAttributes(attributes, range: tag.tagRange)
			}
		}
	}
}

extension ZSWTaggedStringOptions {
	/**
	 Attributes to be applied to an attributed string.

	 - Dynamic: Takes input about the tag to generate values.
	 - Static: Always returns the same attributes.
	 */
	public enum Attributes {
		case dynamic(ZSWDynamicAttributes)
		case `static`([NSAttributedString.Key: Any])

		init(wrapper: ZSWTaggedStringAttribute) {
			if !wrapper.staticDictionary.isEmpty {
				self = .static(wrapper.staticDictionary)
			} else if let block = wrapper.dynamicAttributes {
				self = .dynamic(block)
			} else {
				fatalError("Not static or dynamic")
			}
		}

		var wrapper: ZSWTaggedStringAttribute {
			let wrapper = ZSWTaggedStringAttribute()

			switch self {
			case .dynamic(let attributes):
				wrapper.dynamicAttributes = attributes
			case .static(let attributes):
				wrapper.staticDictionary = attributes
			}

			return wrapper
		}
	}

	/**
	 Attributes to be applied for an unknown tag.

	 For example, if you do not specify attributes for the tag `"a"` and your
	 string contains it, these attributes would be invoked for it.
	 */
	public var unknownTagAttributes: Attributes? {
		get {
			if let wrapper = _private_unknownTagWrapper {
				return Attributes(wrapper: wrapper)
			} else {
				return nil
			}
		}
		set {
			_private_unknownTagWrapper = newValue?.wrapper
		}
	}

	/**
	 Attributes for a given tag name.

	 For example, use the subscript `"a"` to set the attributes for that tag.
	 */
	public subscript(tagName: String) -> Attributes? {
		get {
			if let currentValue = _private_tagToAttributesMap[tagName] {
				return Attributes(wrapper: currentValue)
			} else {
				return nil
			}
		}
		set {
			if let attribute = newValue?.wrapper {
				_private_setWrapper(attribute: attribute, for: tagName)
			}
		}
	}
}
