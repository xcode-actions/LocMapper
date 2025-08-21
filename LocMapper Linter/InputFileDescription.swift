/*
 * InputFileDescription.swift
 * LocMapper Linter
 *
 * Created by François Lamboley on 2018-12-13.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



final class InputFileDescription : NSObject, NSSecureCoding, Sendable {
	
	static let supportsSecureCoding: Bool = true
	
	/* Raw value is tag in menu. */
	enum RefLocType : Int {
		
		case xibRefLoc = 1
		case stdRefLoc = 2
		
	}
	
	let nickname: String?
	
	let url: URL
	let urlBookmarkData: Data
	
	let refLocType: RefLocType
	
	convenience init(url: URL) throws {
		self.init(url: url, urlBookmarkData: try url.bookmarkData(), nickname: nil, refLocType: .xibRefLoc)
	}
	
	private init(url: URL, urlBookmarkData: Data, nickname: String?, refLocType: RefLocType) {
		self.url = url
		self.urlBookmarkData = urlBookmarkData
		
		self.nickname = nickname
		self.refLocType = refLocType
		
		super.init()
	}
	
	func withNickname(_ newNickname: String?) -> Self {
		.init(url: url, urlBookmarkData: urlBookmarkData, nickname: newNickname, refLocType: refLocType)
	}
	
	func withRefLocType(_ newRefLocType: RefLocType) -> Self {
		.init(url: url, urlBookmarkData: urlBookmarkData, nickname: nickname, refLocType: newRefLocType)
	}
	
	required init?(coder aDecoder: NSCoder) {
		nickname = aDecoder.decodeObject(forKey: "nickname") as? String
		refLocType = RefLocType(rawValue: aDecoder.decodeInteger(forKey: "refLocType")) ?? .xibRefLoc
		
		guard let bData = aDecoder.decodeObject(forKey: "urlBookmark") as? Data else {
			return nil
		}
		urlBookmarkData = bData
		
		var stale = false
		guard let u = try? URL(resolvingBookmarkData: urlBookmarkData, bookmarkDataIsStale: &stale) else {
			return nil
		}
		url = u
		
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(nickname, forKey: "nickname")
		aCoder.encode(urlBookmarkData, forKey: "urlBookmark")
		aCoder.encode(refLocType.rawValue, forKey: "refLocType")
	}
	
	var stringHash: String {
		return url.path + ":" + String(refLocType.rawValue)
	}
	
	static func ==(lhs: InputFileDescription, rhs: InputFileDescription) -> Bool {
		return (
			lhs.url        == rhs.url &&
			lhs.refLocType == rhs.refLocType
		)
	}
	
}
