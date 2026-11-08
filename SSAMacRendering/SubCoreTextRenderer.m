//
//  SubCoreTextRenderer3.m
//  SSAMacRendering
//
//  CoreText port of SubATSUIRenderer.m
//

#import "SubCoreTextRenderer.h"
#import "SubImport.h"
#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"
#import "Codecprintf.h"
#import "CommonUtils.h"
#include <CoreText/CoreText.h>
#include <math.h>
#include <tgmath.h>

/*
 * TODO: position fixes
 * TODO: respect scaling
 * TODO: Fix positioning of shapes
 *
 * other TODOs as found in the source code!
 */

#define declare_bitfield(name, bits) uint8_t name[bits / 8 + 1]; bzero(name, sizeof(name));
#define bitfield_set(name, bit) name[(bit) / 8] |= 1 << ((bit) % 8);
#define bitfield_test(name, bit) ((name[(bit) / 8] & (1 << ((bit) % 8))) != 0)

@class SubCoreTextSpanExtra;

static CGColorRef CreateCGColorFromRGBA(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;
static CGColorRef CreateCGColorFromRGBOpaque(SubRGBAColor c, CGColorSpaceRef cspace) CF_RETURNS_RETAINED;
static CGColorRef CopyCGColorWithAlpha(CF_CONSUMED CGColorRef c, CGFloat alpha);
static void FindAllPossibleLineBreaks(NSString *line, uint8_t *breakOpportunities);
static void UpdateFontNameSize(SubCoreTextSpanExtra *spanEx, CGFloat screenScale);

@interface SubCoreTextStyle : NSObject <NSCopying> {
@public;
	NSMutableDictionary<NSString*,id> *style;
}
- (instancetype)initWithCoreTextStyle:(NSDictionary<NSString*,id> *)_style NS_DESIGNATED_INITIALIZER;
@end

@interface SubCoreTextSpanExtra : NSObject <NSCopying> {
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
-(instancetype)initWithCoreTextStyle:(NSDictionary<NSString*,id> *)_style
{
	if (self = [super init]) {
		style = [_style mutableCopy];
	}
	return self;
}

- (instancetype)init
{
	if (self = [self initWithCoreTextStyle:@{}]) {
		
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	SubCoreTextStyle *sty = [SubCoreTextStyle new];
	sty->style = [style mutableCopy];
	return sty;
}
@end

@implementation SubCoreTextSpanExtra

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
		fontName = [sstyle->fontname copy];
	}
	return self;
}

-(id)copyWithZone:(NSZone*)zone
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

-(void)dealloc
{
	CGColorRelease(primaryColor);
	CGColorRelease(outlineColor);
	CGColorRelease(shadowColor);
}
@end

typedef NS_ENUM(int8_t, fill_or_stroke) {
	fillc,
	strokec
};

static inline void SetColor(CGContextRef c, fill_or_stroke whichcolor, CGColorRef col)
{
	if (whichcolor == fillc) CGContextSetFillColorWithColor(c, col);
	else CGContextSetStrokeColorWithColor(c, col);
}

typedef NS_ENUM(int, SubTextLayer) {
	kTextLayerShadow,
	kTextLayerOutline,
	kTextLayerPrimary,
	kTextLayerPrimaryUnstyled
};

typedef NS_OPTIONS(UInt8, RenderOptions) {
	renderMultipleParts = 1,
	renderManualShadows = 2,
	renderComplexTransforms = 4
};

typedef struct {
	UniCharArrayOffset *breaks;
	ItemCount breakCount;
	NSInteger lStart, lEnd;
	SInt8 direction;
} BreakContext;

@implementation SubCoreTextRenderer
{
	SubContext *context;
	CGColorSpaceRef srgbCSpace;
	UniCharArrayOffset *breakBuffer;
	CGFloat screenScaleX, screenScaleY, videoWidth, videoHeight;
	BOOL drawTextBounds;
}

@synthesize context;

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

+ (BOOL)registerFontsAtURL:(NSURL*)url error:(NSError**)error
{
	CFErrorRef theError = NULL;
	BOOL success = CTFontManagerRegisterFontsForURL((CFURLRef)url, kCTFontManagerScopeProcess, &theError);
	if (theError) {
		if (error) {
			*error = CFBridgingRelease(theError);
		} else {
			CFRelease(theError);
		}
	}
	return success;
}

+ (BOOL)unregisterFontsAtURL:(NSURL*)url error:(NSError**)error
{
	CFErrorRef theError = NULL;
	BOOL success = CTFontManagerUnregisterFontsForURL((CFURLRef)url, kCTFontManagerScopeProcess, &theError);
	if (theError) {
		if (error) {
			*error = CFBridgingRelease(theError);
		} else {
			CFRelease(theError);
		}
	}
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
		breakBuffer = malloc(sizeof(UniCharArrayOffset) * 2);
		srgbCSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		drawTextBounds = YES; //CFPreferencesGetAppBooleanValue(CFSTR("DrawSubTextBounds"), PERIAN_PREF_DOMAIN, NULL);
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

-(void)didCompleteStyleParsing:(SubStyle*)s
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:7];

	NSFontTraitMask traits = 0;
	if (s->weight == 1) {
		traits |= NSBoldFontMask;
	}
	if (s->italic) {
		traits |= NSItalicFontMask;
	}
	NSFont *font = [NSFont fontWithName:s.fontname size:s->size > 0 ? s->size : 12.0];
	if (!font) {
		font = [NSFont fontWithName:(NSString*)kSubDefaultFontName size:s->size > 0 ? s->size : 12.0];
	}
	NSFont *newFont = font;
	if (traits) {
		NSFont *converted = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:traits];
		if (converted) newFont = converted;
	}

	if (s->underline) {
		dict[(NSString*)kCTUnderlineStyleAttributeName] = @(kCTUnderlineStyleSingle);
	}
	if (s->strikeout) {
		// CoreText/NSAttributedString strikethrough isn't a direct CT attribute key in the same style dict usage here;
		// keep placeholder parity with previous renderers.
	}

	if (!s->platformSizeScale) s->platformSizeScale = GetWinCTFontSizeScale((__bridge CTFontRef)(font ?: newFont));
	CGFloat size = s->size * s->platformSizeScale * screenScaleY;
	newFont = [[NSFontManager sharedFontManager] convertFont:newFont toSize:size];

	if (s->scaleX != 100. || s->scaleY != 100.) {
		NSAffineTransform *t = [NSAffineTransform transform];
		[t scaleXBy:s->scaleX / 100. yBy:s->scaleY / 100.];
		NSFontDescriptor *descriptor = [newFont fontDescriptor];
		NSFont *scaled = [NSFont fontWithDescriptor:descriptor textTransform:t];
		if (scaled) newFont = scaled;
	}

	dict[(NSString*)kCTFontAttributeName] = newFont;
//	dict[(NSString*)kCTForegroundColorFromContextAttributeName] = @YES;

	if (s->tracking > 0) {
		dict[(NSString*)kCTKernAttributeName] = @(s->tracking);
	}

	s.extra = [[SubCoreTextStyle alloc] initWithCoreTextStyle:dict];
}

-(void)didCreateStartingSpan:(SubRenderSpan *)span forDiv:(SubRenderDiv *)div
{
	span.extra = [[SubCoreTextSpanExtra alloc] initWithStyle:div->styleLine colorSpace:srgbCSpace];
}

static void UpdateFontNameSize(SubCoreTextSpanExtra *spanEx, CGFloat screenScale)
{
	NSMutableDictionary *style = spanEx->style->style;
	NSFont *aFont = style[(NSString*)kCTFontAttributeName];
	CGFloat fSize = spanEx->fontSize * spanEx->platformSizeScale * screenScale;
	NSString *fontName = spanEx->fontName;
	if (aFont) {
		aFont = [[NSFontManager sharedFontManager] convertFont:aFont toSize:fSize];
		if (fontName.length) {
			NSFont *face = [[NSFontManager sharedFontManager] convertFont:aFont toFace:fontName];
			if (face) aFont = face;
		}
	} else {
		aFont = [NSFont fontWithName:fontName size:fSize];
	}
	if (aFont) style[(NSString*)kCTFontAttributeName] = aFont;
}

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
			iv();
		{
			NSFont *oldFont = style[(NSString*)kCTFontAttributeName];
			NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:oldFont toHaveTrait:(ival != 0) ? NSBoldFontMask : NSUnboldFontMask];
			if (newFont) style[(NSString*)kCTFontAttributeName] = newFont;
		}
			break;
		case tag_i:
			bv();
		{
			NSFont *oldFont = style[(NSString*)kCTFontAttributeName];
			NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:oldFont toHaveTrait:bval ? NSItalicFontMask : NSUnitalicFontMask];
			if (newFont) style[(NSString*)kCTFontAttributeName] = newFont;
		}
			break;
		case tag_u:
			bv();
			style[(NSString*)kCTUnderlineStyleAttributeName] = @(bval ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone);
			break;
		case tag_s:
			bv();
			// TODO: strikethrough
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
			if (![oldFontName isEqualToString:spanEx->fontName]) {
				CTFontRef tmpRef = CTFontCreateWithName((CFStringRef)spanEx->fontName, 0, NULL);
				if (tmpRef) {
					spanEx->platformSizeScale = GetWinCTFontSizeScale(tmpRef);
					CFRelease(tmpRef);
				}
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
			//TODO: set scale
			(void)mat;
			break;
		case tag_fscy:
			fv();
			spanEx->scaleY = fval / 100.;
			mat = CGAffineTransformMakeScale(spanEx->scaleX, spanEx->scaleY);
			//TODO: set scale
			(void)mat;
			break;
		case tag_fsp:
			fv();
			style[(NSString*)kCTKernAttributeName] = @(fval);
			break;
		case tag_frz:
			fv();
			if (!isFirstSpan) div->render_complexity |= renderComplexTransforms;
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
			div->scale = fval;
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
			CGColorRelease(color);
			Codecprintf(NULL, "Unimplemented SSA tag '2c'\n");
			break;
		case tag_2a:
			colorv();
			CGColorRelease(color);
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
			// TODO: fad support
			Codecprintf(NULL, "Unimplemented SSA tag 'fad'\n");
			break;
		case tag_fade:
			// TODO: fade support
			Codecprintf(NULL, "Unimplemented SSA tag 'fade'\n");
			break;
		default:
			Codecprintf(NULL, "Unimplemented SSA tag #%d\n",tag);
			break;
	}
#undef bv
#undef iv
#undef fv
#undef sv
#undef colorv
}

#pragma mark Rendering Helper Functions

static CGFloat GetLineHeight(CTLineRef line, BOOL includeDescent, CGFloat extraHeight)
{
	CGFloat ascent = 0, descent = 0, leading = 0;
	CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
	CGFloat h = ascent + (includeDescent ? descent : 0) + extraHeight;
	if (h <= 0) h = ascent + descent + extraHeight;
	return h;
}

static void ExpandCGRect(CGRect *rect, CGFloat radius)
{
	rect->origin.x -= radius;
	rect->origin.y -= radius;
	rect->size.height += radius*2.;
	rect->size.width += radius*2.;
}

static NSMutableAttributedString *AttributedStringForDiv(SubRenderDiv *div)
{
	NSMutableAttributedString *astr = [[NSMutableAttributedString alloc] initWithString:div->text ?: @""];
	NSInteger span_count = [div->spans count];
	for (NSInteger i = 0; i < span_count; i++) {
		SubRenderSpan *span = [div->spans objectAtIndex:i];
		NSUInteger start = span->offset;
		NSUInteger next = (i == span_count-1) ? astr.length : ((SubRenderSpan*)[div->spans objectAtIndex:i+1])->offset;
		if (start >= astr.length || next <= start) continue;
		if (next > astr.length) next = astr.length;
		SubCoreTextSpanExtra *ex = span.extra;
		NSMutableDictionary *attrs = [ex->style->style mutableCopy] ?: [NSMutableDictionary dictionary];
		// Primary text color for CoreText drawing when used in fill contexts isn't relied upon here
		// (renderer sets CG colors per layer), but keep font/underline/kerning.
		if (ex->outlineColor) {
			attrs[(NSString*)kCTStrokeColorAttributeName] = (__bridge id _Nullable)(ex->outlineColor);
		}
//		if (ex->outlineRadius) {
//			attrs[(NSString*)kCTStrokeWidthAttributeName] = @(ex->outlineRadius*2. + .5);
//		}
		if (ex->primaryColor) {
			attrs[(NSString*)kCTForegroundColorAttributeName] = (__bridge id _Nullable)(ex->primaryColor);
		}
		
		[astr setAttributes:attrs range:NSMakeRange(start, next - start)];
	}
	return astr;
}

static CTLineRef CreateCTLineForRange(NSAttributedString *astr, CFRange range)
{
	if (!astr || range.length <= 0) return NULL;
	if (range.location < 0) return NULL;
	if ((CFIndex)astr.length < range.location + range.length) return NULL;
	NSAttributedString *sub = [astr attributedSubstringFromRange:NSMakeRange((NSUInteger)range.location, (NSUInteger)range.length)];
	return CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)sub);
}

static CGFloat CTLineWidth(CTLineRef line)
{
	if (!line) return 0;
	CGFloat ascent=0,descent=0,leading=0;
	return CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
}

static void GetTypographicRectangleForCTLines(NSArray *lines, UniCharArrayOffset *breaks, ItemCount breakCount, CGFloat extraOutline, CGFloat *outWidth, CGFloat *outHeight)
{
	CGFloat maxW = 0, totalH = 0;
	for (ItemCount i = 0; i <= breakCount && (NSInteger)i < (NSInteger)lines.count; i++) {
		CTLineRef line = (__bridge CTLineRef)lines[i];
		CGFloat w = CTLineWidth(line);
		if (w > maxW) maxW = w;
		totalH += GetLineHeight(line, YES, extraOutline);
	}
	if (outWidth) *outWidth = maxW;
	if (outHeight) *outHeight = totalH;
}

static void VisualizeLayoutLineHeights(CGContextRef c, NSArray *lines, UniCharArrayOffset *breaks, ItemCount breakCount, CGFloat extraHeight, CGFloat penX, CGFloat penY)
{
	CGContextSetLineWidth(c, 1.0);
	CGFloat y = penY;
	for (ItemCount i = breakCount; (NSInteger)i >= 0; i--) {
		if ((NSInteger)i >= (NSInteger)lines.count) continue;
		CTLineRef line = (__bridge CTLineRef)lines[i];
		CGFloat ascent=0,descent=0,leading=0;
		CGFloat w = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		CGRect bounds = CTLineGetImageBounds(line, c);
		CGContextSetRGBStrokeColor(c, 1,0,0,1);
		CGContextStrokeRect(c, CGRectMake(penX, y - descent, w, ascent + descent));
		CGContextSetRGBStrokeColor(c, 0,0,1,1);
		CGContextStrokeRect(c, CGRectOffset(bounds, penX, y));
		y += GetLineHeight(line, YES, extraHeight);
	}
}

static BOOL SetupCGForSpan(CGContextRef c, SubCoreTextSpanExtra *spanEx, SubCoreTextSpanExtra *lastSpanEx, SubRenderDiv *div, SubTextLayer textType, BOOL endLayer)
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
#undef if_different
	return endLayer;
}

static void DrawCTLineWithMode(CGContextRef c, CTLineRef line, SubTextLayer textType)
{
	if (!line) return;
	CGContextSetTextPosition(c, 0, 0); // position set by caller
	if (textType == kTextLayerOutline) {
		CGContextSetTextDrawingMode(c, kCGTextStroke);
		CTLineDraw(line, c);
		CGContextSetTextDrawingMode(c, kCGTextFill);
	} else if (textType == kTextLayerShadow) {
		CGContextSetTextDrawingMode(c, kCGTextFillStroke);
		CTLineDraw(line, c);
		CGContextSetTextDrawingMode(c, kCGTextFill);
	} else {
		CGContextSetTextDrawingMode(c, kCGTextFill);
		CTLineDraw(line, c);
	}
}

static void RenderActualLine(CGContextRef c, CTLineRef line, UniCharArrayOffset thisBreak, UniCharArrayOffset lineLen, CGFloat penX, CGFloat penY, SubRenderDiv *div, SubCoreTextSpanExtra *spanEx, SubTextLayer textType)
{
	if (!line) return;
	if (lineLen == 0) return;

	if (textType == kTextLayerOutline && div->styleLine->borderStyle == kSubBorderStyleBox) {
		CGFloat ascent=0, descent=0, leading=0;
		CGFloat w = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		CGFloat h = ascent + descent + (spanEx ? spanEx->outlineRadius : div->styleLine->outlineRadius);
		CGFloat orad = spanEx ? spanEx->outlineRadius : div->styleLine->outlineRadius;
		CGRect borderRect = CGRectMake(penX, penY - descent - orad/2.0, w, h);
		ExpandCGRect(&borderRect, orad);
		borderRect.origin.x = floor(borderRect.origin.x);
		borderRect.origin.y = floor(borderRect.origin.y);
		borderRect.size.width  = ceil(borderRect.size.width);
		borderRect.size.height = ceil(borderRect.size.height);
		CGContextFillRect(c, borderRect);
		return;
	}

	CGContextSetTextPosition(c, penX, penY);
	DrawCTLineWithMode(c, line, textType);
}

static CGFloat DrawTextLinesAligned(CGContextRef c, NSAttributedString *astr, NSArray *ctLines, SubRenderDiv *div, const BreakContext breakc, CGFloat penX, CGFloat penY, SubCoreTextSpanExtra *firstSpanEx, SubTextLayer textType, CGFloat blockWidth)
{
	const CGTextDrawingMode textModes[] = {kCGTextFillStroke, kCGTextStroke, kCGTextFill, kCGTextFill};
	SubCoreTextSpanExtra *lastSpanEx = nil;
	BOOL endLayer = NO, multipleParts = !!(div->render_complexity & renderMultipleParts);

	CGContextSetTextDrawingMode(c, textModes[textType]);
	if (!multipleParts) endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);

	for (NSInteger i = breakc.lStart; i != breakc.lEnd; i -= breakc.direction) {
		if (i < 0 || i >= (NSInteger)ctLines.count) break;
		if (i+1 >= (NSInteger)(breakc.breakCount + 2) && breakc.breaks) {
			// okay
		}
		UniCharArrayOffset thisBreak = breakc.breaks ? breakc.breaks[i] : 0;
		UniCharArrayOffset nextBreak = breakc.breaks ? breakc.breaks[i+1] : 0;
		UniCharArrayOffset linelen = breakc.breaks ? (nextBreak - thisBreak) : 0;
		CGFloat extraHeight = 0;
		CTLineRef line = (__bridge CTLineRef)ctLines[i];

		CGFloat lineX = penX;
		if (div->alignH == kSubAlignmentCenter) {
			CGFloat lw = CTLineWidth(line);
			lineX = penX + (blockWidth - lw) / 2.0;
		} else if (div->alignH == kSubAlignmentRight) {
			CGFloat lw = CTLineWidth(line);
			lineX = penX + blockWidth - lw;
		} else {
			lineX = penX;
		}

		if (!multipleParts) {
			RenderActualLine(c, line, thisBreak, linelen, lineX, penY, div, firstSpanEx, textType);
			extraHeight = div->styleLine->outlineRadius;
		} else {
			NSInteger j, nspans = [div->spans count];
			for (j = 0; j < nspans; j++) {
				SubRenderSpan *span = [div->spans objectAtIndex:j];
				SubCoreTextSpanExtra *spanEx = span.extra;
				UniCharArrayOffset spanLen, drawStart, drawLen;
				if (j < nspans-1) {
					SubRenderSpan *nextSpan = [div->spans objectAtIndex:j+1];
					spanLen = nextSpan->offset - span->offset;
				} else spanLen = [div->text length] - span->offset;

				if (span->offset < thisBreak) {
					drawStart = thisBreak;
					drawLen = spanLen - (thisBreak - span->offset);
				} else {
					drawStart = span->offset;
					drawLen = MIN(spanLen, nextBreak - span->offset);
				}
				if (spanLen == 0 || drawLen == 0) continue;
				if ((span->offset + spanLen) < thisBreak) continue;
				if (span->offset >= nextBreak) break;

				endLayer = SetupCGForSpan(c, spanEx, lastSpanEx, div, textType, endLayer);
				CTLineRef spanLine = CreateCTLineForRange(astr, CFRangeMake(drawStart, drawLen));
				CGFloat spx = (textType == kTextLayerShadow) ? (lineX + spanEx->shadowDist) : lineX;
				CGFloat spy = (textType == kTextLayerShadow) ? (penY - spanEx->shadowDist) : penY;
				RenderActualLine(c, spanLine, drawStart, drawLen, spx, spy, div, spanEx, textType);
				if (spanLine) CFRelease(spanLine);
				extraHeight = MAX(extraHeight, spanEx->outlineRadius);
				lastSpanEx = spanEx;
			}
		}

		penY += breakc.direction * GetLineHeight(line, YES, extraHeight);
	}

	if (endLayer) CGContextEndTransparencyLayer(c);
	return penY;
}

static CGFloat DrawOneTextDiv(CGContextRef c, NSAttributedString *astr, NSArray *ctLines, SubRenderDiv *div, const BreakContext breakc, CGFloat penX, CGFloat penY, CGFloat blockWidth)
{
	SubRenderSpan *firstSpan = [div->spans objectAtIndex:0];
	SubCoreTextSpanExtra *firstSpanEx = firstSpan.extra;
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
			DrawTextLinesAligned(c, astr, ctLines, div, breakc, penX, penY, firstSpanEx, kTextLayerShadow, blockWidth);
		}
	}

	if (drawOutline) {
		if (clearOutlineInnerStroke) {
			CGContextBeginTransparencyLayer(c, NULL);
		}
		DrawTextLinesAligned(c, astr, ctLines, div, breakc, penX, penY, firstSpanEx, kTextLayerOutline, blockWidth);
		if (clearOutlineInnerStroke) {
			CGContextSetBlendMode(c, kCGBlendModeClear);
			DrawTextLinesAligned(c, astr, ctLines, div, breakc, penX, penY, firstSpanEx, kTextLayerPrimaryUnstyled, blockWidth);
			CGContextSetBlendMode(c, kCGBlendModeNormal);
			CGContextEndTransparencyLayer(c);
		}
	}

	penY = DrawTextLinesAligned(c, astr, ctLines, div, breakc, penX, penY, firstSpanEx, kTextLayerPrimary, blockWidth);

	if (endLayer) {
		CGContextEndTransparencyLayer(c);
		CGContextSetShadowWithColor(c, CGSizeMake(0,0), 0, NULL);
	}

	return penY;
}

static void drawShapePart(CGContextRef c, CGPathRef path, SubRenderDiv *div, SubCoreTextSpanExtra *firstSpanEx, SubTextLayer textType)
{
	const CGPathDrawingMode textModes[] = {kCGPathFillStroke, kCGPathStroke, kCGPathFill, kCGPathFill};
	SubCoreTextSpanExtra *lastSpanEx = nil;
	BOOL endLayer = NO, multipleParts = !!(div->render_complexity & renderMultipleParts);
	if (!multipleParts) {
		endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);
	}
	endLayer = SetupCGForSpan(c, firstSpanEx, lastSpanEx, div, textType, endLayer);

	CGContextAddPath(c, path);
	CGContextDrawPath(c, textModes[textType]);

	if (endLayer) CGContextEndTransparencyLayer(c);
}

static void drawShape(CGContextRef c, CGPathRef path, SubRenderDiv *div, SubCoreTextSpanExtra *firstSpanEx)
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

#pragma mark Line breaking (CoreText)

static void FindAllPossibleLineBreaks(NSString *line, uint8_t *breakOpportunities)
{
	if (!line.length) return;
	CFLocaleRef locale = CFLocaleCopyCurrent();
	CFStringTokenizerRef token = CFStringTokenizerCreate(kCFAllocatorDefault, (CFStringRef)line, CFRangeMake(0, line.length), kCFStringTokenizerUnitLineBreak, locale);
	CFRelease(locale);
	while (CFStringTokenizerAdvanceToNextToken(token) != kCFStringTokenizerTokenNone) {
		CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(token);
		if (tokenRange.location > 0 && tokenRange.location <= (CFIndex)line.length) {
			bitfield_set(breakOpportunities, (UniCharArrayOffset)tokenRange.location - 1);
		}
	}
	CFRelease(token);
}

// Build breaks by typesetting with CTTypesetter and applying SSA wrap behavior.
static UniCharArrayOffset *FindLineBreaksCT(NSAttributedString *astr, SubRenderDiv *div, UniCharArrayOffset *breaks, ItemCount *nbreaks, CGFloat breakingWidth, NSInteger textLen)
{
	NSString *str = astr.string;
	CTTypesetterRef ts = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)astr);
	NSMutableArray<NSNumber*> *br = [NSMutableArray array];

	if (div->wrapStyle == kSubLineWrapNone) {
		for (NSInteger i = 0; i < textLen; i++) {
			unichar c = [str characterAtIndex:(NSUInteger)i];
			if (c == '\n' || c == '\r') {
				[br addObject:@(i+1)];
			}
		}
	} else {
		CFIndex start = 0;
		while (start < textLen) {
			NSRange searchRange = NSMakeRange((NSUInteger)start, (NSUInteger)(textLen - start));
			NSRange nl = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:searchRange];
			CFIndex hardEnd = (nl.location == NSNotFound) ? textLen : (CFIndex)nl.location + 1;
			CFIndex lineStart = start;
			while (lineStart < hardEnd) {
				// If at newline, break
				if (lineStart < textLen) {
					unichar c2 = [str characterAtIndex:(NSUInteger)lineStart];
					if (c2 == '\n' || c2 == '\r') {
						if (lineStart + 1 <= hardEnd) {
							[br addObject:@(lineStart + 1)];
						}
						lineStart = hardEnd;
						break;
					}
				}
				CGFloat width = breakingWidth;
				if (width <= 0) width = CGFLOAT_MAX;
				CFIndex count = CTTypesetterSuggestLineBreak(ts, lineStart, width);
				if (count <= 0) {
					// try to find any break or just take to hard end
					count = hardEnd - lineStart;
				}
				CFIndex next = lineStart + count;
				if (next > hardEnd) next = hardEnd;
				if (next <= lineStart) next = lineStart + 1;
				if (next >= hardEnd) {
					lineStart = hardEnd;
					break;
				} else {
					[br addObject:@(next)];
					lineStart = next;
					// For top/bottom wider styles, ATSUI does more complex rebalancing;
					// keep greedy breaks as reasonable approximation.
				}
			}
			start = hardEnd;
		}
	}

	ItemCount breakCount = (ItemCount)br.count;
	breaks = realloc(breaks, sizeof(UniCharArrayOffset) * (breakCount + 2));
	breaks[0] = 0;
	for (ItemCount i = 0; i < breakCount; i++) breaks[i+1] = (UniCharArrayOffset)[br[i] unsignedLongValue];
	breaks[breakCount+1] = (UniCharArrayOffset)textLen;
	*nbreaks = breakCount;
	if (ts) CFRelease(ts);
	return breaks;
}

static NSArray<id> *CreateCTLinesForBreaks(NSAttributedString *astr, UniCharArrayOffset *breaks, ItemCount breakCount)
{
	NSMutableArray *lines = [NSMutableArray arrayWithCapacity:breakCount+1];
	for (ItemCount i = 0; i <= breakCount; i++) {
		CFIndex loc = breaks[i];
		CFIndex len = breaks[i+1] - breaks[i];
		if (len < 0) len = 0;
		CTLineRef line = CreateCTLineForRange(astr, CFRangeMake(loc, len));
		if (line) {
			[lines addObject:CFBridgingRelease(line)];
		} else {
			// placeholder empty line
			CTLineRef empty = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:@""]);
			[lines addObject:CFBridgingRelease(empty)];
		}
	}
	return lines;
}

static CGFloat AlignmentOffset(CGFloat lineWidth, CGFloat maxWidth, SubAlignmentH align)
{
	switch (align) {
		case kSubAlignmentLeft: return 0;
		case kSubAlignmentCenter: return (maxWidth - lineWidth) / 2.0;
		case kSubAlignmentRight: return maxWidth - lineWidth;
	}
	return 0;
}

#pragma mark Main Renderer Function

-(void)renderPacket:(NSString *)packet inContext:(CGContextRef)c size:(CGSize)size
{
	CGFloat bottomPen = 0, topPen = 0, centerPen = 0, *storePen=NULL;
	NSArray<SubRenderDiv*> *divs = SubParsePacket(packet, context, self);
	NSInteger lastLayer = 0;

	CGContextSaveGState(c);
	if (size.width != videoWidth || size.height != videoHeight)
		CGContextScaleCTM(c, size.width / videoWidth, size.height / videoHeight);
	CGContextSetLineCap(c, kCGLineCapRound);
	CGContextSetLineJoin(c, kCGLineJoinRound);
	CGContextSetShouldSmoothFonts(c, NO);
	CGContextSetShouldSubpixelQuantizeFonts(c, NO);

	for (SubRenderDiv *div in divs) {
		NSInteger textLen = [div->text length];
		if (!textLen || ![div->spans count]) continue;

		BOOL resetPens = NO, resetGState = NO;
		if (div->layer != lastLayer || div->shouldResetPens) {
			resetPens = YES;
			lastLayer = div->layer;
		}

		NSRect marginRect = NSMakeRect(div->marginL, div->marginV, context->resX - div->marginL - div->marginR, context->resY - div->marginV - div->marginV);
		marginRect.origin.x *= screenScaleX;
		marginRect.origin.y *= screenScaleY;
		marginRect.size.width  *= screenScaleX;
		marginRect.size.height *= screenScaleY;

		CGFloat penY = 0, penX = 0, breakingWidth = marginRect.size.width;
		BreakContext breakc = {0};
		ItemCount breakCount = 0;

		NSMutableAttributedString *astr = AttributedStringForDiv(div);

		breakBuffer = FindLineBreaksCT(astr, div, breakBuffer, &breakCount, breakingWidth, textLen);
		NSArray *ctLines = CreateCTLinesForBreaks(astr, breakBuffer, breakCount);

		CGFloat imageWidth = 0, imageHeight = 0, descent = 0;
		UniCharArrayOffset *breaks = breakBuffer;

		if (div->positioned || div->alignV == kSubAlignmentMiddle) {
			GetTypographicRectangleForCTLines(ctLines, breaks, breakCount, div->styleLine->outlineRadius, &imageWidth, &imageHeight);
		}
		if ((div->positioned || div->alignV != kSubAlignmentTop) && ctLines.count) {
			CGFloat a=0,d=0,l=0;
			CTLineGetTypographicBounds((__bridge CTLineRef)ctLines[0], &a,&d,&l);
			descent = d;
		}

		if (!div->positioned) {
			penX = NSMinX(marginRect);
			switch(div->alignV) {
				case kSubAlignmentBottom: default:
					if (!bottomPen || resetPens) {
						penY = NSMinY(marginRect) + descent;
					} else penY = bottomPen;
					storePen = &bottomPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
					break;
				case kSubAlignmentMiddle:
					if (!centerPen || resetPens) {
						penY = NSMidY(marginRect) - (imageHeight / 2) + descent;
					} else penY = centerPen;
					storePen = &centerPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
					break;
				case kSubAlignmentTop:
					if (!topPen || resetPens) {
						CGFloat firstH = ctLines.count ? GetLineHeight((__bridge CTLineRef)ctLines[0], NO, 0) : 0;
						penY = NSMaxY(marginRect) - firstH;
					} else penY = topPen;
					storePen = &topPen; breakc.lStart = 0; breakc.lEnd = breakCount+1; breakc.direction = -1;
					break;
			}
		} else {
			penX = div->posX * screenScaleX;
			penY = (context->resY - div->posY) * screenScaleY;
			if (imageWidth == 0 || imageHeight == 0) {
				GetTypographicRectangleForCTLines(ctLines, breaks, breakCount, div->styleLine->outlineRadius, &imageWidth, &imageHeight);
			}
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
			storePen = NULL; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
		}

		SubRenderSpan *firstSpan = [div->spans objectAtIndex:0];
		SubCoreTextSpanExtra *firstSpanEx = firstSpan.extra;

		if (div->scale > 0) {
			CGContextSaveGState(c);
			CGAffineTransform trans = CGAffineTransformMakeTranslation(div->posX, div->posY);
			CGFloat angle = firstSpanEx->angle;
			angle *= M_PI / 180.;
			trans = CGAffineTransformRotate(trans, angle);
			CGAffineTransform trans2 = CGAffineTransformMake(1, 0, 0, -1, 0, videoHeight * screenScaleY);
			CGContextConcatCTM(c, trans2);
			CGPathRef pr = CreateSubParseSubShapesWithString(div->text, &trans);
			drawShape(c, pr, div, firstSpanEx);
			CGPathRelease(pr);
			CGContextRestoreGState(c);
		} else {
			CGFloat blockWidth = breakingWidth;
			if (div->positioned && imageWidth > 0) blockWidth = imageWidth;
			if (firstSpanEx->angle) {
				// Approximate ATSUI line rotation by rotating around pen position.
				CGContextSaveGState(c);
				CGContextTranslateCTM(c, penX, penY);
				CGContextRotateCTM(c, (firstSpanEx->angle * M_PI / 180.0));
				if (firstSpanEx->vertical && div->alignV == kSubAlignmentMiddle && div->alignH == kSubAlignmentCenter) {
					CGContextTranslateCTM(c, imageWidth/2, imageWidth/2);
				}
				//FIXME: these are wrong...
				CGFloat localPenX = 0;
				CGFloat localPenY = 0;
				breakc.breakCount = breakCount;
				breakc.breaks = breaks;
				if (drawTextBounds) {
					VisualizeLayoutLineHeights(c, ctLines, breaks, breakCount, div->styleLine->outlineRadius, localPenX, localPenY);
				}
				localPenY = DrawOneTextDiv(c, astr, ctLines, div, breakc, localPenX, localPenY, blockWidth);
				CGContextRestoreGState(c);
				if (storePen) *storePen = localPenY; // best-effort in rotated space
				continue;
			}

			breakc.breakCount = breakCount;
			breakc.breaks = breaks;
			if (drawTextBounds) {
				VisualizeLayoutLineHeights(c, ctLines, breaks, breakCount, div->styleLine->outlineRadius, penX, penY);
			}

			penY = DrawOneTextDiv(c, astr, ctLines, div, breakc, penX, penY, blockWidth);
			if (storePen) *storePen = penY;
		}
	}

	CGContextRestoreGState(c);
}

-(void)dealloc
{
	free(breakBuffer);
	CGColorSpaceRelease(srgbCSpace);
}

@end

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
