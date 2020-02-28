import Foundation

open class ZSWTaggedStringAttribute: NSObject, NSCopying {
	open var staticDictionary: [NSAttributedString.Key: Any] = [:]
	open var dynamicAttributes: ZSWDynamicAttributes?

	open func copy(with zone: NSZone? = nil) -> Any {
		let attribute = ZSWTaggedStringAttribute()
		attribute.staticDictionary = staticDictionary
		attribute.dynamicAttributes = dynamicAttributes
		return attribute
	}

	open override func isEqual(_ object: Any?) -> Bool {
		if let object = object as? ZSWTaggedStringAttribute {
			let sdEq = NSDictionary(dictionary: staticDictionary).isEqual(to: object.staticDictionary)
			let daPointer = UnsafePointer(&dynamicAttributes)
			let odaPointer = UnsafePointer(&object.dynamicAttributes)
			let daEq = daPointer == odaPointer
			return sdEq && daEq
		}
		return false
	}

	open override var hash: Int {
		return NSDictionary(dictionary: staticDictionary).hash + dynamicAttributes.debugDescription.hash
	}

	open func attributes(for tag: ZSWStringParserTag, attributedString: NSAttributedString) -> [NSAttributedString.Key: Any] {
		if !staticDictionary.isEmpty {
			return staticDictionary
		}
		if let dynamicAttributes = dynamicAttributes {
			let existingAttributes = attributedString.attributes(at: tag.location, effectiveRange: nil)
			return dynamicAttributes(tag.tagName, tag.tagAttributes, existingAttributes)
		}
		return [:]
	}
}
