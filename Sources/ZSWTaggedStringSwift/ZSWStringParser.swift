import Foundation

let kTagStart = "<"
let kTagEnd = ">"
let kTagIgnore = "\01"
let kIgnoredTagStart = "\01<"

extension unichar: ExpressibleByUnicodeScalarLiteral {
	public typealias UnicodeScalarLiteralType = UnicodeScalar
	
	public init(unicodeScalarLiteral scalar: UnicodeScalar) {
		self.init(scalar.value)
	}
}

public func ZSWEscapedString(for unescapedString: String) -> String {
	return unescapedString.replacingOccurrences(of: kTagStart, with: kIgnoredTagStart)
}

open class ZSWStringParser: NSObject {
	public let attributedString: NSAttributedString
	
	open var string: String {
		return attributedString.string
	}
	
	public init(
		with taggedString: ZSWTaggedString,
		options: ZSWTaggedStringOptions,
		parseTagAttributes: Bool
	) throws {
		let scanner = Scanner(string: taggedString.underlyingString)
		scanner.charactersToBeSkipped = nil
		
		let pendingString = NSMutableAttributedString()
		var tagStack: [ZSWStringParserTag] = []
		var finishedTags: [ZSWStringParserTag] = []
		
		let tagStartCharacterSet = CharacterSet(charactersIn: kTagStart)
		let tagEndCharacterSet = CharacterSet(charactersIn: kTagEnd)
		
		while !scanner.isAtEnd {
			var scratchString: NSString?
			scanner.scanUpToCharacters(from: tagStartCharacterSet, into: &scratchString)
			Self.append(string: scratchString, into: pendingString)
			
			if scanner.isAtEnd {
				// No tag were found; we're done.
				break
			}
			
			// Eat the < nom nom nom
			scanner.scanCharacters(from: tagStartCharacterSet, into: nil)
			
			if let str = scratchString, String(str.character(at: str.length - 1)) == kTagIgnore {
				// We found a tag start, but it's one that's been escaped. Skip it, and append the start tag we just gobbled up.
				pendingString.deleteCharacters(in: NSMakeRange(pendingString.length - 1, 1))
				Self.append(string: kTagStart as NSString?, into: pendingString)
				continue
			}
			
			scratchString = nil
			scanner.scanUpToCharacters(from: tagEndCharacterSet, into: &scratchString)
			if scanner.isAtEnd {
				Self.append(string: scratchString, into: pendingString)
				break
			}
			
			// Eat the > nom nom nom
			scanner.scanCharacters(from: tagEndCharacterSet, into: nil)
			
			let tagScanner = Scanner(string: scratchString as String? ?? "")
			var tagName: NSString?
			let scannedSpace = tagScanner.scanUpToCharacters(from: .whitespaces, into: &tagName)
			if let tagName = tagName as String? {
				let tag = ZSWStringParserTag(tagName: tagName, location: pendingString.length)
				if scannedSpace, parseTagAttributes {
					tagScanner.scanCharacters(from: .whitespaces, into: nil)
					let str = tagScanner.string
					let idx = str.index(str.startIndex, offsetBy: tagScanner.scanLocation)
					let attrsStr = String(str[idx...])
					tag.addRawTagAttributes(attrsStr)
				}
				
				let lastTag = tagStack.last
				if let lastTag = lastTag, lastTag.isEnded(by: tag) {
					lastTag.update(with: tag)
					tagStack.removeLast()
					finishedTags.insert(lastTag, at: 0)
				} else if tag.isEndingTag {
					throw NSError(
						domain: ZSW_TAGGED_STRING_ERROR_DOMAIN,
						code: ZSWTaggedStringErrorCode.invalidTags.hashValue,
						userInfo: ["developerError": String(format: "String had ending tag %@ when we expected ending tag %@ or new tag", tag.tagName, lastTag?.tagName ?? "")]
					)
				} else {
					tagStack.append(tag)
				}
			}
		}
		
		if !tagStack.isEmpty {
			throw NSError(
				domain: ZSW_TAGGED_STRING_ERROR_DOMAIN,
				code: ZSWTaggedStringErrorCode.invalidTags.hashValue,
				userInfo: ["developerError": String(format: "Reached end of string with %@ tags remaining (%@)", tagStack.count, tagStack.map { $0.tagName }.joined(separator: ", "))]
			)
		}
		options._private_updateAttributedString(string: pendingString, updatedWith: finishedTags)
		attributedString = pendingString
		super.init()
	}
	
	public static func append(string: NSString?, into attributedString: NSMutableAttributedString) {
		guard let string = string as String?, !string.isEmpty else { return }
		
		attributedString.append(NSAttributedString(string: string))
	}
}
