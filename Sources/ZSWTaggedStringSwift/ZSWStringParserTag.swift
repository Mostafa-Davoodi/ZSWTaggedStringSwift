import Foundation

open class ZSWStringParserTag: NSObject {
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
		super.init()
	}
	
	open override var description: String {
		#if DEBUG
		return String(format: "<%@: %p; tag: %@, isEndingTag: %@, rawAttributes: %@, parsedAttributes: %@>", NSStringFromClass(Self.self), self, tagName, isEndingTag ? "YES" : "NO", rawAttributes, tagAttributes)
		#else
		return String(format: "<%@: %p; tag: %@, isEndingTag: %@, rawAttributes: %@, parsedAttributes: %@>", NSStringFromClass(Self.self), self, tagName, isEndingTag ? "YES" : "NO", tagAttributes)
		#endif
	}
	
	open var isEndingTag: Bool {
		return tagName.hasPrefix("/")
	}
	
	open func isEnded(by tag: ZSWStringParserTag) -> Bool {
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
	
	open func update(with tag: ZSWStringParserTag) {
		guard isEnded(by: tag) else {
			preconditionFailure("Didn't check before updating tag")
		}
		endLocation = tag.location
	}
	
	open var tagRange: NSRange {
		if endLocation < location {
			return NSMakeRange(location, 0)
		} else {
			return NSMakeRange(location, endLocation - location)
		}
	}
	
	open func addRawTagAttributes(_ rawTagAttributes: String) {
		let scanner = Scanner(string: rawTagAttributes)
		scanner.charactersToBeSkipped = nil
		
		var tagAttributes: [String: String] = [:]
		
		let nameBreakSet = CharacterSet(charactersIn: " =")
		let quoteCharacterSet = CharacterSet(charactersIn: "\"'")
		let whitespaceSet = CharacterSet.whitespaces
		
		while !scanner.isAtEnd {
			// eat any whitespace at the start
			scanner.scanCharacters(from: whitespaceSet, into: nil)
			if scanner.isAtEnd {
				// e.g., a tag like <dog ></dog> might produce just a space attribute
				break
			}
			
			// Scan up to '=' or ' '
			var attributeName: NSString?
			scanner.scanUpToCharacters(from: nameBreakSet, into: &attributeName)
			
			var breakString: NSString?
			scanner.scanCharacters(from: nameBreakSet, into: &breakString)
			
			if !(scanner.isAtEnd || breakString?.range(of: "=") == nil) {
				// We had an equal! Yay! We can use the value.
				var quote: NSString?
				let ateQuote = scanner.scanCharacters(from: quoteCharacterSet, into: &quote)
				
				var attributeValue: NSString?
				if ateQuote {
					// For empty values (e.g. ''), we need to see if we scanned more than one quote.
					var count = 0
					if let quote = quote {
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
						scanner.scanUpToCharacters(from: quoteCharacterSet, into: &attributeValue)
						scanner.scanCharacters(from: quoteCharacterSet, into: nil)
					}
				} else {
					scanner.scanUpToCharacters(from: whitespaceSet, into: &attributeValue)
					scanner.scanCharacters(from: whitespaceSet, into: nil)
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
