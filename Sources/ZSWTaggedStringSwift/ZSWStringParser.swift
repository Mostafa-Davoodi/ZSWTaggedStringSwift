import Foundation

let kTagStart = "<"
let kTagEnd = ">"
let kTagIgnore = "\01"
let kIgnoredTagStart = "\01<"

public func ZSWEscapedString(for unescapedString: String) -> String {
	return unescapedString.replacingOccurrences(of: kTagStart, with: kIgnoredTagStart)
}

public struct ZSWStringParser {
	public let attributedString: NSAttributedString
	
	public var string: String {
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
			var scratchString = Helper.scanUpToCharacters(using: scanner, from: tagStartCharacterSet)
			Helper.append(string: scratchString, into: pendingString)
			
			if scanner.isAtEnd {
				// No tag were found; we're done.
				break
			}
			
			// Eat the < nom nom nom
			Helper.scanCharacters(using: scanner, from: tagStartCharacterSet)
			
			if let str = scratchString?.last, String(str) == kTagIgnore {
				// We found a tag start, but it's one that's been escaped. Skip it, and append the start tag we just gobbled up.
				pendingString.deleteCharacters(in: NSMakeRange(pendingString.length - 1, 1))
				Helper.append(string: kTagStart, into: pendingString)
				continue
			}
			
			scratchString = Helper.scanUpToCharacters(using: scanner, from: tagEndCharacterSet)
			if scanner.isAtEnd {
				Helper.append(string: scratchString, into: pendingString)
				break
			}
			
			// Eat the > nom nom nom
			Helper.scanCharacters(using: scanner, from: tagEndCharacterSet)
			
			let tagScanner = Scanner(string: scratchString as String? ?? "")
			let tagName = Helper.scanUpToCharacters(using: tagScanner, from: .whitespaces)
			let scannedSpace = tagName?.trimmingCharacters(in: .whitespaces).isEmpty == false
			if let tagName = tagName {
				var tag = ZSWStringParserTag(tagName: tagName, location: pendingString.length)
				if scannedSpace, parseTagAttributes {
					Helper.scanCharacters(using: tagScanner, from: .whitespaces)
					let str = tagScanner.string
					let idx = str.index(str.startIndex, offsetBy: tagScanner.scanLocation)
					let attrsStr = String(str[idx...])
					tag.addRawTagAttributes(attrsStr)
				}
				
				let lastTag = tagStack.last
				if var lastTag = lastTag, lastTag.isEnded(by: tag) {
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
		options.updateAttributedString(string: pendingString, updatedWith: finishedTags)
		attributedString = pendingString
	}
}
