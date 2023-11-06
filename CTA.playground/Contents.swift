//: Playground - noun: a place where people can play

import Cocoa
import CoreTextAdditions

var str = "Hello, playground"

print("hi")
/*
public extension NSBezierPath {
	
	public convenience init(path: CGPath) {
		self.init()
		
		let pathPtr = UnsafeMutablePointer<NSBezierPath>.allocate(capacity: 1)
		pathPtr.initialize(to: self)
		
		let infoPtr = UnsafeMutableRawPointer(pathPtr)
		
		// I hope the CGPathApply call manages the deallocation of the pointers passed to the applier
		// function, but I'm not sure.
		path.apply(info: infoPtr) { (infoPtr, elementPtr) -> Void in
			let path = infoPtr!.assumingMemoryBound(to: NSBezierPath.self).pointee
			let element = elementPtr.pointee
			
			let pointsPtr = element.points

			switch element.type {
			case .moveToPoint:
				path.move(to: pointsPtr.pointee)
				
			case .addLineToPoint:
				path.line(to: pointsPtr.pointee)
				
			case .addQuadCurveToPoint:
				let firstPoint = pointsPtr.pointee
				let secondPoint = pointsPtr.successor().pointee
				
				let currentPoint = path.currentPoint
				let x = (currentPoint.x + 2 * firstPoint.x) / 3
				let y = (currentPoint.y + 2 * firstPoint.y) / 3
				let interpolatedPoint = CGPoint(x: x, y: y)
				
				let endPoint = secondPoint
				
				path.curve(to: endPoint, controlPoint1: interpolatedPoint, controlPoint2: interpolatedPoint)
				
			case .addCurveToPoint:
				//let firstPoint = pointsPtr.pointee
				//let secondPoint = pointsPtr.successor().pointee
				//let thirdPoint = pointsPtr.successor().successor().pointee
				let firstPoint = pointsPtr.pointee
				let secondPoint = pointsPtr.successor().pointee
				let thirdPoint = pointsPtr.advanced(by: 2).pointee

				path.curve(to: thirdPoint, controlPoint1: firstPoint, controlPoint2: secondPoint)
				
			case .closeSubpath:
				path.close()
			}
			
			pointsPtr.deinitialize()
		}
	}
}
*/

let hi = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: "/Users/cwbetts/Library/Fonts/PSDeluxe.suit") as NSURL) as? [CTFontDescriptor]
print(hi!)
if let fds = FontManager.fontDescriptors(from: URL(fileURLWithPath: "/Library/Fonts/PSDeluxe.suit")) {
	fds.count
	for fd in fds {
		//let fdDesc = CFCopyDescription(fd)
		//let sFDD = fdDesc as String?
		//let fddNN = sFDD ?? "<nil>"
		//print(fddNN)
		print(fd.attributes)
	}
	//print(fds)
}

/*
let aFont = Font(name: "Daily", size: 0)
aFont.debugDescription
aFont.description
aFont.familyName
aFont.name(ofKey: .subFamily)
aFont.name(ofKey: .unique)
aFont.name(ofKey: .version)
aFont.fullName
aFont.postScriptName
aFont.displayName
aFont.traits
aFont.characterSet
aFont.supportedLanguages
aFont.name(ofKey: .copyright)
aFont.name(ofKey: .style)
aFont.name(ofKey: .fontDescription)
aFont.name(ofKey: .sampleText)
aFont.name(ofKey: .postScriptCID)
aFont.stringEncoding
aFont.ascent
aFont.descent
aFont.unitsPerEm
aFont.countOfGlyphs
aFont.boundingBox
//let gf = aFont.graphicsFont()
//CFCopyDescription(gf.font) as String
//CFGetTypeID(gf.font)
*/

func addFont(from data: Data) throws -> CGFont {
	let dat2 = data as NSData
	guard let datPrivid = CGDataProvider(data: dat2),
		let aFont = CGFont(datPrivid) as CGFont? else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError)
	}
	try FontManager.registerGraphicsFont(aFont)
	return aFont
}

let preAddFonts = FontManager.availableFontFamilyNames

do {
	let aURL = URL(fileURLWithPath: /*"/Users/cwbetts/makestuff/BladesOfExile/rsrc/fonts/bold.ttf"*/"/Users/cwbetts/makestuff/BladesOfExile/rsrc/fonts/dungeon.ttf")
	let dat = try Data(contentsOf: aURL, options: .mappedIfSafe)
	try addFont(from: dat)
	//if let datProv = CGDataProvider(url: aURL as NSURL),
	//	let aFont = CGFont(datProv) as CGFont? {
	//	try FontManager.registerGraphicsFont(aFont)
	//}
} catch {
	print(error)
}


let postAddFonts = FontManager.availableFontFamilyNames

postAddFonts.count - preAddFonts.count

let Capriola = Font(name: "DungeonBold", size: 0)
Capriola.debugDescription
Capriola.description
Capriola.familyName
Capriola.name(ofKey: .subFamily)
Capriola.name(ofKey: .unique)
Capriola.name(ofKey: .version)
Capriola.fullName
Capriola.postScriptName
Capriola.displayName
Capriola.traits
let fontCharSet = Capriola.characterSet
Capriola.supportedLanguages
Capriola.name(ofKey: .copyright)
Capriola.name(ofKey: .style)
Capriola.name(ofKey: .fontDescription)
Capriola.name(ofKey: .sampleText)
Capriola.name(ofKey: .postScriptCID)
Capriola.stringEncoding
Capriola.ascent
Capriola.descent
Capriola.unitsPerEm
Capriola.countOfGlyphs
Capriola.boundingBox

let aChar = CharacterSet(charactersIn: Unicode.Scalar(32)!..<Unicode.Scalar(127)!)
fontCharSet.isStrictSuperset(of: aChar)
/*
let scaleVal = CGAffineTransform(scaleX: 4, y: 4)
//let (glyphs, _) = aFont.glyphs(for: Array("B".utf16))
//if let aPath = aFont.path(for: glyphs[0], matrix: scaleVal) {
//	let bPath = NSBezierPath(path: aPath)
//	bPath.elementCount
//}
*/

