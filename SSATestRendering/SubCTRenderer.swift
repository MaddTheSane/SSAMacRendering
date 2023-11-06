//
//  SubCTRenderer.swift
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Cocoa
import CoreGraphics
import SSAMacRendering
import CoreText
#if APPCOMPILE
import CoreTextAdditions
#endif

/// call `ATSUDrawText` more than once, needed for color/border changes in the middle of lines
private let renderMultipleParts: UInt8 = 1
/// CG shadows can't change inside a line... probably
private let renderManualShadows: UInt8 = 2
/// can't draw text at all, have to transform each vertex. needed for 3D perspective, or \frz in the middle of a line
private let renderComplexTransforms: UInt8 = 4

// see comment for GetTypographicRectangleForLayout
private func getLineHeight(_ line: CTLine, includeDescent: Bool) -> CGFloat {
	let (_, ascent, descent, _) = line.typographicBounds
	var toRet = ascent
	if includeDescent {
		toRet += descent
	}
	return toRet
}

/*

static void ExpandCGRect(CGRect *rect, CGFloat radius)
{
rect->origin.x -= radius;
rect->origin.y -= radius;
rect->size.height += radius*2.;
rect->size.width += radius*2.;
}*/



/*
// some broken fonts have very wrong typographic values set, and so this occasionally gives nonsense
// it should be checked against the real pixel box (see #if 0 below), but for correct fonts it looks much better
static void GetTypographicRectangleForLayout(ATSUTextLayout layout, UniCharArrayOffset *breaks, ItemCount breakCount, Fixed extraHeight, Fixed *lX, Fixed *lY, Fixed *height, Fixed *width)
{
ATSTrapezoid trap = {0};
ItemCount trapCount;
FixedRect largeRect = {0};
Fixed baseY = 0;
NSInteger i;

for (i = breakCount; i >= 0; i--) {
UniCharArrayOffset end = breaks[i+1];
FixedRect rect;

ATSUGetGlyphBounds(layout, 0, baseY, breaks[i], end-breaks[i], kATSUseDeviceOrigins, 1, &trap, &trapCount);

baseY += GetLineHeight(layout, breaks[i], YES) + extraHeight;

rect.bottom = MAX(trap.lowerLeft.y, trap.lowerRight.y);
rect.left = MIN(trap.lowerLeft.x, trap.upperLeft.x);
rect.top = MIN(trap.upperLeft.y, trap.upperRight.y);
rect.right = MAX(trap.lowerRight.x, trap.upperRight.x);

if (i == breakCount) largeRect = rect;

largeRect.bottom = MAX(largeRect.bottom, rect.bottom);
largeRect.left = MIN(largeRect.left, rect.left);
largeRect.top = MIN(largeRect.top, rect.top);
largeRect.right = MAX(largeRect.right, rect.right);
}

if (lX) *lX = largeRect.left;
if (lY) *lY = largeRect.bottom;
*height = largeRect.bottom - largeRect.top;
*width = largeRect.right - largeRect.left;
}*/

protocol DeepCopying: NSObjectProtocol {
	func deepCopy() -> Any
}

extension NSDictionary: DeepCopying {
	func deepCopy() -> Any {
		var clone = [AnyHashable: Any]()
		for (key, object) in self as! [AnyHashable: Any] {
			let copyOfObject: Any
			if let object = object as? DeepCopying {
				copyOfObject = object.deepCopy()
			} else if let object = object as? (NSCopying & NSObject) {
				copyOfObject = object.copy()
			} else {
				copyOfObject = object
			}
			clone[key] = copyOfObject
		}
		return clone
	}
}

extension NSArray: DeepCopying {
	func deepCopy() -> Any {
		return self.map { (object) -> Any in
			let copyOfObject: Any
			if let object = object as? DeepCopying {
				copyOfObject = object.deepCopy()
			} else if let object = object as? (NSCopying & NSObject) {
				copyOfObject = object.copy()
			} else {
				copyOfObject = object
			}
			return copyOfObject
		}
	}
}

extension CGColor {
	fileprivate class func createFromRGBA(_ rgba: SubRGBAColor, colorspace cspace: CGColorSpace) -> CGColor? {
		var components = [CGFloat(rgba.red), CGFloat(rgba.green), CGFloat(rgba.blue), CGFloat(rgba.alpha)]
		
		return CGColor(colorSpace: cspace, components: &components)
	}
	
	fileprivate class func createFromRGBOpaque(_ rgba: SubRGBAColor, colorspace cspace: CGColorSpace) -> CGColor? {
		var c2 = rgba
		c2.alpha = 1
		
		return createFromRGBA(c2, colorspace: cspace)
	}
}

/*
private func FindAllPossibleLineBreaks(_ line: String) {
	let token = CFStringTokenizerCreate(kCFAllocatorDefault, line as NSString, CFRangeMake(0, 0), kCFStringTokenizerUnitLineBreak, nil)
	
	while CFStringTokenizerAdvanceToNextToken(token) != .none {
		let tokenRange = CFStringTokenizerGetCurrentTokenRange(token)
	}
}*/

/*
static void FindAllPossibleLineBreaks(TextBreakLocatorRef breakLocator, const unichar *uline, UniCharArrayOffset lineLen, uint8_t *breakOpportunities)
{
UniCharArrayOffset lastBreak = 0;

while (1) {
UniCharArrayOffset breakOffset = 0;
OSStatus status;

status = UCFindTextBreak(breakLocator, kUCTextBreakLineMask, kUCTextBreakLeadingEdgeMask | (lastBreak ? kUCTextBreakIterateMask : 0), uline, lineLen, lastBreak, &breakOffset);

if (status != noErr || breakOffset >= lineLen) break;

bitfield_set(breakOpportunities, breakOffset-1);
lastBreak = breakOffset;
}
}
*/

private func setupCGForSpan(_ c: CGContext, spanEx: SubCTRenderer.SpanExtra, lastSpanEx: SubCTRenderer.SpanExtra?, div: SubRenderDiv, textType: SubCTRenderer.TextLayer, endLayer endLayer1: Bool) -> Bool {
	var endLayer = endLayer1
	
	switch textType {
	case .shadow:
		if lastSpanEx?.shadowColor != spanEx.shadowColor {
			if endLayer {
				c.endTransparencyLayer()
			}
			c.setFillColor(spanEx.shadowColor!)
			c.setStrokeColor(spanEx.shadowColor!)
			if spanEx.shadowColor!.alpha != 1.0 {
				endLayer = true
				c.beginTransparencyLayer(auxiliaryInfo: nil)
			} else {
				endLayer = false
			}
		}
		
	case .outline:
		if lastSpanEx?.outlineRadius != spanEx.outlineRadius {
			c.setLineWidth(spanEx.outlineRadius != 0 ? spanEx.outlineRadius * 2.0 + 0.5 : 0)
		}
		if lastSpanEx?.outlineColor != spanEx.outlineColor {
			if div.styleLine!.borderStyle == .normal {
				c.setStrokeColor(spanEx.outlineColor!)
			} else {
				c.setFillColor(spanEx.outlineColor!)
			}
		}
		
		if lastSpanEx?.outlineAlpha != spanEx.outlineAlpha {
			if endLayer {
				c.endTransparencyLayer()
			}
			c.setAlpha(spanEx.outlineAlpha)
			if spanEx.outlineAlpha != 1.0 {
				endLayer = true
				c.beginTransparencyLayer(auxiliaryInfo: nil)
			} else {
				endLayer = false
			}
		}
		
	case .primary:
		if lastSpanEx?.primaryColor != spanEx.primaryColor {
			c.setFillColor(spanEx.primaryColor!)
		}
		
		if lastSpanEx?.primaryAlpha != spanEx.primaryAlpha {
			if spanEx.primaryAlpha != 1 {
				endLayer = true
				c.beginTransparencyLayer(auxiliaryInfo: nil)
			} else {
				endLayer = false
			}
		}
		
	case .primaryUnstyled:
		break
	}
	
	return endLayer
}


private func drawShapePart(_ c: CGContext, path: CGPath, div: SubRenderDiv, firstSpanEx: SubCTRenderer.SpanExtra, textType: SubCTRenderer.TextLayer) {
	let textModes: [CGPathDrawingMode] = [.fillStroke, .stroke, .fill, .fill]
	let lastSpanEx: SubCTRenderer.SpanExtra? = nil
	var endLayer = false
	let multipleParts = (div.renderComplexity & renderMultipleParts) == renderMultipleParts
	
	if !multipleParts {
		endLayer = setupCGForSpan(c, spanEx: firstSpanEx, lastSpanEx: lastSpanEx, div: div, textType: textType, endLayer: endLayer)
	}
	endLayer = setupCGForSpan(c, spanEx: firstSpanEx, lastSpanEx: lastSpanEx, div: div, textType: textType, endLayer: endLayer)

	c.addPath(path)
	c.drawPath(using: textModes[textType.rawValue])
	
	if endLayer {
		c.endTransparencyLayer()
	}
}

private func drawShape(_ c: CGContext, path: CGPath, div: SubRenderDiv, firstSpanEx: SubCTRenderer.SpanExtra) {
	let drawShadow: Bool
	let drawOutline: Bool
	let clearOutlineInnerStroke: Bool
	var endLayer = false
	
	if (div.renderComplexity & renderMultipleParts) == renderMultipleParts {
		drawShadow = true
		drawOutline = true
		clearOutlineInnerStroke = true
	} else {
		drawShadow = div.styleLine!.borderStyle == .normal && firstSpanEx.shadowDist != 0;
		drawOutline = div.styleLine!.borderStyle != .normal || firstSpanEx.outlineRadius != 0;
		clearOutlineInnerStroke = firstSpanEx.primaryAlpha < 1.0;
	}
	
	if drawShadow {
		if (div.renderComplexity & renderManualShadows) != renderManualShadows {
			endLayer = true
			c.setShadow(offset: CGSize(width: firstSpanEx.shadowDist + 0.5, height: -(firstSpanEx.shadowDist + 0.5)), blur: 0, color: firstSpanEx.shadowColor)
			c.beginTransparencyLayer(auxiliaryInfo: nil)
		} else {
			drawShapePart(c, path: path, div: div, firstSpanEx: firstSpanEx, textType: .shadow)
		}
	}
	
	if drawOutline {
		if clearOutlineInnerStroke {
			c.beginTransparencyLayer(auxiliaryInfo: nil)
		}
		drawShapePart(c, path: path, div: div, firstSpanEx: firstSpanEx, textType: .outline)
		if clearOutlineInnerStroke {
			c.setBlendMode(.clear)
			drawShapePart(c, path: path, div: div, firstSpanEx: firstSpanEx, textType: .primaryUnstyled)
			c.setBlendMode(.normal)
			c.endTransparencyLayer()
		}
	}
	
	drawShapePart(c, path: path, div: div, firstSpanEx: firstSpanEx, textType: .primary);

	if endLayer {
		c.endTransparencyLayer()
		c.setShadow(offset: .zero, blur: 0, color: nil)
	}
}

class SubCTRenderer: NSObject, SubRenderer {
	fileprivate enum TextLayer: Int {
		case shadow = 0
		case outline
		case primary
		case primaryUnstyled
	}

	/// Registers a font for CoreText from `data` and returns the CG font.
	///
	/// The returned `CGFont` object can be used by `CTFontManagerUnregisterGraphicsFont()` to deregister
	/// the font from CoreText.
	class func addFont(from data: Data) throws -> CGFont {
		guard let datPrivid = CGDataProvider(data: data as NSData),
			  let aFont = CGFont(datPrivid) else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError)
		}
		var maybeErr: Unmanaged<CFError>? = nil
		let success = CTFontManagerRegisterGraphicsFont(aFont, &maybeErr)
		guard success else {
			if let maybeErr = maybeErr?.takeRetainedValue() {
				throw maybeErr
			} else {
				throw NSError(domain: NSOSStatusErrorDomain, code: paramErr)
			}
		}
		return aFont
	}
	
	fileprivate final class Style: NSObject, NSCopying {
		
		private static func deepCopy(_ toCopy: [String: Any]) -> [String: Any] {
			var toCopy2 = toCopy
			for (key, val) in toCopy {
				if let val2 = val as? NSDictionary {
					toCopy2[key] = val2.deepCopy()
				} else if let val2 = val as? NSArray {
					toCopy2[key] = val2.deepCopy()
				}
			}
			return toCopy2
		}
		
		var style: [String: Any]
		
		init(dictionary: [String: Any]) {
			style = dictionary
		}
		
		func copy(with zone: NSZone? = nil) -> Any {
			return Style(dictionary: Style.deepCopy(style))
		}

	}
	
	fileprivate final class SpanExtra: NSObject, NSCopying {
		var style: Style?
		var primaryColor: CGColor?
		var outlineColor: CGColor?
		var shadowColor: CGColor?
		var outlineRadius: CGFloat = 0
		var shadowDist: CGFloat = 0
		var scaleX: CGFloat = 0
		var scaleY: CGFloat = 0
		var primaryAlpha: CGFloat = 0
		var outlineAlpha: CGFloat = 0
		var angle: CGFloat = 0
		var platformSizeScale: CGFloat = 0
		var fontSize: CGFloat = 0
		var blurEdges: Bool = false
		var vertical: Bool = false
		var fontName = ""
		var font: CTFont?
		var bold = false
		var italic = false
		var fontMatrix = CGAffineTransform.identity
		
		private override init() {
			super.init()
		}
		
		init(style sstyle: SubStyle, colorSpace cs: CGColorSpace) {
			if let extra = sstyle.extra as? Style {
				style = (extra.copy() as! Style)
			}
			primaryColor = CGColor.createFromRGBOpaque(sstyle.primaryColor, colorspace: cs)
			primaryAlpha = CGFloat(sstyle.primaryColor.alpha)
			outlineColor = CGColor.createFromRGBOpaque(sstyle.outlineColor, colorspace: cs)
			outlineAlpha = CGFloat(sstyle.outlineColor.alpha)
			shadowColor = CGColor.createFromRGBA(sstyle.shadowColor, colorspace: cs)
			outlineRadius = CGFloat(sstyle.outlineRadius)
			shadowDist = CGFloat(sstyle.shadowDist)
			scaleX = CGFloat(sstyle.scaleX) / 100
			scaleY = CGFloat(sstyle.scaleY) / 100
			angle = CGFloat(sstyle.angle)
			platformSizeScale = CGFloat(sstyle.platformSizeScale)
			fontSize = CGFloat(sstyle.size)
			vertical = sstyle.vertical
			font = CTFontCreateWithName(sstyle.fontname as NSString, fontSize, nil)
			super.init()
		}
		
		@objc func copy(with zone: NSZone? = nil) -> Any {
			let ret = SpanExtra()
			
			ret.style = style
			ret.primaryColor = primaryColor
			ret.primaryAlpha = primaryAlpha
			ret.outlineColor = outlineColor
			ret.outlineAlpha = outlineAlpha
			ret.shadowColor = shadowColor
			ret.outlineRadius = outlineRadius
			ret.shadowDist = shadowDist
			ret.scaleX = scaleX
			ret.scaleY = scaleY
			ret.angle = angle
			ret.platformSizeScale = platformSizeScale
			ret.fontSize = fontSize
			ret.font = font
			ret.blurEdges = blurEdges
			ret.vertical = vertical
			ret.bold = bold
			ret.italic = italic
			ret.fontMatrix = fontMatrix
			
			return ret
		}
		
		override var description: String {
			return "SpanEx with alpha \(primaryAlpha)/\(outlineAlpha)"
		}
	}
	
	let videoWidth: CGFloat
	let videoHeight: CGFloat
	var screenScaleX: CGFloat = 1
	var screenScaleY: CGFloat = 1
	private(set) var context: SubContext!
	var layout: CTTypesetter?
	
	private static func updateFontNameSize(_ spanEx: SpanExtra, screenScale: CGFloat) {
		let fSize = spanEx.fontSize * spanEx.platformSizeScale * screenScale;
		let style = spanEx.style
		var descriptor = CTFontDescriptorCreateWithNameAndSize(spanEx.fontName as NSString, fSize)
		var aDict = [String: Any]()
		var traitsDict = [String: Any]()
		var traits = CTFontSymbolicTraits()
		if spanEx.bold {
			traits.insert(.traitBold)
		}
		if spanEx.italic {
			traits.insert(.traitItalic)
		}
		traitsDict[kCTFontSymbolicTrait as String] = traits.rawValue
		aDict[kCTFontTraitsAttribute as String] = traitsDict
		//kCTFontTraitsAttribute
		descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, aDict as NSDictionary)
		let ourFont = CTFontCreateWithFontDescriptor(descriptor, fSize, nil)
		spanEx.font = ourFont
		style?.style[kCTFontAttributeName as String] = ourFont
	}
	
	init?(scriptType type: SubType, header: String?, videoWidth width: CGFloat, videoHeight height: CGFloat) {
		videoWidth = width
		videoHeight = height
		var headers = [String: String]()
		var styles = [[String: String]]()
		
		if var header2 = header {
			header2 = SubStandardizeStringNewlines(header2)
			if let parsed = parseSSAFile(header2) {
				headers = parsed.headers
				styles = parsed.styles
			} else {
				return nil
			}
		}
		
		super.init()
		context = SubContext(scriptType: type, headers: headers, styles: styles, delegate: self)
	}

	func render(packet: String, in c: CGContext, size: CGSize) {
		let divs = SubParsePacket(packet, context, self)
		var lastLayer: Int32 = 0
		
		c.saveGState()
		if size.width != videoWidth || size.height != videoHeight {
			c.scaleBy(x: size.width / videoWidth, y: size.height / videoHeight)
		}
		c.setLineCap(.round) // avoid spiky outlines on some fonts
		c.setLineJoin(.round)
		c.setShouldSmoothFonts(false) // don't do LCD subpixel antialiasing
		c.setShouldSubpixelQuantizeFonts(false) // draw text stroke and fill in the same place

		defer {
			c.restoreGState()
		}
		
		for div in divs {
			guard let text = div.text, text.count != 0, div.spans!.count != 0 else {
				continue
			}
			
			var resetPens = false
			
			if div.layer != lastLayer || div.shouldResetPens {
				resetPens = true
				lastLayer = div.layer
			}
			
			var marginRect = NSRect(x: CGFloat(div.leftMargin), y: CGFloat(div.verticalMargin), width: context.resX - CGFloat(div.leftMargin - div.rightMargin), height: context.resY - CGFloat(div.verticalMargin - div.verticalMargin))
			
			marginRect.origin.x *= screenScaleX;
			marginRect.origin.y *= screenScaleY;
			marginRect.size.width  *= screenScaleX;
			marginRect.size.height *= screenScaleY;

			var breakingWidth = marginRect.size.width
			var penY: CGFloat = 0
			var penX: CGFloat = 0
			
			/*
			BOOL resetPens = NO, resetGState = NO;
			NSData *ubufferData;
			const unichar *ubuffer = SubUnicodeForString(div->text, &ubufferData);

Fixed penY, penX, breakingWidth = FloatToFixed(marginRect.size.width);
BreakContext breakc = {0}; ItemCount breakCount;

ATSUSetTextPointerLocation(layout, ubuffer, kATSUFromTextBeginning, kATSUToTextEnd, textLen);
ATSUSetTransientFontMatching(layout,TRUE);

SetLayoutPositioning(layout, breakingWidth, div->alignH);
SetStyleSpanRuns(layout, div, ubuffer);

breakBuffer = FindLineBreaks(layout, div, breakLocator, breakBuffer, &breakCount, breakingWidth, ubuffer, textLen);

ATSUTextMeasurement imageWidth = 0, imageHeight = 0, descent = 0;
UniCharArrayOffset *breaks = breakBuffer;
*/
			if div.isPositioned || div.alignV == .middle {
				//GetTypographicRectangleForLayout(layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), NULL, NULL, &imageHeight, &imageWidth);
			}
			
			if div.isPositioned || div.alignV != .top {
				//ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);
			}
			
			/*
#if 0
{
ATSUTextMeasurement ascent, descent;

ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineAscentTag,  sizeof(ATSUTextMeasurement), &ascent,  NULL);
ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);

NSLog(@"\"%@\" descent %f ascent %f\n", div->text, FixedToFloat(descent), FixedToFloat(ascent));
}
#endif

if (!div->positioned) {
penX = FloatToFixed(NSMinX(marginRect));

switch(div->alignV) {
case kSubAlignmentBottom: default:
if (!bottomPen || resetPens) {
penY = FloatToFixed(NSMinY(marginRect)) + descent;
} else penY = bottomPen;

storePen = &bottomPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
break;
case kSubAlignmentMiddle:
if (!centerPen || resetPens) {
penY = FloatToFixed(NSMidY(marginRect)) - (imageHeight / 2) + descent;
} else penY = centerPen;

storePen = &centerPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
break;
case kSubAlignmentTop:
if (!topPen || resetPens) {
penY = FloatToFixed(NSMaxY(marginRect)) - GetLineHeight(layout, kATSUFromTextBeginning, NO);
} else penY = topPen;

storePen = &topPen; breakc.lStart = 0; breakc.lEnd = breakCount+1; breakc.direction = -1;
break;
}
} else {
penX = FloatToFixed(div->posX * screenScaleX);
penY = FloatToFixed((context->resY - div->posY) * screenScaleY);

switch (div->alignH) {
case kSubAlignmentCenter: penX -= imageWidth / 2; break;
case kSubAlignmentRight: penX -= imageWidth; break;
case kSubAlignmentLeft: break;
}

switch (div->alignV) {
case kSubAlignmentMiddle: penY -= imageHeight / 2; break;
case kSubAlignmentTop: penY -= imageHeight; break;
case kSubAlignmentBottom: break;
}

penY += descent;

SetLayoutPositioning(layout, imageWidth, div->alignH);
storePen = NULL; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
}

SubRenderSpan *firstSpan = [div->spans objectAtIndex:0];
SubATSUISpanExtra *firstSpanEx = firstSpan.extra;
if (div->scale > 0) {
CGContextSaveGState(c);
//CGContextflip
CGAffineTransform trans = CGAffineTransformMakeTranslation(div->posX, div->posY);
CGFloat angle = firstSpanEx->angle;
angle *= M_PI / 180.;
trans = CGAffineTransformRotate(trans, angle);
CGAffineTransform trans2 = CGAffineTransformMake(1, 0, 0, -1, 0, videoHeight * screenScaleY);
CGContextConcatCTM(c, trans2);
//CGContextScaleCTM(c, 1, videoHeight * screenScaleY);
//CGContextTranslateCTM(c, div->posX, div->posY);
CGPathRef pr = CreateSubParseSubShapesWithString(div->text, &trans);

drawShape(c, pr, div, firstSpanEx);

CGPathRelease(pr);
CGContextRestoreGState(c);
} else {

// FIXME: we can only rotate an entire line at once
if (firstSpanEx->angle) {
Fixed fangle = FloatToFixed(firstSpanEx->angle);
SetATSULayoutOther(layout, kATSULineRotationTag, sizeof(Fixed), &fangle);

// FIXME: awful hack for SSA vertical text idiom
// instead it needs to rotate text by hand or actually fix ATSUI's rotation origin
if (firstSpanEx->vertical &&
div->alignV == kSubAlignmentMiddle && div->alignH == kSubAlignmentCenter) {
CGContextSaveGState(c);
CGContextTranslateCTM(c, FixedToFloat(imageWidth)/2, FixedToFloat(imageWidth)/2);
resetGState = YES;
}
}

if (drawTextBounds)
VisualizeLayoutLineHeights(c, layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), penX, penY, cHeight);

breakc.breakCount = breakCount;
breakc.breaks = breaks;

penY = DrawOneTextDiv(c, layout, div, breakc, penX, penY);
			}
if (resetGState)
CGContextRestoreGState(c);

ubufferData = nil;
if (storePen) *storePen = penY;
*/
			//TODO: implement
		}
		
	}
	
	func didCompleteHeaderParsing(_ sc: SubContext) {
		screenScaleX = videoWidth / sc.resX
		screenScaleY = videoHeight / sc.resY
	}
	
	func didCompleteStyleParsing(_ s: SubStyle) {
		var size: CGFloat = 12
		var fontAttr = [String: Any]()
		var fontTraits = [String: Any]()
		var descriptor = CTFontDescriptorCreateWithNameAndSize(s.fontname as NSString, CGFloat(s.size))
		var font = CTFontCreateWithFontDescriptor(descriptor, CGFloat(s.size), nil)
		//kCTFontTraitsAttribute
		//CTFontDescriptorCreateWithAttributes(fontAttr as NSDictionary)
		
		if s.platformSizeScale == 0 {
			s.platformSizeScale = Float32(GetWinCTFontSizeScale(font))
		}
		
		size = CGFloat(s.size * s.platformSizeScale) * screenScaleY //FIXME: several other values also change relative to PlayRes but aren't handled
		fontAttr[kCTFontSizeAttribute as String] = size
		descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, fontAttr as NSDictionary)

		var mat: CGAffineTransform?
		if s.scaleX != 100 || s.scaleY != 100 {
			mat = CGAffineTransform(scaleX: CGFloat(s.scaleX) / 100, y: CGFloat(s.scaleY) / 100)
		}
		
		//kCTFontSymbolicTrait
		do {
			var traits = CTFontSymbolicTraits()
			if s.italic {
				traits.insert(.traitItalic)
			}
			if s.weight > 0 {
				traits.insert(.traitBold)
			}
			
			fontTraits[kCTFontSymbolicTrait as String] = traits.rawValue
			fontTraits[kCTFontWeightTrait as String] = s.weight
		}
		fontAttr[kCTFontTraitsAttribute as String] = fontTraits
		if var mat = mat {
			font = CTFontCreateWithFontDescriptor(descriptor, CGFloat(s.size), &mat)
		} else {
			font = CTFontCreateWithFontDescriptor(descriptor, CGFloat(s.size), nil)
		}
		
		var someExtras = [String: Any]()
		someExtras[NSAttributedStringKey.CoreText.font.rawValue] = font
		someExtras[NSAttributedStringKey.CoreText.fontTraits.rawValue] = fontTraits
		if s.underline {
			someExtras[NSAttributedStringKey.CoreText.underlineStyle.rawValue] = CTUnderlineStyle.single.rawValue
		}
		if s.strikeout {
			someExtras[NSAttributedStringKey.strikethroughStyle.rawValue] = NSUnderlineStyle.styleSingle.rawValue
		}
		
		/* TODO: implement?
if (s->tracking > 0) { // bug in VSFilter: negative tracking in style lines is ignored
Fixed tracking = FloatToFixed(s->tracking);

SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &tracking);
} */
		
		s.extra = Style(dictionary: someExtras)
	}

	func didCreateStartingSpan(_ span: SubRenderSpan, for div: SubRenderDiv) {
		span.extra = SpanExtra(style: div.styleLine!, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
	}
	
	func spanChanged(tag: SubSSATagName, span: SubRenderSpan, div: SubRenderDiv, param p: UnsafeMutableRawPointer) {
		let spanEx = span.extra as! SpanExtra
		let style = spanEx.style
		let isFirstSpan = div.spans?.count == 0
		var bval: Bool = false
		var sval: String = ""
		var fval: Float = 0
		var ival: Int32 = 0
		var color: CGColor?

		func bv() {
			bval = p.assumingMemoryBound(to: Int32.self).pointee != 0
		}
		
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

		func colorv() {
			let tmpVal = p.assumingMemoryBound(to: UInt32.self).pointee
			let hi = SubParseSSAColor(tmpVal)
			color = CGColor.createFromRGBA(hi, colorspace: CGColorSpace(name: CGColorSpace.sRGB)!)!
		}
		
		switch tag {
		case .tag_b:
			bv()
			spanEx.bold = bval
			//TODO: kCTFontWeightTrait?
			
		case .tag_i:
			bv()
			spanEx.italic = bval
			//TODO: kCTFontSlantTrait?

		case .tag_u:
			bv()
			style?.style[kCTUnderlineStyleAttributeName as String] = bval ? CTUnderlineStyle.single.rawValue : 0
			
		case .tag_s:
			bv()

		case .tag_bord:
			fv()
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts;
			}
			spanEx.outlineRadius = CGFloat(fval)

		case .tag_shad:
			fv()
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts | renderManualShadows
			}
			spanEx.shadowDist = CGFloat(fval)

		case .tag_fn:
			sv()
			if sval.count == 0 {
				sval = div.styleLine!.fontname
			}
			let oldFont = spanEx.font
			spanEx.fontName = sval
			spanEx.vertical = parseFontVerticality(&sval)
			spanEx.font = CTFontCreateWithName(sval as NSString, spanEx.fontSize, nil)
			if oldFont !== spanEx.font {
				spanEx.platformSizeScale = GetWinCTFontSizeScale(spanEx.font!)
			}
			SubCTRenderer.updateFontNameSize(spanEx, screenScale: screenScaleY)

		case .tag_fs:
			fv()
			spanEx.fontSize = CGFloat(fval)
			SubCTRenderer.updateFontNameSize(spanEx, screenScale: screenScaleY)

		case .tag_1c:
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts;
			}
			colorv();
			spanEx.primaryColor = color;

		case .tag_3c:
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts;
			}
			let rgba = SubParseSSAColor(p.assumingMemoryBound(to: UInt32.self).pointee)
			spanEx.outlineColor = CGColor.createFromRGBOpaque(rgba, colorspace: CGColorSpace(name: CGColorSpace.sRGB)!)
			spanEx.outlineAlpha = CGFloat(rgba.alpha)
			
		case .tag_4c:
			if (!isFirstSpan) {
				div.renderComplexity |= renderMultipleParts | renderManualShadows;
			}
			colorv();
			spanEx.shadowColor = color;

		case .tag_fscx:
			fv()
			spanEx.scaleX = CGFloat(fval) / 100.0
			let mat = CGAffineTransform(scaleX: spanEx.scaleX, y: spanEx.scaleY)
			spanEx.fontMatrix = mat
			//SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);

		case .tag_fscy:
			fv()
			spanEx.scaleY = CGFloat(fval) / 100.0
			let mat = CGAffineTransform(scaleX: spanEx.scaleX, y: spanEx.scaleY)
			//SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
			spanEx.fontMatrix = mat

		case .tag_fsp:
			fv();
			//style?.style
			//SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &fixval);

		case .tag_frz:
			fv();
			if !isFirstSpan {
				div.renderComplexity |= renderComplexTransforms // this one's hard
			}
			spanEx.angle = CGFloat(fval)

		case .tag_1a:
			iv();
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts
			}
			spanEx.primaryAlpha = CGFloat(255 - ival) / 255.0

		case .tag_3a:
			iv();
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts
			}
			spanEx.outlineAlpha = CGFloat(255 - ival) / 255.0

		case .tag_4a:
			iv();
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts | renderManualShadows
			}
			spanEx.shadowColor = spanEx.shadowColor?.copy(alpha: CGFloat(255 - ival) / 255.0)

		case .tag_alpha:
			iv();
			let fval = CGFloat(255 - ival) / 255.0
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts | renderManualShadows;
			}
			spanEx.primaryAlpha = fval
			spanEx.outlineAlpha = fval
			spanEx.shadowColor = spanEx.shadowColor?.copy(alpha: fval);
			
		case .tag_r:
			sv();
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts | renderManualShadows
			}
			let sstyle = context.styles[sval] ?? div.styleLine!
			span.extra = SpanExtra(style: sstyle, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)

		case .tag_be:
			bv()
			if !isFirstSpan {
				div.renderComplexity |= renderMultipleParts //FIXME: blur edges
			}
			
			spanEx.blurEdges = bval

		case .tag_p:
			fv()
			div.scale = CGFloat(fval)
			
		case .tag_frx:
			fv()
			print("Unimplemented SSA tag 'frx'")
		case .tag_fry:
			fv()
			print("Unimplemented SSA tag 'fry'")
		case .tag_2c:
			colorv()
			print("Unimplemented SSA tag '2c'")
		case .tag_2a:
			colorv()
			print("Unimplemented SSA tag '2a'")
		//case .tag_t:
		//	print("Unimplemented SSA tag 't'")
		case .tag_pbo:
			fv()
			print("Unimplemented SSA tag 'pbo'")
		//case .tag_fad:
		//	print("Unimplemented SSA tag 'fad'")
		default:
			print(String(format:"Unimplemented SSA tag #%d", tag.rawValue))
		}
	}
	
	var aspectRatio: CGFloat {
		return videoWidth / videoHeight
	}
}

private func renderLine(_ thisBreak: String, context: CGContext, spanExtra: SubCTRenderer.SpanExtra) {
	var attribs = [NSAttributedStringKey: Any]()
	attribs[NSAttributedStringKey.CoreText.foregroundColor] = spanExtra.primaryColor
	attribs[NSAttributedStringKey.CoreText.font] = spanExtra.font
	attribs[NSAttributedStringKey.CoreText.strokeColor] = spanExtra.outlineColor
	attribs[NSAttributedStringKey.CoreText.strokeWidth] = spanExtra.outlineRadius
	let attrBreak = NSAttributedString(string: thisBreak, attributes: attribs)
	let line = CTLineCreateWithAttributedString(attrBreak)
	_=line
}

//CTLineCreateWithAttributedString

//static void RenderActualLine(ATSUTextLayout layout, UniCharArrayOffset thisBreak, UniCharArrayOffset lineLen, Fixed penX, Fixed penY, CGContextRef c, SubRenderDiv *div, SubATSUISpanExtra *spanEx, SubTextLayer textType)

