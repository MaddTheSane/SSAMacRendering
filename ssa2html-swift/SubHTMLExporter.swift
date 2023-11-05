//
//  SubHTMLExporter.swift
//  ssa2html-swift
//
//  Created by C.W. Betts on 10/25/23.
//  Copyright © 2023 C.W. Betts. All rights reserved.
//

import Foundation
import SSAMacRendering

struct StderrOutputStream: TextOutputStream {
	public mutating func write(_ string: String) {
		fputs(string, stderr)
	}
}
var errStream = StderrOutputStream()

internal final class SubHTMLExporter: NSObject, SubRenderer {
	var context: SubContext! {
		return sc
	}
	
	let aspectRatio: CGFloat = 4/3
	
	func render(packet: String, in c: CGContext, size: CGSize) {
		//do nothing. Shouldn't even be called...
	}
	
	var sc: SubContext? = nil
	var html: String
	
	override init() {
		html =
"""
<html>
<head>
<meta http-equiv="Content-type" content="text/html; charset=UTF-8" />
<meta name="generator" content="ssa2html" />

"""
	}
	
	func didCompleteHeaderParsing(_ sc_: SubContext) {
		sc = sc_
		html +=
"""
<title>\(sc!.headers["Title"] ?? "")</title>
<style type="text/css">
.screen {width: \(sc!.resX)px; height: \(sc!.resY)px; background-color: gray; position: relative; display: table}\n.bottom {bottom: 20px; position: absolute} .top {top: 20px; position: absolute}

"""
	}
	
	func didCompleteStyleParsing(_ s: SubStyle) {
		func colorToString(_ theCol: SubRGBAColor) -> String {
			let aRed = theCol.red * 255
			let aGreen = theCol.green * 255
			let aBlue = theCol.blue * 255
			return String(format: "#%02X%02X%02X", Int(aRed), Int(aGreen), Int(aBlue))
		}
		html +=
		"""
.\(escapeCSSIdentifier(s.name)) {display: table-cell; clear: none;
font-family: "\(s.fontname)"; font-size: \(s.size * (72.0/96.0))pt;
color: \(colorToString(s.primaryColor));
-webkit-text-stroke-color: \(colorToString(s.outlineColor));
-webkit-text-stroke-width: \(s.outlineRadius)px;
letter-spacing: \(s.tracking)px;
text-shadow: \(colorToString(s.shadowColor)) \(s.shadowDist*2)px \(s.shadowDist*2)px 0;
text-outline: \(colorToString(s.shadowColor)) \(s.outlineRadius)px 0;
width: \(sc!.resX - CGFloat(s.marginL) - CGFloat(s.marginR))px;
font-weight: \(fontWeightString(forWeight: s.weight)); font-style: \(s.italic ? "italic" : "normal"); text-decoration: \(s.underline ? "underline" : (s.strikeout ? "line-through" : "none"));
text-align: \(s.alignH.stringValue);
vertical-align: \(s.alignV.stringValue);
}

"""
	}
	
	func endOfHead() {
		html +=
		"""
</style>
</head>
<body>

"""
	}
	
	func didCreateStartingSpan(_ span: SubRenderSpan, for div: SubRenderDiv) {
		span.extra = SubHTMLSpanExtra()
	}
	
	func spanChanged(tag: SubSSATagName, span: SubRenderSpan, div: SubRenderDiv, param p: UnsafeMutableRawPointer) {
		let spanEx = span.extra as! SubHTMLSpanExtra
		var sval: String = ""
		var fval: Float = 0
		var ival: Int32 = 0

		func iv() {
			ival = p.assumingMemoryBound(to: Int32.self).pointee
		}

		func fv() {
			fval = p.assumingMemoryBound(to: Float.self).pointee
		}

		func sv() {
			let aP = p.assumingMemoryBound(to: Unmanaged<NSString>.self)
			let unm2 = aP.pointee
			let unm3 = unm2.takeUnretainedValue()
			sval = unm3 as String
		}
		
		func cv() {
			ival = p.assumingMemoryBound(to: Int32.self).pointee
			ival = ival.littleEndian & 0xFFFFFF
		}

		switch tag {
		case .tag_b:
			iv()
			spanEx.str.append("font-weight: \(ival != 0 ? "bold" : "normal"); ")

		case .tag_i:
			iv()
			spanEx.str.append("font-style: \(ival != 0 ? "italic" : "normal"); ")

		case .tag_u:
			iv()
			spanEx.str.append("text-decoration: \(ival != 0 ? "underline" : "none"); ")

		case .tag_s:
			iv()
			spanEx.str.append("text-decoration: \(ival != 0 ? "line-through" : "none"); ")

		case .tag_fn:
			sv()
			spanEx.str.append("font-family: \(sval); ")

		case .tag_fs:
			fv()
			//this is wrong, see GetWinFontSizeScale()
			spanEx.str.append("font-size: \(fval * (72.0/96.0)); ")

		case .tag_1c:
			cv()
			spanEx.str += String(format: "color: #%0.6X; ", ival)

		case .tag_4c:
			cv()
			spanEx.str += String(format: "text-shadow: #%0.6X ", ival)
			spanEx.str.append("\(div.styleLine!.shadowDist * 2)px \(div.styleLine!.shadowDist * 2)px 0; ")

		default:
			print("unimplemented tag type \(tag.description) (\(tag.rawValue))", to: &errStream)
			break
		}
	}
	
	func htmlify(_ divs: [SubRenderDiv]) {
		for div in divs {
			if div.scale > 0 {
				continue
			}
			let spanCount = div.spans?.count ?? 0
			var spans = 1
			var close_div = false
			
			if div.isPositioned {
				html.append("<div style=\"top: \(div.posY)px; left: \(div.posX)px; position: absolute\">")
				close_div = true
			}
			
			html.append(#"<span class="\#(escapeCSSIdentifier(div.styleLine!.name))">"#)
			
			for j in 0 ..< spanCount {
				let span = div.spans![j]
				let ex = span.extra as! SubHTMLSpanExtra
				let str = ex.str
				if !str.isEmpty {
					html.append("<span style=\"\(str)\">")
					spans += 1
				}
				
				if let divTxt = div.text {
					let rang1 = NSMakeRange(Int(span.offset), (j == (spanCount-1)) ? divTxt.utf16.count : Int(((div.spans![j+1]).offset) - span.offset))
					if let strRange = Range(rang1, in: divTxt) {
						html.append(htmlfilter(divTxt[strRange]))
					}
				}
			}
			
			while spans != 0 {
				html.append("</span>")
				spans -= 1
			}
			if close_div {
				html.append("</div>")
			}
			html.append("\n")
		}
	}
	
	func add(_ sl: SubLine) {
		let divs = SubParsePacket(sl.line, sc!, self)
		var top = [SubRenderDiv]()
		var bottom = [SubRenderDiv]()
		var absolute = [SubRenderDiv]()
		
		html.append(#"<div class="screen">\#n"#)
		
		for div in divs {
			if div.isPositioned {
				absolute.append(div)
			} else if div.alignV == .top {
				top.append(div)
			} else {
				bottom.insert(div, at: 0)
			}
		}
		
		if !top.isEmpty {
			html.append("<div class=\"top\">\n")
			htmlify(top)
			html.append("</div>\n")
		}
		
		if !bottom.isEmpty {
			html.append("<div class=\"bottom\">\n")
			htmlify(bottom)
			html.append("</div>\n")
		}
		
		htmlify(absolute)
		
		html.append("</div>\n")

		html.append("<br>\n")
	}
	
	func endOfFile() {
		html.append("</body></html>\n")
	}
}

private extension SubAlignmentH {
	var stringValue: String {
		switch self {
		case .left:
			return "left"
		case .center:
			return "center"
		case .right:
			return "right"
		@unknown default:
			fatalError()
		}
	}
}

private extension SubAlignmentV {
	var stringValue: String {
		switch self {
		case .bottom:
			return "bottom"
		case .middle:
			return "middle"
		case .top:
			return "top"
		@unknown default:
			fatalError()
		}
	}
}

// font-weight actually seems to be enumerated 100|200|...|900
// but, like, whatever
private func fontWeightString(forWeight weight: Float32) -> String {
	if weight == 0 {
		return "normal"
	} else if weight == 1 {
		return "bold"
	} else {
		return "\(Int(weight))"
	}
}

private func escapeCSSIdentifier(_ s: String) -> String {
	if s.range(of: " ") == nil {
		return s
	}
	return s.replacingOccurrences(of: " ", with: "_")
}

private final class SubHTMLSpanExtra: NSObject, NSCopying {
	func copy(with zone: NSZone? = nil) -> Any {
		return SubHTMLSpanExtra()
	}
	
	var str = ""
}

private func htmlfilter<A: StringProtocol>(_ s: A) -> String {
	var ms = String(s)
	ms.replace("\n", with: "<br>\n")
	return ms
}
