/*
 * SubATSUIRenderer.m
 * Created by Alexander Strange on 7/30/07.
 *
 * This file is part of Perian.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#import "SubATSUIRenderer.h"
#import "SubImport.h"
#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"
#import "Codecprintf.h"
#import "CommonUtils.h"
#include <pthread.h>
#import <CoreText/CoreText.h>


#ifdef QD_HEADERS_ARE_PRIVATE
extern OSStatus ATSUSetLayoutControls(
					  ATSUTextLayout                iTextLayout,
					  ItemCount                     iAttributeCount,
					  const ATSUAttributeTag        iTag[],
					  const ByteCount               iValueSize[],
					  const ATSUAttributeValuePtr   iValue[]) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUCreateAndCopyStyle(
					   ATSUStyle    iStyle,
					   ATSUStyle *  oStyle) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUDisposeTextLayout(ATSUTextLayout iTextLayout) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUCreateAndCopyStyle(
					   ATSUStyle    iStyle,
					   ATSUStyle *  oStyle) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUDisposeStyle(ATSUStyle iStyle) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUSetAttributes(
				  ATSUStyle                     iStyle,
				  ItemCount                     iAttributeCount,
				  const ATSUAttributeTag        iTag[],
				  const ByteCount               iValueSize[],
				  const ATSUAttributeValuePtr   iValue[]) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus
ATSUSetLayoutControls(
					  ATSUTextLayout                iTextLayout,
					  ItemCount                     iAttributeCount,
					  const ATSUAttributeTag        iTag[],
					  const ByteCount               iValueSize[],
					  const ATSUAttributeValuePtr   iValue[]) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUCreateTextLayout(ATSUTextLayout * oTextLayout) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUCreateStyle(ATSUStyle * oStyle) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUSetTextPointerLocation(
						   ATSUTextLayout         iTextLayout,
						   ConstUniCharArrayPtr   iText,
						   UniCharArrayOffset     iTextOffset,
						   UniCharCount           iTextLength,
						   UniCharCount           iTextTotalLength) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUFindFontFromName(
					 const void *		iName,
					 ByteCount          iNameLength,
					 FontNameCode       iFontNameCode,
					 FontPlatformCode   iFontNamePlatform,
					 FontScriptCode     iFontNameScript,
					 FontLanguageCode   iFontNameLanguage,
					 ATSUFontID *       oFontID) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUSetTransientFontMatching(
							 ATSUTextLayout   iTextLayout,
							 Boolean          iTransientFontMatching) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetLineControl(
				   ATSUTextLayout          iTextLayout,
				   UniCharArrayOffset      iLineStart,
				   ATSUAttributeTag        iTag,
				   ByteCount               iExpectedValueSize,
				   ATSUAttributeValuePtr   oValue,
				   ByteCount *             oActualValueSize) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUFontCount(ItemCount * oFontCount) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetFontIDs(
			   ATSUFontID   oFontIDs[],
			   ItemCount    iArraySize,
			   ItemCount *  oFontCount) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUFindFontName(
				 ATSUFontID         iFontID,
				 FontNameCode       iFontNameCode,
				 FontPlatformCode   iFontNamePlatform,
				 FontScriptCode     iFontNameScript,
				 FontLanguageCode   iFontNameLanguage,
				 ByteCount          iMaximumNameLength,
				 Ptr                oName,
				 ByteCount *        oActualNameLength,
				 ItemCount *        oFontNameIndex) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetGlyphBounds(
				   ATSUTextLayout        iTextLayout,
				   ATSUTextMeasurement   iTextBasePointX,
				   ATSUTextMeasurement   iTextBasePointY,
				   UniCharArrayOffset    iBoundsCharStart,
				   UniCharCount          iBoundsCharLength,
				   UInt16                iTypeOfBounds,
				   ItemCount             iMaxNumberOfBounds,
				   ATSTrapezoid          oGlyphBounds[],
				   ItemCount *           oActualNumberOfBounds) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUMeasureTextImage(
					 ATSUTextLayout        iTextLayout,
					 UniCharArrayOffset    iLineOffset,
					 UniCharCount          iLineLength,
					 ATSUTextMeasurement   iLocationX,
					 ATSUTextMeasurement   iLocationY,
					 Rect *                oTextImageRect) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUSetRunStyle(
				ATSUTextLayout       iTextLayout,
				ATSUStyle            iStyle,
				UniCharArrayOffset   iRunStart,
				UniCharCount         iRunLength) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetRunStyle(
				ATSUTextLayout        iTextLayout,
				UniCharArrayOffset    iOffset,
				ATSUStyle *           oStyle,
				UniCharArrayOffset *  oRunStart,
				UniCharCount *        oRunLength) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUSetSoftLineBreak(
					 ATSUTextLayout       iTextLayout,
					 UniCharArrayOffset   iLineBreak) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetSoftLineBreaks(
					  ATSUTextLayout       iTextLayout,
					  UniCharArrayOffset   iRangeStart,
					  UniCharCount         iRangeLength,
					  ItemCount            iMaximumBreaks,
					  UniCharArrayOffset   oBreaks[],
					  ItemCount *          oBreakCount) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUDrawText(
			 ATSUTextLayout        iTextLayout,
			 UniCharArrayOffset    iLineOffset,
			 UniCharCount          iLineLength,
			 ATSUTextMeasurement   iLocationX,
			 ATSUTextMeasurement   iLocationY) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUDirectGetLayoutDataArrayPtrFromTextLayout(
													   ATSUTextLayout           iTextLayout,
													   UniCharArrayOffset       iLineOffset,
													   ATSUDirectDataSelector   iDataSelector,
													   void *                   oLayoutDataArrayPtr[],
													   ItemCount *              oLayoutDataCount
													   ) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUDirectReleaseLayoutDataArrayPtr(
													ATSULineRef              iLineRef,
													ATSUDirectDataSelector   iDataSelector,
													void *                   iLayoutDataArrayPtr[]
													) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUBatchBreakLines(
							 ATSUTextLayout iTextLayout,
							 UniCharArrayOffset iRangeStart,
							 UniCharCount iRangeLength,
							 ATSUTextMeasurement iLineWidth,
							 ItemCount * oBreakCount
							 ) CF_DEPRECATED_MAC(10_0, 10_8);
extern OSStatus ATSUGetUnjustifiedBounds (
								   ATSUTextLayout iTextLayout,
								   UniCharArrayOffset iLineStart,
								   UniCharCount iLineLength,
								   ATSUTextMeasurement *oTextBefore,
								   ATSUTextMeasurement *oTextAfter,
								   ATSUTextMeasurement *oAscent,
								   ATSUTextMeasurement *oDescent
								   ) CF_DEPRECATED_MAC(10_0, 10_8);

#endif

static CGFloat GetWinATSFontSizeScale(ATSFontRef font);
static void FindAllPossibleLineBreaks(TextBreakLocatorRef breakLocator, const unichar *uline, UniCharArrayOffset lineLen, uint8_t *breakOpportunities);
static ATSUFontID GetFontIDForSSAName(NSString *name);
static CGColorRef CreateCGColorFromRGBA(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;
static CGColorRef CreateCGColorFromRGBOpaque(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;

#define declare_bitfield(name, bits) uint8_t name[bits / 8 + 1]; bzero(name, sizeof(name));
#define bitfield_set(name, bit) name[(bit) / 8] |= 1 << ((bit) % 8);
#define bitfield_test(name, bit) ((name[(bit) / 8] & (1 << ((bit) % 8))) != 0)

@interface SubATSUStyle : NSObject <NSCopying> {
@public;
	ATSUStyle style;
}
- (instancetype)initWithATSUStyle:(ATSUStyle)_style;
@end

@interface SubATSUISpanExtra : NSObject <NSCopying> {
	@public;
	SubATSUStyle *style;
	CGColorRef primaryColor, outlineColor, shadowColor;
	Float32 outlineRadius, shadowDist, scaleX, scaleY, primaryAlpha, outlineAlpha, angle, platformSizeScale, fontSize;
	BOOL blurEdges, vertical;
	ATSUFontID font;
}
-(instancetype)initWithStyle:(SubStyle*)sstyle colorSpace:(CGColorSpaceRef)cs;
@end

@implementation SubATSUStyle
-(instancetype)initWithATSUStyle:(ATSUStyle)_style
{
	if (self = [super init]) {
		style = _style;
	}
	return self;
}

- (id)copyWithZone:(NSZone*)zone
{
	SubATSUStyle *sty = [SubATSUStyle new];
	ATSUCreateAndCopyStyle(style, &sty->style);
	return sty;
}

- (void)dealloc
{
	ATSUDisposeStyle(style);
}
@end

@implementation SubATSUISpanExtra
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

- (instancetype)initWithStyle:(SubStyle*)sstyle colorSpace:(CGColorSpaceRef)cs
{	
	if (self = [super init]) {
		SubATSUStyle *extra = sstyle.extra;
		
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
		font = GetFontIDForSSAName(sstyle->fontname);
	}
	
	return self;
}

-(id)copyWithZone:(NSZone*)zone
{
	SubATSUISpanExtra *ret = [[SubATSUISpanExtra alloc] init];
	
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
	ret->font = font;
	ret->blurEdges = blurEdges;
	ret->vertical = vertical;
	
	return ret;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"SpanEx with alpha %f/%f", primaryAlpha, outlineAlpha];
}

-(void)dealloc
{
	CGColorRelease(primaryColor);
	CGColorRelease(outlineColor);
	CGColorRelease(shadowColor);
}
@end

#define span_ex(span) ((SubATSUISpanEx*)span->ex)

static void SetATSUStyleFlag(ATSUStyle style, ATSUAttributeTag t, Boolean v)
{
	const ATSUAttributeTag tags[] = {t};
	const ByteCount		 sizes[] = {sizeof(v)};
	const ATSUAttributeValuePtr vals[] = {&v};
	
	ATSUSetAttributes(style,1,tags,sizes,vals);
}

static void SetATSUStyleOther(ATSUStyle style, ATSUAttributeTag t, ByteCount s, const ATSUAttributeValuePtr v)
{
	const ATSUAttributeTag tags[] = {t};
	const ByteCount		 sizes[] = {s};
	const ATSUAttributeValuePtr vals[] = {v};
	
	ATSUSetAttributes(style,1,tags,sizes,vals);
}

static void SetATSULayoutOther(ATSUTextLayout l, ATSUAttributeTag t, ByteCount s, const ATSUAttributeValuePtr v)
{
	const ATSUAttributeTag tags[] = {t};
	const ByteCount		 sizes[] = {s};
	const ATSUAttributeValuePtr vals[] = {v};
	
	ATSUSetLayoutControls(l,1,tags,sizes,vals);
}

@implementation SubATSUIRenderer
@synthesize context;

- (instancetype)initWithScriptType:(int)type header:(NSString*)header videoWidth:(CGFloat)width videoHeight:(CGFloat)height
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

		breakBuffer = malloc(sizeof(UniCharArrayOffset) * 2);
		ATSUCreateTextLayout(&layout);
		srgbCSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		UCCreateTextBreakLocator(NULL, 0, kUCTextBreakLineMask, &breakLocator);
		drawTextBounds = CFPreferencesGetAppBooleanValue(CFSTR("DrawSubTextBounds"), PERIAN_PREF_DOMAIN, NULL);
	}
	
	return self;
}

-(void)didCompleteHeaderParsing:(SubContext*)sc
{
	screenScaleX = videoWidth / sc->resX;
	screenScaleY = videoHeight / sc->resY;
}

-(CGFloat)aspectRatio
{
	return videoWidth / videoHeight;
}

static NSMutableDictionary *fontIDCache = nil;
static ItemCount fontCount;
static ATSUFontID *fontIDs = NULL;

/// Assumes ATSUFontID = ATSFontRef. This is true.
static ATSUFontID GetFontIDForSSAName(NSString *name)
{	
	NSNumber *idN = nil;
	NSString *lcName = [name lowercaseString];
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fontIDCache = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					   @(ATSFontFindFromName((CFStringRef)kSubDefaultFontName, kATSOptionFlagsDefault)),
					   kSubDefaultFontName, nil];
	});
	
	@synchronized(fontIDCache) {
		idN = [fontIDCache objectForKey:lcName];
		
		if (idN != nil)
			return [idN unsignedIntValue];
		
		ByteCount nlen = [name length];
		NSData *unameData;
		const unichar *uname = SubUnicodeForString(name, &unameData);
		ATSUFontID font;
		
		ATSUFindFontFromName(uname, nlen * sizeof(unichar), kFontFamilyName, kFontMicrosoftPlatform, kFontNoScript, kFontNoLanguage, &font);
		
		unameData = nil;
		
		if (font == kATSUInvalidFontID) font = ATSFontFindFromName((__bridge CFStringRef)name, kATSOptionFlagsDefault);
		if (font == kATSUInvalidFontID) { // try a case-insensitive search
			if (!fontIDs) {
				ATSUFontCount(&fontCount);
				fontIDs = malloc(sizeof(ATSUFontID[fontCount]));
				ATSUGetFontIDs(fontIDs, fontCount, &fontCount);
			}
			
#define kBufLength 512
			ByteCount len;
			ItemCount x, index;
			unichar buf[kBufLength];
	  
			for (x = 0; x < fontCount && font == kATSUInvalidFontID; x++) {
				ATSUFindFontName(fontIDs[x], kFontFamilyName, kFontMicrosoftPlatform, kFontNoScript, kFontNoLanguage, kBufLength, (Ptr)buf, &len, &index);
				len = MIN(len, kBufLength);
				NSString *fname = [[NSString alloc] initWithCharactersNoCopy:buf length:len/sizeof(unichar) freeWhenDone:NO];
				
				if ([name caseInsensitiveCompare:fname] == NSOrderedSame)
					font = fontIDs[x];
			}
#undef kBufLength
		}
		
		if (font == kATSUInvalidFontID)
			font = [[fontIDCache objectForKey:kSubDefaultFontName] intValue]; // final fallback
		
		/*{
		 NSString *fontPSName = nil;
		 ATSFontGetPostScriptName(font, kATSOptionFlagsDefault, (CFStringRef*)&fontPSName);
		 NSLog(@"Font lookup: %@ -> %@", name, fontPSName);
		 [fontPSName autorelease];
		 }*/
		[fontIDCache setValue:@(font) forKey:lcName];
		
		return font;
	}
}

-(void)didCompleteStyleParsing:(SubStyle*)s
{
	const ATSUAttributeTag tags[] = {kATSUStyleRenderingOptionsTag, kATSUSizeTag, kATSUQDBoldfaceTag, kATSUQDItalicTag, kATSUQDUnderlineTag, kATSUStyleStrikeThroughTag, kATSUFontTag};
	const ByteCount		 sizes[] = {sizeof(ATSStyleRenderingOptions), sizeof(Fixed), sizeof(Boolean), sizeof(Boolean), sizeof(Boolean), sizeof(Boolean), sizeof(ATSUFontID)};
	
	Boolean b = s->weight > 0, i = s->italic, u = s->underline, st = s->strikeout;
	ATSStyleRenderingOptions opt = kATSStyleApplyAntiAliasing;
	ATSUFontID font = GetFontIDForSSAName(s.fontname);
	ATSFontRef fontRef = font;
	ATSUStyle style;
	Fixed size;
		
	const ATSUAttributeValuePtr vals[] = {&opt, &size, &b, &i, &u, &st, &font};
	
	if (!s->platformSizeScale) s->platformSizeScale = GetWinATSFontSizeScale(fontRef);
	size = FloatToFixed(s->size * s->platformSizeScale * screenScaleY); //FIXME: several other values also change relative to PlayRes but aren't handled
	
	ATSUCreateStyle(&style);
	ATSUSetAttributes(style, sizeof(tags) / sizeof(ATSUAttributeTag), tags, sizes, vals);
	
	if (s->tracking > 0) { // bug in VSFilter: negative tracking in style lines is ignored
		Fixed tracking = FloatToFixed(s->tracking);
		
		SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &tracking);
	}
	
	if (s->scaleX != 100. || s->scaleY != 100.) {
		CGAffineTransform mat = CGAffineTransformMakeScale(s->scaleX / 100., s->scaleY / 100.);
		
		SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
	}
	
	s.extra = [[SubATSUStyle alloc] initWithATSUStyle:style];
}

-(void)didCreateStartingSpan:(SubRenderSpan *)span forDiv:(SubRenderDiv *)div
{
	span.extra = [[SubATSUISpanExtra alloc] initWithStyle:div->styleLine colorSpace:srgbCSpace];
}

static void UpdateFontNameSize(SubATSUISpanExtra *spanEx, float screenScale)
{
	Fixed fSize = FloatToFixed(spanEx->fontSize * spanEx->platformSizeScale * screenScale);
	ATSUStyle style = spanEx->style->style;
	SetATSUStyleOther(style, kATSUFontTag, sizeof(ATSUFontID), &spanEx->font);
	SetATSUStyleOther(style, kATSUSizeTag, sizeof(Fixed), &fSize);
}

enum {renderMultipleParts = 1, // call ATSUDrawText more than once, needed for color/border changes in the middle of lines
	  renderManualShadows = 2, // CG shadows can't change inside a line... probably
	  renderComplexTransforms = 4}; // can't draw text at all, have to transform each vertex. needed for 3D perspective, or \frz in the middle of a line

-(void)spanChangedTag:(SubSSATagName)tag span:(SubRenderSpan*)span div:(SubRenderDiv*)div param:(void*)p
{
	SubATSUISpanExtra *spanEx = span.extra;
	ATSUStyle style = spanEx->style->style;
	BOOL isFirstSpan = [div->spans count] == 0;
	CGColorRef color;
	CGAffineTransform mat;
	ATSFontRef oldFont;
	Boolean bval;
	Fixed fixval;
	NSString *sval;
	float fval;
	int ival;

#define bv() bval = *(int*)p;
#define iv() ival = *(int*)p;
#define fv() fval = *(float*)p;
#define sv() sval = *(NSString*__unsafe_unretained*)p;
#define fixv() fv(); fixval = FloatToFixed(fval);
#define colorv() color = CreateCGColorFromRGBA(SubParseSSAColor(*(int*)p), srgbCSpace);
	
	switch (tag) {
		case tag_b:
			bv(); // FIXME: font weight variations
			SetATSUStyleFlag(style, kATSUQDBoldfaceTag, bval != 0);
			break; 
		case tag_i:
			bv();
			SetATSUStyleFlag(style, kATSUQDItalicTag, bval);
			break; 
		case tag_u:
			bv();
			SetATSUStyleFlag(style, kATSUQDUnderlineTag, bval);
			break; 
		case tag_s:
			bv();
			SetATSUStyleFlag(style, kATSUStyleStrikeThroughTag, bval);
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
			oldFont = spanEx->font;
			spanEx->vertical = SubParseFontVerticality(&sval);
			spanEx->font = GetFontIDForSSAName(sval);
			if (oldFont != spanEx->font) spanEx->platformSizeScale = GetWinATSFontSizeScale(spanEx->font);
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
			SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
			break;
		case tag_fscy:
			fv();
			spanEx->scaleY = fval / 100.;
			mat = CGAffineTransformMakeScale(spanEx->scaleX, spanEx->scaleY);
			SetATSUStyleOther(style, kATSUFontMatrixTag, sizeof(CGAffineTransform), &mat);
			break;
		case tag_fsp:
			fixv();
			SetATSUStyleOther(style, kATSUAfterWithStreamShiftTag, sizeof(Fixed), &fixval);
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
				
				span.extra = [[SubATSUISpanExtra alloc] initWithStyle:sstyle colorSpace:srgbCSpace];
			}
			break;
		case tag_be:
			bv();
			if (!isFirstSpan) div->render_complexity |= renderMultipleParts; //FIXME: blur edges
			spanEx->blurEdges = bval;
			break;
		case tag_p:
			fv();
			div->scale = fval;
			break;
		case tag_frx:
			Codecprintf(NULL, "Unimplemented SSA tag 'frx'\n");
			break;
		case tag_fry:
			Codecprintf(NULL, "Unimplemented SSA tag 'fry'\n");
			break;
		case tag_2c:
			Codecprintf(NULL, "Unimplemented SSA tag '2c'\n");
			break;
		case tag_2a:
			Codecprintf(NULL, "Unimplemented SSA tag '2a'\n");
			break;
		case tag_t:
			Codecprintf(NULL, "Unimplemented SSA tag 't'\n");
			break;
		case tag_pbo:
			Codecprintf(NULL, "Unimplemented SSA tag 'pbo'\n");
			break;
		default:
			Codecprintf(NULL, "Unimplemented SSA tag #%d\n",tag);
			break;
	}
}

#pragma mark Rendering Helper Functions

/// see comment for GetTypographicRectangleForLayout
static ATSUTextMeasurement GetLineHeight(ATSUTextLayout layout, UniCharArrayOffset lpos, Boolean includeDescent)
{
	ATSUTextMeasurement ascent = 0, descent = 0;
	
	ATSUGetLineControl(layout, lpos, kATSULineAscentTag,  sizeof(ATSUTextMeasurement), &ascent,  NULL);
	if (includeDescent) ATSUGetLineControl(layout, lpos, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);
	
	return ascent + descent;
}

static void ExpandCGRect(CGRect *rect, CGFloat radius)
{
	rect->origin.x -= radius;
	rect->origin.y -= radius;
	rect->size.height += radius*2.;
	rect->size.width += radius*2.;
}

/// some broken fonts have very wrong typographic values set, and so this occasionally gives nonsense
/// it should be checked against the real pixel box (see #if 0 below), but for correct fonts it looks much better
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
}

/// Draw the text bounds on screen under the actual text
/// Note that it almost never appears where it's supposed to be, and I'm not sure if that's my fault or ATSUI's
static void VisualizeLayoutLineHeights(CGContextRef c, ATSUTextLayout layout, UniCharArrayOffset *breaks, ItemCount breakCount, Fixed extraHeight, Fixed penX, Fixed penY, float screenHeight)
{
	ATSTrapezoid trap = {0};
	Rect pixRect = {0};
	ItemCount trapCount;
	NSInteger i;
	
	CGContextSetLineWidth(c, 3.0);
	
	for (i = breakCount; i >= 0; i--) {
		UniCharArrayOffset end = breaks[i+1];

		ATSUMeasureTextImage(layout, breaks[i], end-breaks[i], 0, 0, &pixRect);
		ATSUGetGlyphBounds(layout, 0, 0, breaks[i], end-breaks[i], kATSUseDeviceOrigins, 1, &trap, &trapCount);
		
		CGContextSetRGBStrokeColor(c, 1,0,0,1);
		CGContextBeginPath(c);
		CGContextMoveToPoint(c, FixedToFloat(penX + trap.upperLeft.x),  FixedToFloat(penY + trap.lowerLeft.y));
		CGContextAddLineToPoint(c, FixedToFloat(penX + trap.upperRight.x),  FixedToFloat(penY + trap.lowerRight.y));
		CGContextAddLineToPoint(c, FixedToFloat(penX + trap.lowerRight.x),  FixedToFloat(penY + trap.upperRight.y));
		CGContextAddLineToPoint(c, FixedToFloat(penX + trap.lowerLeft.x),  FixedToFloat(penY + trap.upperLeft.y));
		CGContextClosePath(c);
		CGContextStrokePath(c);
		CGContextSetRGBStrokeColor(c, 0, 0, 1, 1);
		CGContextStrokeRect(c, CGRectMake(FixedToFloat(penX) + pixRect.left, FixedToFloat(penY) + pixRect.top, pixRect.right - pixRect.left, pixRect.bottom - pixRect.top));
		
		penY += GetLineHeight(layout, breaks[i], YES) + extraHeight;
	}
}

#if 0
static void GetImageBoundingBoxForLayout(ATSUTextLayout layout, UniCharArrayOffset *breaks, ItemCount breakCount, Fixed extraHeight, Fixed *lX, Fixed *lY, Fixed *height, Fixed *width)
{
	Rect largeRect = {0};
	ATSUTextMeasurement baseY = 0;
	int i;
	
	for (i = breakCount; i >= 0; i--) {
		UniCharArrayOffset end = breaks[i+1];
		Rect rect;
		
		ATSUMeasureTextImage(layout, breaks[i], end-breaks[i], 0, baseY, &rect);
		
		baseY += GetLineHeight(layout, breaks[i], YES) + extraHeight;
		
		if (i == breakCount) largeRect = rect;
		
		largeRect.bottom = MAX(largeRect.bottom, rect.bottom);
		largeRect.left = MIN(largeRect.left, rect.left);
		largeRect.top = MIN(largeRect.top, rect.top);
		largeRect.right = MAX(largeRect.right, rect.right);
	}
	
	
	if (lX) *lX = IntToFixed(largeRect.left);
	if (lY) *lY = IntToFixed(largeRect.bottom);
	*height = IntToFixed(largeRect.bottom - largeRect.top);
	*width = IntToFixed(largeRect.right - largeRect.left);
}
#endif

typedef enum {fillc, strokec} fill_or_stroke;

static void SetColor(CGContextRef c, fill_or_stroke whichcolor, CGColorRef col)
{
	if (whichcolor == fillc) CGContextSetFillColorWithColor(c, col);
	else CGContextSetStrokeColorWithColor(c, col);
}

static void MakeRunVertical(ATSUTextLayout layout, UniCharArrayOffset spanOffset, UniCharArrayOffset length)
{
	ATSUStyle style, vStyle;
	ATSUVerticalCharacterType vertical = kATSUStronglyVertical;
	
	ATSUGetRunStyle(layout, spanOffset, &style, NULL, NULL);
	ATSUCreateAndCopyStyle(style, &vStyle);
	SetATSUStyleOther(vStyle, kATSUVerticalCharacterTag, sizeof(vertical), &vertical);
	ATSUSetRunStyle(layout, vStyle, spanOffset, length);
	ATSUDisposeStyle(vStyle);
}

static void EnableVerticalForSpan(ATSUTextLayout layout, SubRenderDiv *div, const unichar *ubuffer, UniCharArrayOffset spanOffset, UniCharArrayOffset length)
{
	const unichar tategakiLowerBound = 0x02F1; // copied from http://source.winehq.org/source/dlls/gdi32/freetype.c
	NSInteger runStart, runAboveBound, i;
	
	if (!length) return;
	
	runStart = spanOffset;
	runAboveBound = ubuffer[spanOffset] >= tategakiLowerBound;
	
	for (i = spanOffset+1; i < spanOffset + length; i++) {
		int isAboveBound = ubuffer[i] >= tategakiLowerBound;
		
		if (isAboveBound != runAboveBound) {
			if (runAboveBound)
				MakeRunVertical(layout, runStart, i - runStart);
			runStart = i;
			runAboveBound = isAboveBound;
		}
	}
	
	if (runAboveBound)
		MakeRunVertical(layout, runStart, i - runStart);
}

static void SetStyleSpanRuns(ATSUTextLayout layout, SubRenderDiv *div, const unichar *ubuffer)
{
	NSInteger span_count = [div->spans count];
	NSInteger i;
	
	for (i = 0; i < span_count; i++) {
		SubRenderSpan *span = [div->spans objectAtIndex:i];
		UniCharArrayOffset next = (i == span_count-1) ? [div->text length] : ((SubRenderSpan*)[div->spans objectAtIndex:i+1])->offset, spanLen = next - span->offset;
		SubATSUISpanExtra *ex = span.extra;
		ATSUStyle style = ex->style->style;

		ATSUSetRunStyle(layout, style, span->offset, spanLen);
		
		if (ex->vertical) {
			EnableVerticalForSpan(layout, div, ubuffer, span->offset, spanLen);
		}
	}
}

static void SetLayoutPositioning(ATSUTextLayout layout, Fixed lineWidth, SubAlignmentH align)
{
	const ATSUAttributeTag tags[] = {kATSULineFlushFactorTag, kATSULineWidthTag, kATSULineRotationTag};
	const ByteCount		  sizes[] = {sizeof(Fract), sizeof(ATSUTextMeasurement), sizeof(Fixed)};
	Fract alignment;
	Fixed fixzero = 0;
	const ATSUAttributeValuePtr vals[] = {&alignment, &lineWidth, &fixzero};
	
	switch (align) {
		case kSubAlignmentLeft:
			alignment = FloatToFract(0);
			break;
		case kSubAlignmentCenter:
			alignment = kATSUCenterAlignment;
			break;
		case kSubAlignmentRight:
			alignment = fract1;
			break;
	}
	
	ATSUSetLayoutControls(layout,sizeof(vals) / sizeof(ATSUAttributeValuePtr),tags,sizes,vals);
}

static UniCharArrayOffset BreakOneLineSpan(ATSUTextLayout layout, SubRenderDiv *div, uint8_t *breakOpportunities,
										   ATSLayoutRecord *records, ItemCount lineLen, Fixed idealLineWidth, Fixed originalLineWidth, Fixed maximumLineWidth, NSInteger numBreaks, NSInteger lastHardBreak)
{		
	UniCharArrayOffset lastBreakOffset = 0;
	Fixed widthOffset = 0;
	int recOffset = 0;
	BOOL foundABreak;

	do {
		int j, lastIndex = 0;
		ATSUTextMeasurement error = 0;
		foundABreak = NO;
				
		for (j = recOffset; j < lineLen; j++) {
			ATSLayoutRecord *rec = &records[j];
			UniCharArrayOffset charOffset = rec->originalOffset/2 + lastHardBreak;
			Fixed recPos = rec->realPos - widthOffset;

			if (bitfield_test(breakOpportunities, charOffset)) {
				if (recPos >= idealLineWidth) {
					error = recPos - idealLineWidth;

					if (lastIndex) {
						Fixed lastError = abs((records[lastIndex].realPos - widthOffset) - idealLineWidth);
						if (lastError < error || div->wrapStyle == kSubLineWrapBottomWider) {
							rec = &records[lastIndex];
							j = lastIndex;
							recPos = rec->realPos - widthOffset;
							charOffset = rec->originalOffset/2 + lastHardBreak;
						}
					}
					
					// try not to leave short trailing lines
					if ((recPos + (originalLineWidth - rec->realPos)) < maximumLineWidth) return 0;
						
					foundABreak = YES;
					lastBreakOffset = charOffset;
					ATSUSetSoftLineBreak(layout, charOffset);
					break;
				}
				
				lastIndex = j;
			}
		}
		
		widthOffset = records[j].realPos;
		recOffset = j;
		numBreaks--;
	} while (foundABreak && numBreaks);
		
	return (numBreaks == 0) ? 0 : lastBreakOffset;
}

static void BreakLinesEvenly(ATSUTextLayout layout, SubRenderDiv *div, TextBreakLocatorRef breakLocator, Fixed breakingWidth, const unichar *utext, NSInteger textLen, ItemCount numHardBreaks)
{
	UniCharArrayOffset hardBreaks[numHardBreaks+2];
	declare_bitfield(breakOpportunities, textLen);
	float fBreakingWidth = FixedToFloat(breakingWidth);
	OSStatus err = noErr;
	int i;
	
	ATSUGetSoftLineBreaks(layout, kATSUFromTextBeginning, kATSUToTextEnd, numHardBreaks, &hardBreaks[1], NULL);	
	FindAllPossibleLineBreaks(breakLocator, utext, textLen, breakOpportunities);
		
	hardBreaks[0] = 0;
	hardBreaks[numHardBreaks+1] = textLen;
	
	for (i = 0; i <= numHardBreaks; i++) {
		UniCharArrayOffset thisBreak = hardBreaks[i], nextBreak = hardBreaks[i+1];
		ATSUTextMeasurement leftEdge, rightEdge, ignore;
		
		ATSUGetUnjustifiedBounds(layout, thisBreak, nextBreak - thisBreak, &leftEdge, &rightEdge, &ignore, &ignore);
		Fixed lineWidth = rightEdge - leftEdge;
		float fLineWidth = FixedToFloat(lineWidth);
				
		if (lineWidth > breakingWidth) {
			ATSLayoutRecord *records;
			ItemCount numRecords;
			int idealSplitLines = ceilf(fLineWidth / fBreakingWidth);
			Fixed idealBreakWidth = FloatToFixed(fLineWidth / idealSplitLines);
			
			err = ATSUDirectGetLayoutDataArrayPtrFromTextLayout(layout, thisBreak, kATSUDirectDataLayoutRecordATSLayoutRecordCurrent, (void*)&records, &numRecords);
			if (err) goto err;
			UniCharArrayOffset res = BreakOneLineSpan(layout, div, breakOpportunities, records, numRecords, idealBreakWidth, lineWidth, breakingWidth, idealSplitLines-1, thisBreak);
			
			ATSUDirectReleaseLayoutDataArrayPtr(NULL, kATSUDirectDataLayoutRecordATSLayoutRecordCurrent, (void*)&records);
			
			if (res) ATSUBatchBreakLines(layout, res, nextBreak - res, breakingWidth, NULL);
		}
	}
	
	return;
err:
	Codecprintf(NULL, "ATSU error %d accessing text layout\n", (int)err);
}

static UniCharArrayOffset *FindLineBreaks(ATSUTextLayout layout, SubRenderDiv *div, TextBreakLocatorRef breakLocator, UniCharArrayOffset *breaks, ItemCount *nbreaks, Fixed breakingWidth, const unichar *utext, NSInteger textLen)
{
	ItemCount breakCount=0;
	
	switch (div->wrapStyle) {
		case kSubLineWrapSimple:
			ATSUBatchBreakLines(layout, kATSUFromTextBeginning, kATSUToTextEnd, breakingWidth, &breakCount);
			break;
		case kSubLineWrapTopWider:
		case kSubLineWrapBottomWider:
		case kSubLineWrapNone:
			SetLayoutPositioning(layout, positiveInfinity, kSubAlignmentLeft);	
			ATSUBatchBreakLines(layout, kATSUFromTextBeginning, kATSUToTextEnd, positiveInfinity, &breakCount);
			if (div->wrapStyle != kSubLineWrapNone) {
				BreakLinesEvenly(layout, div, breakLocator, breakingWidth, utext, textLen, breakCount);
				ATSUGetSoftLineBreaks(layout, kATSUFromTextBeginning, kATSUToTextEnd, 0, NULL, &breakCount);
			}
			SetLayoutPositioning(layout, breakingWidth, div->alignH);	
			break;
	}
		
	breaks = realloc(breaks, sizeof(UniCharArrayOffset) * (breakCount+2));
	ATSUGetSoftLineBreaks(layout, kATSUFromTextBeginning, kATSUToTextEnd, breakCount, &breaks[1], NULL);
	
	breaks[0] = 0;
	breaks[breakCount+1] = textLen;
	
	*nbreaks = breakCount;
	return breaks;
}

typedef struct {
	UniCharArrayOffset *breaks;
	ItemCount breakCount;
	NSInteger lStart, lEnd;
	SInt8 direction;
} BreakContext;

typedef enum {
	kTextLayerShadow,
	kTextLayerOutline,
	kTextLayerPrimary,
	kTextLayerPrimaryUnstyled
} SubTextLayer;

static BOOL SetupCGForSpan(CGContextRef c, SubATSUISpanExtra *spanEx, SubATSUISpanExtra *lastSpanEx, SubRenderDiv *div, SubTextLayer textType, BOOL endLayer)
{	
#define if_different(x) if (!lastSpanEx || lastSpanEx-> x != spanEx-> x)
	
	switch (textType) {
		case kTextLayerShadow:
			if_different(shadowColor) {
				if (endLayer) CGContextEndTransparencyLayer(c);

				SetColor(c, fillc, spanEx->shadowColor);
				SetColor(c, strokec, spanEx->shadowColor);
				if (CGColorGetAlpha(spanEx->shadowColor) != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else endLayer = NO;
			}
			break;
			
		case kTextLayerOutline:
			if_different(outlineRadius) CGContextSetLineWidth(c, spanEx->outlineRadius ? (spanEx->outlineRadius*2. + .5) : 0.);
			if_different(outlineColor)  SetColor(c, (div->styleLine->borderStyle == kSubBorderStyleNormal) ? strokec : fillc, spanEx->outlineColor);
			
			if_different(outlineAlpha) {
				if (endLayer) CGContextEndTransparencyLayer(c);
				CGContextSetAlpha(c, spanEx->outlineAlpha);
				if (spanEx->outlineAlpha != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else endLayer = NO;
			}
				
			break;
		case kTextLayerPrimary:
			if_different(primaryColor) SetColor(c, fillc, spanEx->primaryColor);
			
			if_different(primaryAlpha) {
				if (endLayer) CGContextEndTransparencyLayer(c);

				CGContextSetAlpha(c, spanEx->primaryAlpha);
				if (spanEx->primaryAlpha != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else endLayer = NO;
			}
			break;
			
		case kTextLayerPrimaryUnstyled:
			break;
	}
	
	return endLayer;
}

static void RenderActualLine(ATSUTextLayout layout, UniCharArrayOffset thisBreak, UniCharArrayOffset lineLen, Fixed penX, Fixed penY, CGContextRef c, SubRenderDiv *div, SubATSUISpanExtra *spanEx, SubTextLayer textType)
{
	//ATS bug(?) with some fonts:
	//drawing \n draws some random other character, so skip them
	//FIXME: maybe don't store newlines in div->text at all
	if ([div->text characterAtIndex:thisBreak+lineLen-1] == '\n') {
		lineLen--;
		if (!lineLen) return;
	}

	if (textType == kTextLayerOutline && div->styleLine->borderStyle == kSubBorderStyleBox) {
		ATSUTextMeasurement lineWidth, lineHeight, lineX, lineY;
		UniCharArrayOffset breaks[2] = {thisBreak, thisBreak + lineLen};
		GetTypographicRectangleForLayout(layout, breaks, 0, FloatToFixed(spanEx->outlineRadius), &lineX, &lineY, &lineHeight, &lineWidth);
		
		CGRect borderRect = CGRectMake(FixedToFloat(lineX + penX), FixedToFloat(penY - lineY), FixedToFloat(lineWidth), FixedToFloat(lineHeight));
		
		ExpandCGRect(&borderRect, spanEx->outlineRadius);
		
		borderRect.origin.x = floor(borderRect.origin.x);
		borderRect.origin.y = floor(borderRect.origin.y);
		borderRect.size.width  = ceil(borderRect.size.width);
		borderRect.size.height = ceil(borderRect.size.height);
		
		CGContextFillRect(c, borderRect);
	} else ATSUDrawText(layout, thisBreak, lineLen, penX, penY);
}

static Fixed DrawTextLines(CGContextRef c, ATSUTextLayout layout, SubRenderDiv *div, const BreakContext breakc, Fixed penX, Fixed penY, SubATSUISpanExtra *firstSpanEx, SubTextLayer textType)
{
	const CGTextDrawingMode textModes[] = {kCGTextFillStroke, kCGTextStroke, kCGTextFill, kCGTextFill};
	SubATSUISpanExtra *lastSpanEx = nil;
	BOOL endLayer = NO, multipleParts = !!(div->render_complexity & renderMultipleParts);
	NSInteger i;

	CGContextSetTextDrawingMode(c, textModes[textType]);
	
	if (!multipleParts) endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);
	
	for (i = breakc.lStart; i != breakc.lEnd; i -= breakc.direction) {
		UniCharArrayOffset thisBreak = breakc.breaks[i], nextBreak = breakc.breaks[i+1], linelen = nextBreak - thisBreak;
		CGFloat extraHeight = 0;
		
		if (!multipleParts) {
			RenderActualLine(layout, thisBreak, linelen, penX, penY, c, div, firstSpanEx, textType);
			extraHeight = div->styleLine->outlineRadius;
		} else {
			NSInteger j, nspans = [div->spans count];
			
			//linear search for the next span to draw
			//FIXME: make sure this never skips any spans
			for (j = 0; j < nspans; j++) {
				SubRenderSpan *span = [div->spans objectAtIndex:j];
				SubATSUISpanExtra *spanEx = span.extra;
				UniCharArrayOffset spanLen, drawStart, drawLen;
				
				if (j < nspans-1) {
					SubRenderSpan *nextSpan = [div->spans objectAtIndex:j+1];
					spanLen = nextSpan->offset - span->offset;
				} else spanLen = [div->text length] - span->offset;
				
				if (span->offset < thisBreak) { // text spans a newline
					drawStart = thisBreak;
					drawLen = spanLen - (thisBreak - span->offset);
				} else {
					drawStart = span->offset;
					drawLen = MIN(spanLen, nextBreak - span->offset);
				}
				
				if (spanLen == 0 || drawLen == 0)         continue;
				if ((span->offset + spanLen) < thisBreak) continue; // too early
				if (span->offset >= nextBreak)            break; // too far ahead

				endLayer = SetupCGForSpan(c, spanEx, lastSpanEx, div, textType, endLayer);
				RenderActualLine(layout, drawStart, drawLen, (textType == kTextLayerShadow) ? (penX + FloatToFixed(spanEx->shadowDist)) : penX, 
														 (textType == kTextLayerShadow) ? (penY - FloatToFixed(spanEx->shadowDist)) : penY, c, div, spanEx, textType);
				extraHeight = MAX(extraHeight, spanEx->outlineRadius);
				lastSpanEx = spanEx;
			}
		
		}

		penY += breakc.direction * (GetLineHeight(layout, thisBreak, YES) + FloatToFixed(extraHeight));
	}
		
	if (endLayer) CGContextEndTransparencyLayer(c);

	return penY;
}

static Fixed DrawOneTextDiv(CGContextRef c, ATSUTextLayout layout, SubRenderDiv *div, const BreakContext breakc, Fixed penX, Fixed penY)
{
	SubRenderSpan *firstSpan = [div->spans objectAtIndex:0];
	SubATSUISpanExtra *firstSpanEx = firstSpan.extra;
	BOOL drawShadow, drawOutline, clearOutlineInnerStroke;
	BOOL endLayer = NO;
	
	if (div->render_complexity & renderMultipleParts) {
		drawShadow = drawOutline = clearOutlineInnerStroke = YES;
	} else {
		drawShadow = div->styleLine->borderStyle == kSubBorderStyleNormal && firstSpanEx->shadowDist;
		drawOutline= div->styleLine->borderStyle != kSubBorderStyleNormal || firstSpanEx->outlineRadius;
		clearOutlineInnerStroke = firstSpanEx->primaryAlpha < 1.;
	}
	
	if (drawShadow) {
		if (!(div->render_complexity & renderManualShadows)) {
			endLayer = YES;
			CGContextSetShadowWithColor(c, CGSizeMake(firstSpanEx->shadowDist + .5, -(firstSpanEx->shadowDist + .5)), 0, firstSpanEx->shadowColor);
			CGContextBeginTransparencyLayer(c, NULL);
		} else {
			DrawTextLines(c, layout, div, breakc, penX, penY, firstSpanEx, kTextLayerShadow);
		}
	}
	
	if (drawOutline) {
		if (clearOutlineInnerStroke) {
			CGContextBeginTransparencyLayer(c, NULL);
		}
		DrawTextLines(c, layout, div, breakc, penX, penY, firstSpanEx, kTextLayerOutline);
		if (clearOutlineInnerStroke) {
			CGContextSetBlendMode(c, kCGBlendModeClear);
			DrawTextLines(c, layout, div, breakc, penX, penY, firstSpanEx, kTextLayerPrimaryUnstyled);
			CGContextSetBlendMode(c, kCGBlendModeNormal);
			CGContextEndTransparencyLayer(c);
		}
	}

	penY = DrawTextLines(c, layout, div, breakc, penX, penY, firstSpanEx, kTextLayerPrimary);
	
	if (endLayer) {
		CGContextEndTransparencyLayer(c);
		CGContextSetShadowWithColor(c, CGSizeMake(0,0), 0, NULL);
	}
	
	return penY;
}

static void drawShapePart(CGContextRef c, CGPathRef path, SubRenderDiv *div, SubATSUISpanExtra *firstSpanEx, SubTextLayer textType)
{
	const CGPathDrawingMode textModes[] = {kCGPathFillStroke, kCGPathStroke, kCGPathFill, kCGPathFill};
	SubATSUISpanExtra *lastSpanEx = nil;
	BOOL endLayer = NO, multipleParts = !!(div->render_complexity & renderMultipleParts);
	if (!multipleParts) {
		endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);
	}
	endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);

	CGContextAddPath(c, path);
	CGContextDrawPath(c, textModes[textType]);

	if (endLayer) CGContextEndTransparencyLayer(c);
}

static void drawShape(CGContextRef c, CGPathRef path, SubRenderDiv *div, SubATSUISpanExtra *firstSpanEx)
{
	BOOL drawShadow, drawOutline, clearOutlineInnerStroke;
	BOOL endLayer = NO;
	if (div->render_complexity & renderMultipleParts) {
		drawShadow = drawOutline = clearOutlineInnerStroke = YES;
	} else {
		drawShadow = div->styleLine->borderStyle == kSubBorderStyleNormal && firstSpanEx->shadowDist;
		drawOutline= div->styleLine->borderStyle != kSubBorderStyleNormal || firstSpanEx->outlineRadius;
		clearOutlineInnerStroke = firstSpanEx->primaryAlpha < 1.;
	}

	
	if (drawShadow) {
		if (!(div->render_complexity & renderManualShadows)) {
			endLayer = YES;
			CGContextSetShadowWithColor(c, CGSizeMake(firstSpanEx->shadowDist + .5, -(firstSpanEx->shadowDist + .5)), 0, firstSpanEx->shadowColor);
			CGContextBeginTransparencyLayer(c, NULL);
		} else {
			drawShapePart(c, path, div, firstSpanEx, kTextLayerShadow);
		}
	}
	
	if (drawOutline) {
		if (clearOutlineInnerStroke) {
			CGContextBeginTransparencyLayer(c, NULL);
		}
		drawShapePart(c, path, div, firstSpanEx, kTextLayerOutline);
		if (clearOutlineInnerStroke) {
			CGContextSetBlendMode(c, kCGBlendModeClear);
			drawShapePart(c, path, div, firstSpanEx, kTextLayerPrimaryUnstyled);
			CGContextSetBlendMode(c, kCGBlendModeNormal);
			CGContextEndTransparencyLayer(c);
		}
	}
	
	drawShapePart(c, path, div, firstSpanEx, kTextLayerPrimary);
	
	if (endLayer) {
		CGContextEndTransparencyLayer(c);
		CGContextSetShadowWithColor(c, CGSizeMake(0,0), 0, NULL);
	}
}

#pragma mark Main Renderer Function

-(void)renderPacket:(NSString *)packet inContext:(CGContextRef)c size:(CGSize)size
{
	Fixed bottomPen = 0, topPen = 0, centerPen = 0, *storePen=NULL;
	NSArray<SubRenderDiv*> *divs = SubParsePacket(packet, context, self);
	NSInteger lastLayer = 0;

	CGContextSaveGState(c);
	if (size.width != videoWidth || size.height != videoHeight)
		CGContextScaleCTM(c, size.width / videoWidth, size.height / videoHeight);
	CGContextSetLineCap(c, kCGLineCapRound); // avoid spiky outlines on some fonts
	CGContextSetLineJoin(c, kCGLineJoinRound);
	CGContextSetShouldSmoothFonts(c, NO);    // don't do LCD subpixel antialiasing
	CGContextSetShouldSubpixelQuantizeFonts(c, NO); // draw text stroke and fill in the same place
	
	SetATSULayoutOther(layout, kATSUCGContextTag, sizeof(CGContextRef), &c);

	for (SubRenderDiv *div in divs) {
		NSInteger textLen = [div->text length];
		if (!textLen || ![div->spans count]) continue;
		
		BOOL resetPens = NO, resetGState = NO;
		NSData *ubufferData;
		const unichar *ubuffer = SubUnicodeForString(div->text, &ubufferData);
		
		if (div->layer != lastLayer || div->shouldResetPens) {
			resetPens = YES;
			lastLayer = div->layer;
		}
		
		//NSLog(@"%@", div);
		
		NSRect marginRect = NSMakeRect(div->marginL, div->marginV, context->resX - div->marginL - div->marginR, context->resY - div->marginV - div->marginV);
		
		marginRect.origin.x *= screenScaleX;
		marginRect.origin.y *= screenScaleY;
		marginRect.size.width  *= screenScaleX;
		marginRect.size.height *= screenScaleY;

		Fixed penY, penX, breakingWidth = FloatToFixed(marginRect.size.width);
		BreakContext breakc = {0}; ItemCount breakCount;
		
		ATSUSetTextPointerLocation(layout, ubuffer, kATSUFromTextBeginning, kATSUToTextEnd, textLen);		
		ATSUSetTransientFontMatching(layout,TRUE);
		
		SetLayoutPositioning(layout, breakingWidth, div->alignH);
		SetStyleSpanRuns(layout, div, ubuffer);
		
		breakBuffer = FindLineBreaks(layout, div, breakLocator, breakBuffer, &breakCount, breakingWidth, ubuffer, textLen);

		ATSUTextMeasurement imageWidth = 0, imageHeight = 0, descent = 0;
		UniCharArrayOffset *breaks = breakBuffer;
		
		if (div->positioned || div->alignV == kSubAlignmentMiddle)
			GetTypographicRectangleForLayout(layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), NULL, NULL, &imageHeight, &imageWidth);
		
		if (div->positioned || div->alignV != kSubAlignmentTop)
			ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);
		
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
			VisualizeLayoutLineHeights(c, layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), penX, penY, size.height);

		breakc.breakCount = breakCount;
		breakc.breaks = breaks;
		
		penY = DrawOneTextDiv(c, layout, div, breakc, penX, penY);
		}
		if (resetGState)
			CGContextRestoreGState(c);
		
		ubufferData = nil;
		if (storePen) *storePen = penY;
	}
	
	CGContextRestoreGState(c);
}

-(void)dealloc
{
	free(breakBuffer);
	UCDisposeTextBreakLocator(&breakLocator);
	CGColorSpaceRelease(srgbCSpace);
	ATSUDisposeTextLayout(layout);
}
@end

#if 0
SubRendererRef SubRendererCreate(bool isSSA, char *header, size_t headerLen, int width, int height)
{
	@autoreleasepool {
		SubRendererRef s = nil;
		@try {
			NSString *hdr = nil;
			if (header) 
				hdr = [[NSString alloc] initWithBytesNoCopy:(void*)header length:headerLen encoding:NSUTF8StringEncoding freeWhenDone:NO];
			s = (SubRendererRef)CFBridgingRetain([[SubATSUIRenderer alloc] initWithScriptType:isSSA ? kSubTypeSSA : kSubTypeSRT header:hdr videoWidth:width videoHeight:height]);
		}
		@catch (NSException *e) {
			NSLog(@"Caught exception while creating SubRenderer - %@", e);
		}
		return s;
	}
}

SubRendererRef SubRendererCreateCF(bool isSSA, CFStringRef header, int width, int height)
{
	@autoreleasepool {
		SubRendererRef s = nil;
		@try {
			s = (SubRendererRef)CFBridgingRetain([[SubATSUIRenderer alloc] initWithScriptType:isSSA ? kSubTypeSSA : kSubTypeSRT header:(__bridge NSString * _Nullable)(header) videoWidth:width videoHeight:height]);
		}
		@catch (NSException *e) {
			NSLog(@"Caught exception while creating SubRenderer - %@", e);
		}
		return s;
	}
}
#endif

#include "TTStructs.h"

#define BRIDGE_TO_CTFONT 0

// Windows and OS X use different TrueType fields to measure text.
// Some Windows fonts have one field set incorrectly(?), so we have to compensate.
// FIXME: This function doesn't read from the right fonts; if we're using italic variant, it should get the ATSFontRef for that
// This should be cached
static CGFloat GetWinATSFontSizeScale(ATSFontRef font)
{
#if defined(BRIDGE_TO_CTFONT) && BRIDGE_TO_CTFONT
	CTFontRef ctFnt = CTFontCreateWithPlatformFont(font, 0, NULL, NULL);
	if (ctFnt) {
		CGFloat toRet = GetWinCTFontSizeScale(ctFnt);
		CFRelease(ctFnt);
		return toRet;
	} else {
#endif
		TT_Header headTable = {0};
		TT_OS2 os2Table = {0};
		ByteCount os2Size = 0, headSize = 0;
		
		OSErr err = ATSFontGetTable(font, 'OS/2', 0, 0, NULL, &os2Size);
		if (!os2Size || err) return 1;
		
		err = ATSFontGetTable(font, 'head', 0, 0, NULL, &headSize);
		if (!headSize || err) return 1;
		
		ATSFontGetTable(font, 'head', 0, headSize, &headTable, &headSize);
		ATSFontGetTable(font, 'OS/2', 0, os2Size, &os2Table, &os2Size);
		
		// ppem = units_per_em * lfheight / (winAscent + winDescent) c.f. WINE
		// lfheight being SSA font size
		unsigned short oA = EndianU16_BtoN(os2Table.usWinAscent), oD = EndianU16_BtoN(os2Table.usWinDescent);
		unsigned winSize = oA + oD;
		
		unsigned unitsPerEM = EndianU16_BtoN(headTable.Units_Per_EM);
		
		return (winSize && unitsPerEM) ? ((CGFloat)unitsPerEM / (CGFloat)winSize) : 1;
#if defined(BRIDGE_TO_CTFONT) && BRIDGE_TO_CTFONT
	}
#endif
}

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
