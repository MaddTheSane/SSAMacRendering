//
//  SubCoreTextRenderer.m
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#include <CoreText/CoreText.h>
#import "SubCoreTextRenderer.h"
#import "SubImport.h"
#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"
#include "CommonUtils.h"
#import "Codecprintf.h"

#define declare_bitfield(name, bits) uint8_t name[bits / 8 + 1]; bzero(name, sizeof(name));
#define bitfield_set(name, bit) name[(bit) / 8] |= 1 << ((bit) % 8);
#define bitfield_test(name, bit) ((name[(bit) / 8] & (1 << ((bit) % 8))) != 0)


static CGColorRef CreateCGColorFromRGBA(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;
static CGColorRef CreateCGColorFromRGBOpaque(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;

static CGColorRef CreateCGColorFromRGBA(SubRGBAColor c, CGColorSpaceRef cspace)
{
	const CGFloat components[] = {c.red, c.green, c.blue, c.alpha};
	
	return CGColorCreate(cspace, components);
}

static CGColorRef CreateCGColorFromRGBOpaque(SubRGBAColor c, CGColorSpaceRef cspace)
{
	SubRGBAColor c2 = c;
	c2.alpha = 1;
	return CreateCGColorFromRGBA(c2, cspace);
}

static CGColorRef CopyCGColorWithAlpha(CF_CONSUMED CGColorRef c, CGFloat alpha)
{
	CGColorRef new = CGColorCreateCopyWithAlpha(c, alpha);
	CGColorRelease(c);
	return new;
}

static NSString * const Scale;

@interface SubCoreTextStyle : NSObject <NSCopying> {
@public;
	NSMutableDictionary<NSString*,id> *style;
}
- (instancetype)initWithCoreTextStyle:(NSDictionary<NSString*,id> *)_style;

@end


@interface SubCoreTextSpanExtra: NSObject <NSCopying> {
@public;
	SubCoreTextStyle *style;
	CGColorRef primaryColor, outlineColor, shadowColor;
	CGFloat outlineRadius, shadowDist, scaleX, scaleY, primaryAlpha, outlineAlpha, angle, platformSizeScale, fontSize;
	BOOL blurEdges, vertical;
	NSString *fontName;
}

-(instancetype)initWithStyle:(SubStyle*)sstyle colorSpace:(CGColorSpaceRef)cs;

@end

@implementation SubCoreTextStyle

- (instancetype)initWithCoreTextStyle:(NSDictionary<NSString*,id> *)_style;
{
	if (self = [super init]) {
		style = [_style mutableCopy];
	}
	return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
	SubCoreTextStyle *toCopy = [SubCoreTextStyle new];
	toCopy->style = [style mutableCopy];
	return toCopy;
}


@end

@implementation SubCoreTextSpanExtra

-(instancetype)initWithStyle:(SubStyle*)sstyle colorSpace:(CGColorSpaceRef)cs
{
	if (self = [super init]) {
		SubCoreTextStyle *extra = sstyle.extra;
		
		style = [extra copy];
		primaryColor = CreateCGColorFromRGBOpaque(sstyle->primaryColor, cs);
		primaryAlpha = sstyle->primaryColor.alpha;
		outlineColor = CreateCGColorFromRGBOpaque(sstyle->outlineColor, cs);
		outlineAlpha = sstyle->outlineColor.alpha;
		shadowColor  = CreateCGColorFromRGBA(sstyle->shadowColor,  cs);
		outlineRadius = sstyle->outlineRadius;
		shadowDist = sstyle->shadowDist;
		scaleX = sstyle->scaleX / 100.;
		scaleY = sstyle->scaleY / 100.;
		angle = sstyle->angle;
		platformSizeScale = sstyle->platformSizeScale;
		fontSize = sstyle->size;
		vertical = sstyle->vertical;
		fontName = sstyle->fontname;
		
	}
	
	return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
	SubCoreTextSpanExtra *ret = [[SubCoreTextSpanExtra alloc] init];
	
	ret->style = [style copy];
	ret->primaryColor = CGColorRetain(primaryColor);
	ret->primaryAlpha = primaryAlpha;
	ret->outlineColor = CGColorRetain(outlineColor);
	ret->outlineAlpha = outlineAlpha;
	ret->shadowColor = CGColorRetain(shadowColor);
	ret->outlineRadius = outlineRadius;
	ret->shadowDist = shadowDist;
	ret->scaleX = scaleX;
	ret->scaleY = scaleY;
	ret->angle = angle;
	ret->platformSizeScale = platformSizeScale;
	ret->fontSize = fontSize;
	ret->fontName = [fontName copy];
	ret->blurEdges = blurEdges;
	ret->vertical = vertical;
	
	return ret;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"SpanEx with alpha %f/%f", primaryAlpha, outlineAlpha];
}

- (void)dealloc
{
	CGColorRelease(primaryColor);
	CGColorRelease(outlineColor);
	CGColorRelease(shadowColor);
}

@end

@implementation SubCoreTextRenderer
{
	SubContext *context;
	CGFloat screenScaleX, screenScaleY, videoWidth, videoHeight;
	BOOL drawTextBounds;
	CGColorSpaceRef srgbCSpace;
}

+ (CGFontRef)registerFontFromData:(NSData*)data error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
	CGDataProviderRef datProvid = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	if (!datProvid) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
		}
		return NULL;
	}
	CGFontRef aFont = CGFontCreateWithDataProvider(datProvid);
	CGDataProviderRelease(datProvid);
	if (!aFont) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
		}
		return NULL;
	}
	
	CFErrorRef ourErr = NULL;
	
	BOOL success = CTFontManagerRegisterGraphicsFont(aFont, &ourErr);
	if (!success) {
		CGFontRelease(aFont);
		NSError *nsErr = CFBridgingRelease(ourErr);
		if (error) {
			*error = nsErr;
		}
		return NULL;
	}
	
	return aFont;
}

+ (BOOL)unregisterFont:(CF_CONSUMED CGFontRef)font error:(NSError*_Nullable __autoreleasing*_Nullable)error
{
	CFErrorRef ourErr = NULL;

	BOOL success = CTFontManagerUnregisterGraphicsFont(font, &ourErr);
	if (!success) {
		NSError *nsErr = CFBridgingRelease(ourErr);
		if (error) {
			*error = nsErr;
		}
	}
	CGFontRelease(font);
	return success;
}

- (instancetype)initWithScriptType:(SubType)type header:(NSString*)header videoWidth:(CGFloat)width videoHeight:(CGFloat)height
{
	if (self = [super init]) {
		NSDictionary *headers = nil;
		NSArray *styles = nil;
		
		videoWidth = width;
		videoHeight = height;
		
		if (header) {
			header = SubStandardizeStringNewlines(header);
			SubParseSSAFile(header, &headers, &styles, NULL);
		}
		
		context = [[SubContext alloc] initWithScriptType:type headers:headers styles:styles delegate:self];
		srgbCSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);

	}
	return self;
}

- (void)renderPacket:(NSString *)packet inContext:(CGContextRef)c width:(CGFloat)cWidth height:(CGFloat)cHeight
{
	NSArray<SubRenderDiv*>* divs = SubParsePacket(packet, context, self);
	int32_t lastLayer = 0;

	CGContextSaveGState(c);
	if (cWidth != videoWidth || cHeight != videoHeight) {
		CGContextScaleCTM(c, cWidth / videoWidth, cHeight / videoHeight);
	}
	CGContextSetLineCap(c, kCGLineCapRound); // avoid spiky outlines on some fonts
	CGContextSetLineJoin(c, kCGLineJoinRound);
	CGContextSetShouldSmoothFonts(c, false); // don't do LCD subpixel antialiasing
	CGContextSetShouldSubpixelQuantizeFonts(c, false); // draw text stroke and fill in the same place
	
	for (SubRenderDiv *div in divs) {
		NSInteger textLen = [div->text length];
		if (!textLen || ![div->spans count]) {
			continue;
		}

		/*
		 guard let text = div.text, text.count != 0, div.spans!.count != 0 else {

		 */
	}
}

-(void)didCompleteHeaderParsing:(SubContext*)sc
{
	screenScaleX = videoWidth / sc->resX;
	screenScaleY = videoHeight / sc->resY;
}

-(void)didCompleteStyleParsing:(SubStyle*)s
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:7];
	
//	Boolean b = s->weight > 0, i = s->italic, u = s->underline, st = s->strikeout;
	NSFontTraitMask traits = 0;
	if (s->weight > 0) {
		traits |= NSBoldFontMask;
	}
	if (s->italic) {
		traits |= NSItalicFontMask;
	}
	NSFont *font = [NSFont fontWithName:s.fontname size:0];
	NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:traits];
	
	if (s->underline) {
		dict[(NSString*)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleSingle);
	}
	
	if (!s->platformSizeScale) s->platformSizeScale = GetWinCTFontSizeScale((__bridge CTFontRef)(font));
	CGFloat size = s->size * s->platformSizeScale * screenScaleY; //FIXME: several other values also change relative to PlayRes but aren't handled
	newFont = [[NSFontManager sharedFontManager] convertFont:font toSize:size];

	if (s->scaleX != 100. || s->scaleY != 100.) {
		NSAffineTransform*d = [NSAffineTransform transform];
		[d scaleXBy:s->scaleX / 100. yBy:s->scaleY / 100.];
		NSFontDescriptor *descriptor = [newFont fontDescriptor];
		
		newFont = [NSFont fontWithDescriptor:descriptor textTransform:d];
	}

	dict[(NSString*)kCTFontAttributeName] = newFont;
	
	if (s->tracking > 0) { // bug in VSFilter: negative tracking in style lines is ignored
		Fixed tracking = FloatToFixed(s->tracking);
		
//		SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &tracking);
	}
		
	s.extra = [[SubCoreTextStyle alloc] initWithCoreTextStyle:dict];

}

-(void)didCreateStartingSpan:(SubRenderSpan*)span forDiv:(SubRenderDiv*)div
{
	span.extra = [[SubCoreTextSpanExtra alloc] initWithStyle:div->styleLine colorSpace:srgbCSpace];
}

static void UpdateFontNameSize(SubCoreTextSpanExtra *spanEx, CGFloat screenScale)
{
	NSMutableDictionary *style = spanEx->style->style;
	NSFont *aFont = style[(NSString*)kCTFontAttributeName];
	CGFloat fSize = spanEx->fontSize * spanEx->platformSizeScale * screenScale;
	NSString *fontName = spanEx->fontName;
	aFont = [[NSFontManager sharedFontManager] convertFont:aFont toSize:fSize];
	aFont = [[NSFontManager sharedFontManager] convertFont:aFont toFace:fontName];
	style[(NSString*)kCTFontAttributeName] = aFont;
}


typedef NS_OPTIONS(UInt8, RenderOptions) {
	renderMultipleParts = 1, //!< call ATSUDrawText more than once, needed for color/border changes in the middle of lines
	renderManualShadows = 2, //!< CG shadows can't change inside a line... probably
	renderComplexTransforms = 4 //!< can't draw text at all, have to transform each vertex. needed for 3D perspective, or \frz in the middle of a line
};

-(void)spanChangedTag:(SubSSATagName)tag span:(SubRenderSpan*)span div:(SubRenderDiv*)div param:(void*)p
{
	SubCoreTextSpanExtra *spanEx = span.extra;
	NSMutableDictionary *style = spanEx->style->style;
	BOOL isFirstSpan = [div->spans count] == 0;
	CGColorRef color;
	CGAffineTransform mat;
	NSString *oldFontName;
	bool bval;
	NSString *sval;
	float fval;
	int ival;
	
#define bv() bval = *(int*)p;
#define iv() ival = *(int*)p;
#define fv() fval = *(float*)p;
#define sv() sval = *(NSString*__unsafe_unretained*)p;
#define colorv() color = CreateCGColorFromRGBA(SubParseSSAColor(*(int*)p), srgbCSpace);
	
	switch (tag) {
		case tag_b:
			iv(); // FIXME: font weight variations
		{
			NSFont *oldFont = style[(NSString*)kCTFontAttributeName];
			NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:oldFont toHaveTrait: (ival != 0) ? NSBoldFontMask : NSUnboldFontMask];
			style[(NSString*)kCTFontAttributeName] = newFont;
		}
			break;
		case tag_i:
			bv();
		{
			NSFont *oldFont = style[(NSString*)kCTFontAttributeName];
			NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:oldFont toHaveTrait: (bval != 0) ? NSItalicFontMask : NSUnitalicFontMask];
			style[(NSString*)kCTFontAttributeName] = newFont;
		}
			break;
		case tag_u:
			bv();
			style[(NSString*)kCTUnderlineStyleAttributeName] = @(bval ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone);
			break;
		case tag_s:
			bv();
			//style[]
			//SetATSUStyleFlag(style, kATSUStyleStrikeThroughTag, bval);
			break;
		case tag_bord:
			fv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts;
			spanEx->outlineRadius = fval;
			break;
		case tag_shad:
			fv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts | renderManualShadows;
			spanEx->shadowDist = fval;
			break;
		case tag_fn:
			sv();
			if (![sval length]) sval = div->styleLine->fontname;
			spanEx->vertical = SubParseFontVerticality(&sval);
			oldFontName = spanEx->fontName;
			spanEx->fontName = [sval copy];
			if ([oldFontName isEqualToString:spanEx->fontName]) {
				CTFontRef tmpRef = CTFontCreateWithName((CFStringRef)sval, 0, NULL);
				spanEx->platformSizeScale = GetWinCTFontSizeScale(tmpRef);
				CFRelease(tmpRef);
			}
			UpdateFontNameSize(spanEx, screenScaleY);
			break;
		case tag_fs:
			fv();
			spanEx->fontSize = fval;
			UpdateFontNameSize(spanEx, screenScaleY);
			break;
		case tag_1c:
			CGColorRelease(spanEx->primaryColor);
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts;
			colorv();
			spanEx->primaryColor = color;
			break;
		case tag_3c:
			CGColorRelease(spanEx->outlineColor);
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts;
		{
			SubRGBAColor rgba = SubParseSSAColor(*(int*)p);
			spanEx->outlineColor = CreateCGColorFromRGBOpaque(rgba, srgbCSpace);
			spanEx->outlineAlpha = rgba.alpha;
		}
			break;
		case tag_4c:
			CGColorRelease(spanEx->shadowColor);
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts | renderManualShadows;
			colorv();
			spanEx->shadowColor = color;
			break;
		case tag_fscx:
			fv();
			spanEx->scaleX = fval / 100.;
			mat = CGAffineTransformMakeScale(spanEx->scaleX, spanEx->scaleY);
			//SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
			break;
		case tag_fscy:
			fv();
			spanEx->scaleY = fval / 100.;
			mat = CGAffineTransformMakeScale(spanEx->scaleX, spanEx->scaleY);
			//[NSValue valueWith]
			//SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
			break;
		case tag_fsp:
			fv();
			//SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &fixval);
			break;
		case tag_frz:
			fv();
			if (!isFirstSpan) div->render_complexity |= renderComplexTransforms; // this one's hard
			spanEx->angle = fval;
			break;
		case tag_1a:
			iv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts;
			spanEx->primaryAlpha = (255-ival)/255.;
			break;
		case tag_3a:
			iv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts;
			spanEx->outlineAlpha = (255-ival)/255.;
			break;
		case tag_4a:
			iv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts | renderManualShadows;
			spanEx->shadowColor = CopyCGColorWithAlpha(spanEx->shadowColor, (255-ival)/255.);
			break;
		case tag_alpha:
			iv();
			fval = (255-ival)/255.;
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts | renderManualShadows;
			spanEx->primaryAlpha = spanEx->outlineAlpha = fval;
			spanEx->shadowColor = CopyCGColorWithAlpha(spanEx->shadowColor, fval);
			break;
		case tag_r:
			sv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts | renderManualShadows;
		{
			SubStyle *sstyle = [context->styles objectForKey:sval];
			if (!sstyle) sstyle = div->styleLine;
			
			span.extra = [[SubCoreTextSpanExtra alloc] initWithStyle:sstyle colorSpace:srgbCSpace];
		}
			break;
		case tag_be:
			bv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts; //FIXME: blur edges
			spanEx->blurEdges = bval;
			break;
		case tag_p:
			fv();
			Codecprintf(NULL, "Unimplemented SSA tag 'p'\n");
			break;
		case tag_frx:
			fv();
			Codecprintf(NULL, "Unimplemented SSA tag 'frx'\n");
			break;
		case tag_fry:
			fv();
			Codecprintf(NULL, "Unimplemented SSA tag 'fry'\n");
			break;
		case tag_2c:
			colorv();
			Codecprintf(NULL, "Unimplemented SSA tag '2c'\n");
			break;
		case tag_2a:
			colorv();
			Codecprintf(NULL, "Unimplemented SSA tag '2a'\n");
			break;
		case tag_t:
			Codecprintf(NULL, "Unimplemented SSA tag 't'\n");
			break;
		case tag_pbo:
			fv();
			Codecprintf(NULL, "Unimplemented SSA tag 'pbo'\n");
			break;
		case tag_fad:
			Codecprintf(NULL, "Unimplemented SSA tag 'fad'\n");
			break;
		default:
			Codecprintf(NULL, "Unimplemented SSA tag #%d\n",tag);
			break;
	}
}

-(CGFloat)aspectRatio
{
	return videoWidth / videoHeight;
}

@end

#if 1
SubRendererRef SubRendererCreate(bool isSSA, char *header, size_t headerLen, int width, int height)
{
	@autoreleasepool {
		NSString *hdr = nil;
		if (header)
			hdr = [[NSString alloc] initWithBytesNoCopy:(void*)header length:headerLen encoding:NSUTF8StringEncoding freeWhenDone:NO];
		return SubRendererCreateCF(isSSA, (__bridge CFStringRef _Nullable)(hdr), width, height);
	}
}

SubRendererRef SubRendererCreateCF(bool isSSA, CFStringRef header, int width, int height)
{
	@autoreleasepool {
		SubRendererRef s = nil;
		@try {
			s = (SubRendererRef)CFBridgingRetain([[SubCoreTextRenderer alloc] initWithScriptType:isSSA ? kSubTypeSSA : kSubTypeSRT header:(__bridge NSString * _Nonnull)(header) videoWidth:width videoHeight:height]);
		}
		@catch (NSException *e) {
			NSLog(@"Caught exception while creating SubRenderer - %@", e);
		}
		return s;
	}
}
#endif

#include "TTStructs.h"

//! Windows and OS X use different TrueType fields to measure text.
//! Some Windows fonts have one field set incorrectly(?), so we have to compensate.
//! This should be cached
CGFloat GetWinCTFontSizeScale(CTFontRef font)
{
	TT_Header headTable = {0};
	TT_OS2 os2Table = {0};
	
	NSData *os2TableData = CFBridgingRelease(CTFontCopyTable(font, kCTFontTableOS2, kCTFontTableOptionNoOptions));
	if (!os2TableData || os2TableData.length == 0) {
		return 1;
	}
	NSData *headTableData = CFBridgingRelease(CTFontCopyTable(font, kCTFontTableHead, kCTFontTableOptionNoOptions));
	if (!headTableData || headTableData.length == 0) {
		return 1;
	}
	
	[os2TableData getBytes:&os2Table length:MIN(os2TableData.length, sizeof(TT_OS2))];
	[headTableData getBytes:&headTable length:MIN(headTableData.length, sizeof(TT_Header))];
	
	// ppem = units_per_em * lfheight / (winAscent + winDescent) c.f. WINE
	// lfheight being SSA font size
	unsigned short oA = EndianU16_BtoN(os2Table.usWinAscent), oD = EndianU16_BtoN(os2Table.usWinDescent);
	unsigned int winSize = oA + oD;
	
	unsigned short unitsPerEM = CTFontGetUnitsPerEm(font);
	unsigned short unitsPerEM2 = EndianU16_BtoN(headTable.Units_Per_EM);
	
	if (unitsPerEM != unitsPerEM2) {
		Codecprintf(NULL, "unitsPerEM mismatch\n");
	}
	
	return (winSize && unitsPerEM) ? ((CGFloat)unitsPerEM / (CGFloat)winSize) : 1;
}
