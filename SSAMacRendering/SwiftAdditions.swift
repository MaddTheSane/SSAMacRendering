//
//  SwiftAdditions.swift
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation

public func parseFontVerticality(_ fontname: inout String) -> Bool {
	var nsFontName = fontname as NSString
	let toRet = __SubParseFontVerticality(&nsFontName)
	fontname = nsFontName as String
	return toRet
}

public func parseASSAlignment(_ a: UInt8) -> (h: SubAlignmentH, v: SubAlignmentV) {
	var h = SubAlignmentH.center
	var v = SubAlignmentV.middle
	__SubParseASSAlignment(a, &h, &v)
	return (h, v)
}

public func parseSSAAlignment(_ b: UInt8) -> (h: SubAlignmentH, v: SubAlignmentV) {
	let a = SubASSFromSSAAlignment(b)
	return parseASSAlignment(a)
}

extension SubRGBAColor {
	@inlinable public init(rgb: UInt32) {
		self = SubParseSSAColor(rgb)
	}
	
	@inlinable public init(string: String) {
		self = SubParseSSAColorString(string)
	}
	
	public var cgColor: CGColor {
		let cols = [CGFloat(self.red), CGFloat(self.green), CGFloat(self.blue), CGFloat(self.alpha)]
		return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: cols)!
	}
}

public func parseSSAFile(_ ssa: String) -> (headers: [String: String], styles: [[String: String]], subs: [[String: String]])? {
	var tmpHead = NSDictionary()
	var tmpStyles = NSArray()
	var tmpSubs = NSArray()
	
	__SubParseSSAFile(ssa, &tmpHead, &tmpStyles, &tmpSubs)
	
	guard let head = tmpHead as? [String: String], let styles = tmpStyles as? [[String: String]], let subs = tmpSubs as? [[String: String]] else {
		return nil
	}
	return (head, styles, subs)
}

extension SubSSATagName: CustomStringConvertible {
	public var description: String {
		switch self {
		case .tag_b:
			return "tag_b"
		case .tag_i:
			return "tag_i"
		case .tag_u:
			return "tag_u"
		case .tag_s:
			return "tag_s"
		case .tag_bord:
			return "tag_bord"
		case .tag_shad:
			return "tag_shad"
		case .tag_be:
			return "tag_be"
		case .tag_fn:
			return "tag_fn"
		case .tag_fs:
			return "tag_fs"
		case .tag_fscx:
			return "tag_fscx"
		case .tag_fscy:
			return "tag_fscy"
		case .tag_fsp:
			return "tag_fsp"
		case .tag_frx:
			return "tag_frx"
		case .tag_fry:
			return "tag_fry"
		case .tag_frz:
			return "tag_frz"
		case .tag_1c:
			return "tag_1c"
		case .tag_2c:
			return "tag_2c"
		case .tag_3c:
			return "tag_3c"
		case .tag_4c:
			return "tag_4c"
		case .tag_alpha:
			return "tag_alpha"
		case .tag_1a:
			return "tag_1a"
		case .tag_2a:
			return "tag_2a"
		case .tag_3a:
			return "tag_3a"
		case .tag_4a:
			return "tag_4a"
		case .tag_r:
			return "tag_r"
		case .tag_p:
			return "tag_p"
		case .tag_t:
			return "tag_t"
		case .tag_pbo:
			return "tag_pbo"
		case .tag_fad:
			return "tag_fad"
		case .tag_fade:
			return "tag_fade"
		}
	}
}

extension SubAlignmentH: CustomStringConvertible {
	public var description: String {
		switch self {
		case .left:
			return "left"
		case .center:
			return "center"
		case .right:
			return "right"
		@unknown default:
			return "Unknown SubAlignmentH value: \(self.rawValue)"
		}
	}
}

extension SubAlignmentV: CustomStringConvertible {
	public var description: String {
		switch self {
		case .bottom:
			return "bottom"
		case .middle:
			return "middle"
		case .top:
			return "top"
		@unknown default:
			return "Unknown SubAlignmentV value: \(self.rawValue)"
		}
	}
}
