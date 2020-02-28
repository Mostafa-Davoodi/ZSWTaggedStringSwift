import Foundation

/**
 Dynamic attributes executed for a tag

 Below parameters are for an example tag of:

 `<a href="http://google.com">`

 - Parameter tagName: This would be `"a"` in the example.
 - Parameter tagAttributes: This would be `["href": "http://google.com"]` in the example.
 - Parameter existingStringAttributes: The attributes for the generated attributed string at the given tag start location before applying the given attributes.

 - Returns: The `NSAttributedString` attributes you wish to be applied for the tag.

 */
public typealias ZSWDynamicAttributes = (_ tagName: String, _ tagAttributes: [String: Any], _ existingStringAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any]
