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
	public init(rgb: UInt32) {
		self = SubParseSSAColor(rgb)
	}
	
	public init(string: String) {
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

@available(*, renamed: "parseASSAlignment(_:)", unavailable)
public func SubParseASSAlignment(_ a: UInt8) -> (h: SubAlignmentH, v: SubAlignmentV) {
	fatalError()
}

@available(*, unavailable, renamed: "parseFontVerticality(_:)")
public func SubParseFontVerticality(_ fontname: inout String) -> Bool {
	fatalError()
}

@available(*, renamed: "parseSSAFile(_:)", unavailable)
public func SubParseSSAFile(_ ssa: String) -> (headers: [String: String], styles: [[String: String]], subs: [[String: String]])? {
	fatalError()
}
