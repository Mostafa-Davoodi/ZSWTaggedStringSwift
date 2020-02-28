import Foundation

/**
 Attributes to be applied to an attributed string.

 - Dynamic: Takes input about the tag to generate values.
 - Static: Always returns the same attributes.
 */
public enum ZSWDynamicAttribute {
	case dynamic(ZSWDynamicAttributes)
	case `static`([NSAttributedString.Key: Any])

	public func attributes(for tag: ZSWStringParserTag, attributedString: NSAttributedString) -> [NSAttributedString.Key: Any] {
		switch self {
		case let .static(staticAttrs):
			return staticAttrs
		case let .dynamic(dynamicAttrs):
			let existingAttributes = attributedString.attributes(at: tag.location, effectiveRange: nil)
			return dynamicAttrs(tag.tagName, tag.tagAttributes, existingAttributes)
		}
	}
}
