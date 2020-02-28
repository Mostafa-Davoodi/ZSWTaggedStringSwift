import Foundation

struct Helper {
	@discardableResult
	static func scanUpToCharacters(using scanner: Scanner, from set: CharacterSet) -> String? {
		if #available(iOS 13, *) {
			return scanner.scanUpToCharacters(from: set)
		} else {
			var string: NSString?
			scanner.scanUpToCharacters(from: set, into: &string)
			return string as String?
		}
	}
	
	@discardableResult
	static func scanCharacters(using scanner: Scanner, from set: CharacterSet) -> String? {
		if #available(iOS 13, *) {
			return scanner.scanCharacters(from: set)
		} else {
			var string: NSString?
			scanner.scanCharacters(from: set, into: &string)
			return string as String?
		}
	}
	
	static func append(string: String?, into attributedString: NSMutableAttributedString) {
		guard let string = string, !string.isEmpty else { return }
		
		attributedString.append(NSAttributedString(string: string))
	}
}
