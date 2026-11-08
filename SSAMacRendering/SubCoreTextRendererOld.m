//
//  SubCoreTextRenderer.m
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#include <CoreText/CoreText.h>
#import "SubCoreTextRendererOld.h"
#import "SubImport.h"
#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"
#include "CommonUtils.h"
#import "Codecprintf.h"

#define declare_bitfield(name, bits) uint8_t name[bits / 8 + 1]; bzero(name, sizeof(name));
#define bitfield_set(name, bit) name[(bit) / 8] |= 1 << ((bit) % 8);
#define bitfield_test(name, bit) ((name[(bit) / 8] & (1 << ((bit) % 8))) != 0)

static void FindAllPossibleLineBreaks(NSString *line, uint8_t *breakOpportunities);


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
		srgbCSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		drawTextBounds = CFPreferencesGetAppBooleanValue(CFSTR("DrawSubTextBounds"), PERIAN_PREF_DOMAIN, NULL);
	}
	return self;
}

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
	SubTextLayerShadow,
	SubTextLayerOutline,
	SubTextLayerPrimary,
	SubTextLayerPrimaryUnstyled
};

static BOOL SetupCGForSpan(CGContextRef c, SubCoreTextSpanExtra *spanEx, SubCoreTextSpanExtra *lastSpanEx, SubRenderDiv *div, SubTextLayer textType, BOOL endLayer)
{
#define if_different(x) if (!lastSpanEx || lastSpanEx-> x != spanEx-> x)
	
	switch (textType) {
		case SubTextLayerShadow:
			if_different(shadowColor) {
				if (endLayer) {
					CGContextEndTransparencyLayer(c);
				}

				SetColor(c, fillc, spanEx->shadowColor);
				SetColor(c, strokec, spanEx->shadowColor);
				if (CGColorGetAlpha(spanEx->shadowColor) != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else {
					endLayer = NO;
				}
			}
			break;
			
		case SubTextLayerOutline:
			if_different(outlineRadius) {
				CGContextSetLineWidth(c, spanEx->outlineRadius ? (spanEx->outlineRadius*2. + .5) : 0.);
			}
			if_different(outlineColor) { 
				SetColor(c, (div->styleLine->borderStyle == kSubBorderStyleNormal) ? strokec : fillc, spanEx->outlineColor);
			}
			
			if_different(outlineAlpha) {
				if (endLayer) {
					CGContextEndTransparencyLayer(c);
				}
				CGContextSetAlpha(c, spanEx->outlineAlpha);
				if (spanEx->outlineAlpha != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else {
					endLayer = NO;
				}
			}
				
			break;
		case SubTextLayerPrimary:
			if_different(primaryColor) {
				SetColor(c, fillc, spanEx->primaryColor);
			}
			
			if_different(primaryAlpha) {
				if (endLayer) {
					CGContextEndTransparencyLayer(c);
				}

				CGContextSetAlpha(c, spanEx->primaryAlpha);
				if (spanEx->primaryAlpha != 1.) {
					endLayer = YES;
					CGContextBeginTransparencyLayer(c, NULL);
				} else {
					endLayer = NO;
				}
			}
			break;
			
		case SubTextLayerPrimaryUnstyled:
			break;
	}
	
	return endLayer;
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

	if (endLayer) {
		CGContextEndTransparencyLayer(c);
	}
}

typedef struct {
	UniCharArrayOffset *breaks;
	ItemCount breakCount;
	NSInteger lStart, lEnd;
	SInt8 direction;
} BreakContext;

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
			drawShapePart(c, path, div, firstSpanEx, SubTextLayerShadow);
		}
	}
	
	if (drawOutline) {
		if (clearOutlineInnerStroke) {
			CGContextBeginTransparencyLayer(c, NULL);
		}
		drawShapePart(c, path, div, firstSpanEx, SubTextLayerOutline);
		if (clearOutlineInnerStroke) {
			CGContextSetBlendMode(c, kCGBlendModeClear);
			drawShapePart(c, path, div, firstSpanEx, SubTextLayerPrimaryUnstyled);
			CGContextSetBlendMode(c, kCGBlendModeNormal);
			CGContextEndTransparencyLayer(c);
		}
	}
	
	drawShapePart(c, path, div, firstSpanEx, SubTextLayerPrimary);
	
	if (endLayer) {
		CGContextEndTransparencyLayer(c);
		CGContextSetShadowWithColor(c, CGSizeMake(0,0), 0, NULL);
	}
}

- (void)renderPacket:(NSString *)packet inContext:(CGContextRef)c size:(CGSize)size
{
	CGFloat bottomPen = 0, topPen = 0, centerPen = 0, *storePen=NULL;
	NSArray<SubRenderDiv*>* divs = SubParsePacket(packet, context, self);
	int32_t lastLayer = 0;

	CGContextSaveGState(c);
	if (size.width != videoWidth || size.height != videoHeight) {
		CGContextScaleCTM(c, size.width / videoWidth, size.height / videoHeight);
	}
	CGContextSetLineCap(c, kCGLineCapRound); // avoid spiky outlines on some fonts
	CGContextSetLineJoin(c, kCGLineJoinRound);
	CGContextSetShouldSmoothFonts(c, false); // don't do LCD subpixel antialiasing
	CGContextSetShouldSubpixelQuantizeFonts(c, false); // draw text stroke and fill in the same place
	
	for (SubRenderDiv *div1 in divs) {
		NSInteger textLen = [div1->text length];
		if (!textLen || ![div1->spans count]) {
			continue;
		}

		BOOL resetPens = NO, resetGState = NO;
		NSData *ubufferData;
		const unichar *ubuffer = SubUnicodeForString(div1->text, &ubufferData);
		
		if (div1->layer != lastLayer || div1->shouldResetPens) {
			resetPens = YES;
			lastLayer = div1->layer;
		}

		NSRect marginRect = NSMakeRect(div1->marginL, div1->marginV, context->resX - div1->marginL - div1->marginR, context->resY - div1->marginV - div1->marginV);
		
		marginRect.origin.x *= screenScaleX;
		marginRect.origin.y *= screenScaleY;
		marginRect.size.width  *= screenScaleX;
		marginRect.size.height *= screenScaleY;
		
		CGFloat penY = 0, penX = 0, breakingWidth = marginRect.size.width;
		BreakContext breakc = {0}; ItemCount breakCount=0;
#if 0
		// Step 1: Convert ATS text to UTF-8

		NSString *text = nil; // Your ATS text converted to a string

		// Step 2: Set up the font and layout attributes

		CTFontRef fontRef = nil; // Create a CTFont from your ATS font or header
		NSDictionary<NSAttributedStringKey, id> *attributes = @{NSFontNameAttribute: (__bridge id)fontRef};

		// Step 3: Create CTLine

		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedSubstringFromRange:NSMakeRange(0, [text length])];
		[attributedString appendAttributedString:[[ NSAttributedString alloc] initWithString:text attributes:attributes]];

		NSArray<CTLine *> lines = [attributedString lineByTrimmingLeadWhitespace];

		// Step 4: Set Baseline Offset

		if ([lines count] > 0) {
			CTLineRef firstLine = (__bridge CTLineRef)(lines[0]);
			CTFramesetterRef framesetterRef = NULL; // Create a CTFramesetter
			CTFramesetterSizedRunSize rangeSize = {0, [text length]};
			
			CGSize desiredSize = CGSizeMake(80.0f /* Your screen width */, 96.0f /* Your line height */); // Set your desired size
			
			CGRect frameRect;
			if ([lines count] == 1) {
				CTFramesetterSizedRun range = {rangeSize, [firstLine bounds].size};
				
				CTFramesetterAdvance framesetterAdvance = CTFrameSetterCreateWithFontAndText(framesetterRef, fontRef, &frameRect, nil);
				
				CGRect adjustedFrameRect;
				CGAffineTransform transformation = CGAffineTransformMakeScale(1.0f /* Scaling factor */, 1.0f /* Reverse scaling factor for vertical text */);
				
				CFTypesetterSizedRun frameSizeRange = {rangeSize, CGSizeMake(firstLine.bounds.size.width * desiredSize.height / firstLine.bounds.size.height, desiredSize.height)};
				
				CGAffineTransform frameTransform = CGAffineTransformMakeConcatenation(transformation, CGFramesetterFrameGetSize(framesetterAdvance)->ctFrame);
				CGSize textRectSize = CFAbsoluteValue(CGRectApplyAffineTransform(CGRectMake(0.0f, 0.0f, transformedFrameRect.width, transformedFrameRect.height), frameTransform).size);
				
				adjustedFrameRect = CGRectMake(adjustedBaselineOffset - textRectSize.width / 2.0f /* Centering baseline */ + firstLine.bounds.origin.x,
											  transformedFrameRect.origin.y - (textRectSize.height / 2.0f /* Middle alignment */
														),
											  transformedFrameRect.size.width,
											  desiredSize.height);
				
				frameTransform = CGAffineTransformMakeScale(1.0f /* Scaling factor */, 1.0f /* Reverse scaling factor for vertical text */);
				
				CGPathRef path = CGPathCreateWithEllipseInRect(CFRangeMake(adjustedBaselineOffset - firstLine.bounds.size.width / 2.0f, transformedFrameRect.origin.y), CGSizeMake(firstLine.bounds.size.width * desiredSize.height / firstLine.bounds.size.height, desiredSize.height));
				
				CGContextSaveGState(context);
				CGContextAddPath(context, path);
				CGContextSetFillColorWithColor(context, CGColorCreateGenericRGBA(1.0f /* Red */, 1.0f /* Green */, 1.0f /* Blue */, 0.1f /* Alpha */));
				CGContextStrokePath(context);
				CGContextRestoreGState(context);
				
			}

		}
#endif
		// Clean-up (if necessary)
		
//		ATSUSetTextPointerLocation(layout, ubuffer, kATSUFromTextBeginning, kATSUToTextEnd, textLen);
//		ATSUSetTransientFontMatching(layout,TRUE);
		
//		SetLayoutPositioning(layout, breakingWidth, div->alignH);
//		SetStyleSpanRuns(layout, div, ubuffer);
		
//		breakBuffer = FindLineBreaks(layout, div, breakLocator, breakBuffer, &breakCount, breakingWidth, ubuffer, textLen);

		CGFloat imageWidth = 0, imageHeight = 0, descent = 0;
//		UniCharArrayOffset *breaks = breakBuffer;
		
		if (div1->positioned || div1->alignV == kSubAlignmentMiddle) {
//			GetTypographicRectangleForLayout(layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), NULL, NULL, &imageHeight, &imageWidth);
		}
		
		if (div1->positioned || div1->alignV != kSubAlignmentTop) {
//			ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);
		}
		
#if 0
		{
			ATSUTextMeasurement ascent, descent;
			
			ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineAscentTag,  sizeof(ATSUTextMeasurement), &ascent,  NULL);
			ATSUGetLineControl(layout, kATSUFromTextBeginning, kATSULineDescentTag, sizeof(ATSUTextMeasurement), &descent, NULL);
			
			NSLog(@"\"%@\" descent %f ascent %f\n", div->text, FixedToFloat(descent), FixedToFloat(ascent));
		}
#endif
		
		if (!div1->positioned) {
			penX = NSMinX(marginRect);

			switch(div1->alignV) {
				case kSubAlignmentBottom: default:
					if (!bottomPen || resetPens) {
						penY = NSMinY(marginRect) + descent;
					} else {
						penY = bottomPen;
					}
					
					storePen = &bottomPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
					break;
				case kSubAlignmentMiddle:
					if (!centerPen || resetPens) {
						penY = NSMidY(marginRect) - (imageHeight / 2) + descent;
					} else {
						penY = centerPen;
					}
					
					storePen = &centerPen; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
					break;
				case kSubAlignmentTop:
					if (!topPen || resetPens) {
//						penY = NSMaxY(marginRect) - GetLineHeight(layout, kATSUFromTextBeginning, NO);
					} else {
						penY = topPen;
					}
					
					storePen = &topPen; breakc.lStart = 0; breakc.lEnd = breakCount+1; breakc.direction = -1;
					break;
			}
		} else {
			penX = div1->posX * screenScaleX;
			penY = (context->resY - div1->posY) * screenScaleY;
			
			switch (div1->alignH) {
				case kSubAlignmentCenter: penX -= imageWidth / 2; break;
				case kSubAlignmentRight: penX -= imageWidth; break;
				case kSubAlignmentLeft: break;
			}
			
			switch (div1->alignV) {
				case kSubAlignmentMiddle: penY -= imageHeight / 2; break;
				case kSubAlignmentTop: penY -= imageHeight; break;
				case kSubAlignmentBottom: break;
			}
			
			penY += descent;

//			SetLayoutPositioning(layout, imageWidth, div->alignH);
			storePen = NULL; breakc.lStart = breakCount; breakc.lEnd = -1; breakc.direction = 1;
		}
		
		SubRenderSpan *firstSpan = [div1->spans objectAtIndex:0];
		SubCoreTextSpanExtra *firstSpanEx = firstSpan.extra;

		if (div1->scale > 0) {
			CGContextSaveGState(c);
			//CGContextflip
			CGAffineTransform trans = CGAffineTransformMakeTranslation(div1->posX, div1->posY);
			CGFloat angle = firstSpanEx->angle;
			angle *= M_PI / 180.;
			trans = CGAffineTransformRotate(trans, angle);
			CGAffineTransform trans2 = CGAffineTransformMake(1, 0, 0, -1, 0, videoHeight * screenScaleY);
			CGContextConcatCTM(c, trans2);
			//CGContextScaleCTM(c, 1, videoHeight * screenScaleY);
			//CGContextTranslateCTM(c, div->posX, div->posY);
			CGPathRef pr = CreateSubParseSubShapesWithString(div1->text, &trans);
			
			drawShape(c, pr, div1, firstSpanEx);

			CGPathRelease(pr);
			CGContextRestoreGState(c);
		} else {
			// FIXME: we can only rotate an entire line at once
			if (firstSpanEx->angle) {
				CGFloat fangle = firstSpanEx->angle;
//				SetATSULayoutOther(layout, kATSULineRotationTag, sizeof(Fixed), &fangle);
				
				// FIXME: awful hack for SSA vertical text idiom
				// instead it needs to rotate text by hand or actually fix ATSUI's rotation origin
				if (firstSpanEx->vertical &&
					div1->alignV == kSubAlignmentMiddle && div1->alignH == kSubAlignmentCenter) {
					CGContextSaveGState(c);
					CGContextTranslateCTM(c, FixedToFloat(imageWidth)/2, FixedToFloat(imageWidth)/2);
					resetGState = YES;
				}
			}
		}
		
			if (drawTextBounds) {
//			VisualizeLayoutLineHeights(c, layout, breaks, breakCount, FloatToFixed(div->styleLine->outlineRadius), penX, penY, size.height);

		breakc.breakCount = breakCount;
//		breakc.breaks = breaks;
		
//		penY = DrawOneTextDiv(c, layout, div, breakc, penX, penY);
		}
		if (resetGState)
			CGContextRestoreGState(c);
		
		ubufferData = nil;
		if (storePen) *storePen = penY;

	}
	CGContextRestoreGState(c);
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
	if (s->weight == 1) {
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
	newFont = [[NSFontManager sharedFontManager] convertFont:newFont toSize:size];

	if (s->scaleX != 100. || s->scaleY != 100.) {
		NSAffineTransform*d = [NSAffineTransform transform];
		[d scaleXBy:s->scaleX / 100. yBy:s->scaleY / 100.];
		NSFontDescriptor *descriptor = [newFont fontDescriptor];
		
		newFont = [NSFont fontWithDescriptor:descriptor textTransform:d];
	}

	dict[(NSString*)kCTFontAttributeName] = newFont;
	
	if (s->tracking > 0) { // bug in VSFilter: negative tracking in style lines is ignored
		float tracking = s->tracking;
		
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
	renderMultipleParts = 1, //!< Call ATSUDrawText more than once, needed for color/border changes in the middle of lines
	renderManualShadows = 2, //!< CG shadows can't change inside a line... probably
	renderComplexTransforms = 4 //!< Can't draw text at all, have to transform each vertex. needed for 3D perspective, or \frz in the middle of a line
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
			Codecprintf(NULL, "Unimplemented SSA tag '2c'\n");
			CGColorRelease(color);
			break;
		case tag_2a:
			colorv();
			Codecprintf(NULL, "Unimplemented SSA tag '2a'\n");
			CGColorRelease(color);
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
		case tag_fade:
			Codecprintf(NULL, "Unimplemented SSA tag 'fade'\n");
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
