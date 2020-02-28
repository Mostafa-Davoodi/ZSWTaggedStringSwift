import Foundation

public struct ZSWStringParserTag {
	public let tagName: String
	public let location: Int
	var endLocation: Int
	var tagAttributes: [String: String]
	
	#if DEBUG
	var rawAttributes: String = ""
	#endif
	
	public init(tagName: String, location: Int) {
		self.tagName = tagName
		self.location = location
		self.endLocation = location
		self.tagAttributes = [:]
	}
	
	public var isEndingTag: Bool {
		return tagName.hasPrefix("/")
	}
	
	public func isEnded(by tag: ZSWStringParserTag) -> Bool {
		if !tag.isEndingTag {
			return false
		}
		let str = tag.tagName.lowercased()
		let idx = str.index(str.startIndex, offsetBy: 1)
		if str[idx...] != tagName.lowercased() {
			return false
		}
		return true
	}
	
	public mutating func update(with tag: ZSWStringParserTag) {
		guard isEnded(by: tag) else {
			preconditionFailure("Didn't check before updating tag")
		}
		endLocation = tag.location
	}
	
	public var tagRange: NSRange {
		if endLocation < location {
			return NSMakeRange(location, 0)
		} else {
			return NSMakeRange(location, endLocation - location)
		}
	}
	
	public mutating func addRawTagAttributes(_ rawTagAttributes: String) {
		let scanner = Scanner(string: rawTagAttributes)
		scanner.charactersToBeSkipped = nil
		
		var tagAttributes: [String: String] = [:]
		
		let nameBreakSet = CharacterSet(charactersIn: " =")
		let quoteCharacterSet = CharacterSet(charactersIn: "\"'")
		let whitespaceSet = CharacterSet.whitespaces
		
		while !scanner.isAtEnd {
			// eat any whitespace at the start
			Helper.scanCharacters(using: scanner, from: whitespaceSet)
			if scanner.isAtEnd {
				// e.g., a tag like <dog ></dog> might produce just a space attribute
				break
			}
			
			// Scan up to '=' or ' '
			let attributeName = Helper.scanUpToCharacters(using: scanner, from: nameBreakSet)
			
			let breakString = Helper.scanCharacters(using: scanner, from: nameBreakSet)
			
			if !(scanner.isAtEnd || breakString?.range(of: "=") == nil) {
				// We had an equal! Yay! We can use the value.
				let quote = Helper.scanCharacters(using: scanner, from: quoteCharacterSet)
				let ateQuote = quote?.isEmpty == false
				
				let attributeValue: String?
				if ateQuote {
					// For empty values (e.g. ''), we need to see if we scanned more than one quote.
					var count = 0
					if let quote = quote as NSString? {
						for idx in 0 ..< quote.length {
							if let char = UnicodeScalar(quote.character(at: idx)),
								quoteCharacterSet.contains(char) {
								count += 1
							}
						}
					}
					
					if count > 1 {
						attributeValue = ""
					} else {
						attributeValue = Helper.scanUpToCharacters(using: scanner, from: quoteCharacterSet)
						Helper.scanCharacters(using: scanner, from: quoteCharacterSet)
					}
				} else {
					attributeValue = Helper.scanUpToCharacters(using: scanner, from: whitespaceSet)
					Helper.scanCharacters(using: scanner, from: whitespaceSet)
				}
				if let attributeName = attributeName as String?,
					let attributeValue = attributeValue as String? {
					tagAttributes[attributeName] = attributeValue
				}
			}
		}
		
		if !tagAttributes.isEmpty {
			self.tagAttributes.merge(tagAttributes, uniquingKeysWith: { $1 })
		}
		
		#if DEBUG
		if !rawTagAttributes.isEmpty {
			rawAttributes += rawTagAttributes
		}
		#endif
	}
}
