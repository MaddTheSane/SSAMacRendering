
#line 1 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
/*
 * SubParsing.m.rl
 * Created by Alexander Strange on 7/25/07.
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

/*
 * Parsing of SSA/ASS subtitle files using Ragel.
 * At the moment, all subtitle formats supported by Perian
 * are converted to SSA before reaching here.
 * Feel free to implement new file formats as Ragel parsers here
 * if it ends up cleaner than doing it by hand.
 *
 * SSA specification (as it exists):
 * http://google.com/codesearch/p?hl=en#_g4u1OIsR_M/trunk/src/subtitles/STS.cpp&q=package:vsfilter%20%22v4%22&sa=N&cd=7&ct=rc&l=1395
 * http://moodub.free.fr/video/ass-specs.doc 
 *
 * FIXME:
 * - Files which can't be parsed have no clear error messages.
 * - Line and section names are case-insensitive in VSFilter, but we
 *   assume they are capitalized as in Aegisub.
 * - SSA v4.00++ is not supported.
 */

#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"
#import "SubContext.h"
#import "Codecprintf.h"


#line 47 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

#line 52 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
static const char _SSAfile_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 2, 0, 1, 
	2, 0, 2, 2, 1, 3, 3, 0, 
	1, 3
};

static const short _SSAfile_key_offsets[] = {
	0, 0, 2, 4, 5, 6, 7, 8, 
	9, 10, 12, 13, 14, 15, 16, 22, 
	26, 29, 35, 37, 42, 46, 51, 56, 
	60, 64, 68, 72, 76, 80, 87, 94, 
	97, 103, 105, 109, 113, 117, 121, 124, 
	130, 132, 139, 143, 147, 151, 155, 159, 
	163, 170, 177, 180, 186, 188, 192, 196, 
	200, 204, 208, 212, 216, 219, 225, 227, 
	231, 235, 239, 243, 246, 252, 254, 261, 
	265, 269, 273, 277, 281, 285, 292, 296, 
	301, 306, 310, 314, 318, 322, 326, 330, 
	337, 341, 345, 350, 355, 359, 363, 367, 
	371, 375, 379, 386, 390, 394, 395, 400
};

static const unsigned short _SSAfile_trans_keys[] = {
	91u, 65279u, 83u, 115u, 99u, 114u, 105u, 112u, 
	116u, 32u, 73u, 105u, 110u, 102u, 111u, 93u, 
	10u, 13u, 32u, 160u, 9u, 12u, 10u, 13u, 
	58u, 91u, 10u, 13u, 58u, 10u, 13u, 32u, 
	160u, 9u, 12u, 10u, 13u, 10u, 13u, 58u, 
	86u, 118u, 10u, 13u, 52u, 58u, 10u, 13u, 
	32u, 43u, 58u, 10u, 13u, 58u, 83u, 115u, 
	10u, 13u, 58u, 116u, 10u, 13u, 58u, 121u, 
	10u, 13u, 58u, 108u, 10u, 13u, 58u, 101u, 
	10u, 13u, 58u, 115u, 10u, 13u, 58u, 93u, 
	10u, 13u, 32u, 58u, 160u, 9u, 12u, 10u, 
	13u, 32u, 58u, 160u, 9u, 12u, 10u, 13u, 
	58u, 10u, 13u, 32u, 160u, 9u, 12u, 10u, 
	13u, 10u, 13u, 58u, 116u, 10u, 13u, 58u, 
	121u, 10u, 13u, 58u, 108u, 10u, 13u, 58u, 
	101u, 10u, 13u, 58u, 10u, 13u, 32u, 160u, 
	9u, 12u, 10u, 13u, 10u, 13u, 58u, 69u, 
	86u, 101u, 118u, 10u, 13u, 58u, 118u, 10u, 
	13u, 58u, 101u, 10u, 13u, 58u, 110u, 10u, 
	13u, 58u, 116u, 10u, 13u, 58u, 115u, 10u, 
	13u, 58u, 93u, 10u, 13u, 32u, 58u, 160u, 
	9u, 12u, 10u, 13u, 32u, 58u, 160u, 9u, 
	12u, 10u, 13u, 58u, 10u, 13u, 32u, 160u, 
	9u, 12u, 10u, 13u, 10u, 13u, 58u, 105u, 
	10u, 13u, 58u, 97u, 10u, 13u, 58u, 108u, 
	10u, 13u, 58u, 111u, 10u, 13u, 58u, 103u, 
	10u, 13u, 58u, 117u, 10u, 13u, 58u, 101u, 
	10u, 13u, 58u, 10u, 13u, 32u, 160u, 9u, 
	12u, 10u, 13u, 10u, 13u, 58u, 116u, 10u, 
	13u, 58u, 121u, 10u, 13u, 58u, 108u, 10u, 
	13u, 58u, 101u, 10u, 13u, 58u, 10u, 13u, 
	32u, 160u, 9u, 12u, 10u, 13u, 10u, 13u, 
	58u, 69u, 86u, 101u, 118u, 10u, 13u, 58u, 
	118u, 10u, 13u, 58u, 101u, 10u, 13u, 58u, 
	110u, 10u, 13u, 58u, 116u, 10u, 13u, 58u, 
	115u, 10u, 13u, 58u, 93u, 10u, 13u, 32u, 
	58u, 160u, 9u, 12u, 10u, 13u, 52u, 58u, 
	10u, 13u, 32u, 43u, 58u, 10u, 13u, 58u, 
	83u, 115u, 10u, 13u, 58u, 116u, 10u, 13u, 
	58u, 121u, 10u, 13u, 58u, 108u, 10u, 13u, 
	58u, 101u, 10u, 13u, 58u, 115u, 10u, 13u, 
	58u, 93u, 10u, 13u, 32u, 58u, 160u, 9u, 
	12u, 10u, 13u, 32u, 58u, 10u, 13u, 52u, 
	58u, 10u, 13u, 32u, 43u, 58u, 10u, 13u, 
	58u, 83u, 115u, 10u, 13u, 58u, 116u, 10u, 
	13u, 58u, 121u, 10u, 13u, 58u, 108u, 10u, 
	13u, 58u, 101u, 10u, 13u, 58u, 115u, 10u, 
	13u, 58u, 93u, 10u, 13u, 32u, 58u, 160u, 
	9u, 12u, 10u, 13u, 32u, 58u, 10u, 13u, 
	32u, 58u, 91u, 10u, 13u, 58u, 83u, 91u, 
	10u, 13u, 58u, 68u, 83u, 91u, 0
};

static const char _SSAfile_single_lengths[] = {
	0, 2, 2, 1, 1, 1, 1, 1, 
	1, 2, 1, 1, 1, 1, 4, 4, 
	3, 4, 2, 5, 4, 5, 5, 4, 
	4, 4, 4, 4, 4, 5, 5, 3, 
	4, 2, 4, 4, 4, 4, 3, 4, 
	2, 7, 4, 4, 4, 4, 4, 4, 
	5, 5, 3, 4, 2, 4, 4, 4, 
	4, 4, 4, 4, 3, 4, 2, 4, 
	4, 4, 4, 3, 4, 2, 7, 4, 
	4, 4, 4, 4, 4, 5, 4, 5, 
	5, 4, 4, 4, 4, 4, 4, 5, 
	4, 4, 5, 5, 4, 4, 4, 4, 
	4, 4, 5, 4, 4, 1, 5, 6
};

static const char _SSAfile_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 1, 0, 
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 0, 
	1, 0, 0, 0, 0, 0, 0, 1, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 0, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 0, 0, 
	0, 0, 0, 0, 1, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 1, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 0, 0, 0, 0
};

static const short _SSAfile_index_offsets[] = {
	0, 0, 3, 6, 8, 10, 12, 14, 
	16, 18, 21, 23, 25, 27, 29, 35, 
	40, 44, 50, 53, 59, 64, 70, 76, 
	81, 86, 91, 96, 101, 106, 113, 120, 
	124, 130, 133, 138, 143, 148, 153, 157, 
	163, 166, 174, 179, 184, 189, 194, 199, 
	204, 211, 218, 222, 228, 231, 236, 241, 
	246, 251, 256, 261, 266, 270, 276, 279, 
	284, 289, 294, 299, 303, 309, 312, 320, 
	325, 330, 335, 340, 345, 350, 357, 362, 
	368, 374, 379, 384, 389, 394, 399, 404, 
	411, 416, 421, 427, 433, 438, 443, 448, 
	453, 458, 463, 470, 475, 480, 482, 488
};

static const unsigned char _SSAfile_indicies[] = {
	0, 2, 1, 3, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 10, 1, 11, 1, 12, 
	1, 13, 1, 14, 1, 15, 15, 14, 
	14, 14, 1, 15, 15, 17, 18, 16, 
	15, 15, 20, 19, 23, 23, 22, 22, 
	22, 21, 25, 25, 24, 15, 15, 20, 
	26, 26, 19, 15, 15, 27, 20, 19, 
	15, 15, 28, 29, 20, 19, 15, 15, 
	20, 30, 30, 19, 15, 15, 20, 31, 
	19, 15, 15, 20, 32, 19, 15, 15, 
	20, 33, 19, 15, 15, 20, 34, 19, 
	15, 15, 20, 35, 19, 15, 15, 20, 
	36, 19, 38, 38, 37, 20, 37, 37, 
	19, 40, 40, 39, 20, 39, 39, 19, 
	40, 40, 42, 41, 45, 45, 44, 44, 
	44, 43, 47, 47, 46, 40, 40, 42, 
	48, 41, 40, 40, 42, 49, 41, 40, 
	40, 42, 50, 41, 40, 40, 42, 51, 
	41, 40, 40, 52, 41, 55, 55, 54, 
	54, 54, 53, 57, 57, 56, 40, 40, 
	42, 58, 59, 58, 59, 41, 40, 40, 
	42, 60, 41, 40, 40, 42, 61, 41, 
	40, 40, 42, 62, 41, 40, 40, 42, 
	63, 41, 40, 40, 42, 64, 41, 40, 
	40, 42, 65, 41, 67, 67, 66, 42, 
	66, 66, 41, 69, 69, 68, 42, 68, 
	68, 41, 69, 69, 71, 70, 74, 74, 
	73, 73, 73, 72, 76, 76, 75, 69, 
	69, 71, 77, 70, 69, 69, 71, 78, 
	70, 69, 69, 71, 79, 70, 69, 69, 
	71, 80, 70, 69, 69, 71, 81, 70, 
	69, 69, 71, 82, 70, 69, 69, 71, 
	83, 70, 69, 69, 84, 70, 87, 87, 
	86, 86, 86, 85, 89, 89, 88, 69, 
	69, 71, 90, 70, 69, 69, 71, 91, 
	70, 69, 69, 71, 92, 70, 69, 69, 
	71, 93, 70, 69, 69, 94, 70, 87, 
	87, 96, 96, 96, 95, 89, 89, 97, 
	69, 69, 71, 98, 99, 98, 99, 70, 
	69, 69, 71, 100, 70, 69, 69, 71, 
	101, 70, 69, 69, 71, 102, 70, 69, 
	69, 71, 103, 70, 69, 69, 71, 104, 
	70, 69, 69, 71, 105, 70, 67, 67, 
	106, 71, 106, 106, 70, 69, 69, 107, 
	71, 70, 69, 69, 108, 109, 71, 70, 
	69, 69, 71, 110, 110, 70, 69, 69, 
	71, 111, 70, 69, 69, 71, 112, 70, 
	69, 69, 71, 113, 70, 69, 69, 71, 
	114, 70, 69, 69, 71, 115, 70, 69, 
	69, 71, 116, 70, 118, 118, 117, 71, 
	117, 117, 70, 69, 69, 108, 71, 70, 
	40, 40, 119, 42, 41, 40, 40, 120, 
	121, 42, 41, 40, 40, 42, 122, 122, 
	41, 40, 40, 42, 123, 41, 40, 40, 
	42, 124, 41, 40, 40, 42, 125, 41, 
	40, 40, 42, 126, 41, 40, 40, 42, 
	127, 41, 40, 40, 42, 128, 41, 38, 
	38, 129, 42, 129, 129, 41, 40, 40, 
	120, 42, 41, 15, 15, 28, 20, 19, 
	0, 1, 40, 40, 131, 132, 133, 130, 
	69, 69, 135, 136, 137, 138, 134, 0
};

static const char _SSAfile_trans_targs[] = {
	2, 0, 101, 3, 4, 5, 6, 7, 
	8, 9, 10, 11, 12, 13, 14, 15, 
	16, 17, 19, 16, 17, 18, 17, 15, 
	18, 15, 20, 21, 22, 100, 23, 24, 
	25, 26, 27, 28, 29, 30, 102, 30, 
	102, 31, 32, 33, 32, 102, 33, 102, 
	35, 36, 37, 38, 39, 40, 39, 102, 
	40, 102, 42, 89, 43, 44, 45, 46, 
	47, 48, 49, 103, 49, 103, 50, 51, 
	52, 51, 103, 52, 103, 54, 55, 56, 
	57, 58, 59, 60, 61, 62, 61, 103, 
	62, 103, 64, 65, 66, 67, 68, 69, 
	68, 69, 71, 78, 72, 73, 74, 75, 
	76, 77, 50, 79, 80, 88, 81, 82, 
	83, 84, 85, 86, 87, 50, 103, 90, 
	91, 99, 92, 93, 94, 95, 96, 97, 
	98, 31, 31, 32, 34, 41, 50, 51, 
	53, 63, 70
};

static const char _SSAfile_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 16, 1, 0, 5, 1, 1, 13, 
	0, 3, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 9, 0, 
	0, 0, 5, 1, 1, 13, 0, 3, 
	0, 0, 0, 0, 5, 1, 1, 22, 
	0, 19, 0, 0, 0, 0, 0, 0, 
	0, 0, 11, 11, 0, 0, 0, 5, 
	1, 1, 13, 0, 3, 0, 0, 0, 
	0, 0, 0, 0, 5, 1, 1, 22, 
	0, 19, 0, 0, 0, 0, 5, 1, 
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 11, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 9, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 9, 1, 16, 1, 1, 1, 16, 
	1, 1, 1
};

static const char _SSAfile_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 7, 7, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0
};

static const int SSAfile_start = 1;
static const int SSAfile_first_final = 102;
static const int SSAfile_error = 0;

static const int SSAfile_en_main = 1;


#line 48 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

SubRGBAColor SubParseSSAColor(unsigned rgb)
{
	unsigned char r, g, b, a;
	
	a = (rgb >> 24) & 0xff;
	b = (rgb >> 16) & 0xff;
	g = (rgb >> 8) & 0xff;
	r = rgb & 0xff;
	
	a = 255-a;
	
	return (SubRGBAColor){r/255.,g/255.,b/255.,a/255.};
}

SubRGBAColor SubParseSSAColorString(NSString *c)
{
	const char *c_ = [c UTF8String];
	unsigned int rgb;
	
	if (c_[0] == '&') {
		rgb = (unsigned int)strtoul(&c_[2],NULL,16);
	} else {
		rgb = (unsigned int)strtol(c_,NULL,0);
	}
	
	return SubParseSSAColor(rgb);
}

UInt8 SubASSFromSSAAlignment(UInt8 a)
{
    int h = 1, v = 0;
	if (a >= 9 && a <= 11) {v = kSubAlignmentMiddle; h = a-8;}
	if (a >= 5 && a <= 7)  {v = kSubAlignmentTop;    h = a-4;}
	if (a >= 1 && a <= 3)  {v = kSubAlignmentBottom; h = a;}
	return v * 3 + h;
}

void SubParseASSAlignment(UInt8 a, UInt8 *alignH, UInt8 *alignV)
{
	switch (a) {
		case 4 ... 6: *alignV = kSubAlignmentMiddle; break;
		case 7 ... 9: *alignV = kSubAlignmentTop; break;
		default: case 1 ... 3: *alignV = kSubAlignmentBottom; break;
	}
	
	switch (a) {
		case 1: case 4: case 7: *alignH = kSubAlignmentLeft; break;
		case 3: case 6: case 9: *alignH = kSubAlignmentRight; break;
		default: case 2: case 5: case 8: *alignH = kSubAlignmentCenter; break;
	}
}

BOOL SubParseFontVerticality(NSString **fontname)
{
	if ([*fontname length] && [*fontname characterAtIndex:0] == '@') {
		*fontname = [*fontname substringFromIndex:1];
		return YES;
	}
	return NO;
}

@implementation SubRenderSpan
-(SubRenderSpan*)copyWithZone:(NSZone*)zone
{
	SubRenderSpan *span = [[SubRenderSpan alloc] init];
	span->offset = offset;
	span.extra   = [extra copy];
	return span;
}

@synthesize extra;

-(NSString*)description
{
	return [NSString stringWithFormat:@"Span at %ld: %@", offset, extra];
}
@end

@implementation SubRenderDiv
@synthesize text;
@synthesize styleLine;
@synthesize spans;
@synthesize posX;
@synthesize posY;
@synthesize leftMargin = marginL;
@synthesize rightMargin = marginR;
@synthesize verticalMargin = marginV;
@synthesize layer;
@synthesize alignH;
@synthesize alignV;
@synthesize wrapStyle;
@synthesize renderComplexity = render_complexity;
@synthesize positioned;
@synthesize shouldResetPens;

-(NSString*)description
{
	NSInteger i, sc = [spans count];
	NSMutableString *tmp = [NSMutableString stringWithFormat:@"div \"%@\" with %ld spans:", text, (long)sc];
	for (i = 0; i < sc; i++) {[tmp appendFormat:@" %ld",((SubRenderSpan*)[spans objectAtIndex:i])->offset];}
	[tmp appendFormat:@" %lu", (unsigned long)[text length]];
	return tmp;
}

-(SubRenderDiv*)init
{
	if (self = [super init]) {
		text      = nil;
		styleLine = nil;
		marginL   = marginR = marginV = layer = 0;
		spans     = nil;
		
		posX   = posY = 0;
		alignH = kSubAlignmentCenter; alignV = kSubAlignmentBottom;
		
		positioned = NO;
		render_complexity = 0;
	}
	
	return self;
}

@end

extern BOOL IsScriptASS(NSDictionary *headers);

static NSArray<NSDictionary<NSString*,NSString*>*> *SplitByFormat(NSString *format, NSArray<NSString*> *lines)
{
	NSArray *formarray = SubSplitStringIgnoringWhitespace(format,@",");
	NSInteger numlines = [lines count], numfields = [formarray count];
	NSMutableArray *ar = [NSMutableArray arrayWithCapacity:numlines];
	
	for (NSString *s in lines) {
		NSArray *splitline = SubSplitStringWithCount(s, @",", numfields);
		
		if ([splitline count] != numfields) continue;
		[ar addObject:[NSDictionary dictionaryWithObjects:splitline
												  forKeys:formarray]];
	}
	
	return ar;
}

void SubParseSSAFile(NSString *ssastr, NSDictionary<NSString*,NSString*> **headers, NSArray<NSDictionary<NSString*,NSString*>*> **styles, NSArray<NSDictionary<NSString*,NSString*>*> **subs)
{
	NSInteger len = [ssastr length];
	NSData *ssaData;
	const unichar *ssa = SubUnicodeForString(ssastr, &ssaData);
	NSMutableDictionary *headerdict = [NSMutableDictionary dictionary];
	NSMutableArray *stylearr = [NSMutableArray array], *eventarr = [NSMutableArray array], *cur_array=NULL;
	NSCharacterSet *wcs = [NSCharacterSet whitespaceCharacterSet];
	NSString *str=NULL, *styleformat=NULL, *eventformat=NULL;
	BOOL is_ass = NO;
	
	const unichar *p = ssa, *pe = ssa + len, *strbegin = p;
	int cs=0;
	
#define send() [[NSString alloc] initWithCharactersNoCopy:(unichar*)strbegin length:p-strbegin freeWhenDone:NO]
	
	
#line 248 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

		
	
#line 474 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
	{
	cs = SSAfile_start;
	}

#line 251 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	
#line 481 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const unsigned short *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _SSAfile_trans_keys + _SSAfile_key_offsets[cs];
	_trans = _SSAfile_index_offsets[cs];

	_klen = _SSAfile_single_lengths[cs];
	if ( _klen > 0 ) {
		const unsigned short *_lower = _keys;
		const unsigned short *_mid;
		const unsigned short *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _SSAfile_range_lengths[cs];
	if ( _klen > 0 ) {
		const unsigned short *_lower = _keys;
		const unsigned short *_mid;
		const unsigned short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _SSAfile_indicies[_trans];
	cs = _SSAfile_trans_targs[_trans];

	if ( _SSAfile_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _SSAfile_actions + _SSAfile_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 211 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{strbegin = p;}
	break;
	case 1:
#line 212 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{[headerdict setObject:send() forKey:str];}
	break;
	case 2:
#line 213 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{str = send();}
	break;
	case 3:
#line 214 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{[cur_array addObject:[send() stringByTrimmingCharactersInSet:wcs]];}
	break;
	case 4:
#line 215 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
			cur_array=stylearr;
			is_ass = IsScriptASS(headerdict);
			styleformat = is_ass ?
				@"Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"
			   :@"Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding";
		}
	break;
	case 5:
#line 222 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
			cur_array=eventarr;
			eventformat = is_ass ?
				@"Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
			   :@"Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text";
		}
	break;
#line 590 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	const char *__acts = _SSAfile_actions + _SSAfile_eof_actions[cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 3:
#line 214 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{[cur_array addObject:[send() stringByTrimmingCharactersInSet:wcs]];}
	break;
#line 610 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
		}
	}
	}

	_out: {}
	}

#line 252 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	//%%write eof;

	ssaData = nil;

	*headers = headerdict;
	if (styles) *styles = SplitByFormat(styleformat, stylearr);
	if (subs) *subs = SplitByFormat(eventformat, eventarr);
}


#line 262 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

#line 631 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
static const char _SSAtag_actions[] = {
	0, 1, 12, 1, 13, 1, 14, 1, 
	15, 1, 16, 1, 17, 1, 18, 1, 
	19, 1, 20, 1, 23, 1, 24, 1, 
	25, 1, 26, 1, 34, 1, 35, 1, 
	36, 1, 37, 2, 12, 37, 2, 13, 
	37, 2, 14, 37, 2, 15, 37, 2, 
	16, 37, 2, 17, 37, 2, 18, 37, 
	2, 19, 37, 2, 20, 37, 2, 24, 
	0, 2, 24, 1, 2, 24, 2, 2, 
	24, 3, 2, 24, 30, 2, 24, 31, 
	2, 24, 32, 2, 24, 37, 2, 25, 
	12, 2, 25, 13, 2, 25, 14, 2, 
	25, 15, 2, 25, 16, 2, 25, 17, 
	2, 25, 18, 2, 25, 19, 2, 25, 
	20, 2, 26, 4, 2, 26, 5, 2, 
	26, 7, 2, 26, 8, 2, 26, 9, 
	2, 26, 10, 2, 26, 11, 2, 26, 
	22, 2, 26, 37, 2, 27, 6, 2, 
	27, 21, 2, 28, 6, 2, 28, 21, 
	2, 29, 33, 2, 34, 37, 3, 24, 
	0, 37, 3, 24, 1, 37, 3, 24, 
	2, 37, 3, 24, 3, 37, 3, 24, 
	30, 37, 3, 24, 31, 37, 3, 24, 
	32, 37, 3, 25, 12, 37, 3, 25, 
	13, 37, 3, 25, 14, 37, 3, 25, 
	15, 37, 3, 25, 16, 37, 3, 25, 
	17, 37, 3, 25, 18, 37, 3, 25, 
	19, 37, 3, 25, 20, 37, 3, 26, 
	4, 37, 3, 26, 5, 37, 3, 26, 
	7, 37, 3, 26, 8, 37, 3, 26, 
	9, 37, 3, 26, 10, 37, 3, 26, 
	11, 37, 3, 26, 22, 37, 3, 27, 
	6, 37, 3, 27, 21, 37, 3, 28, 
	6, 37, 3, 28, 21, 37, 3, 29, 
	33, 37
};

static const short _SSAtag_key_offsets[] = {
	0, 2, 3, 25, 28, 37, 46, 53, 
	62, 64, 73, 82, 89, 98, 100, 103, 
	112, 121, 128, 137, 139, 148, 157, 164, 
	173, 175, 178, 187, 196, 203, 212, 214, 
	223, 232, 239, 248, 250, 253, 262, 271, 
	278, 287, 289, 298, 307, 314, 323, 325, 
	331, 334, 338, 342, 348, 351, 355, 357, 
	359, 361, 370, 379, 386, 395, 397, 401, 
	404, 408, 415, 418, 422, 427, 430, 435, 
	439, 442, 444, 446, 448, 450, 455, 458, 
	463, 467, 470, 480, 482, 484, 486, 488, 
	494, 498, 501, 503, 505, 513, 516, 521, 
	525, 528, 533, 540, 543, 548, 552, 555, 
	558, 563, 566, 571, 575, 578, 583, 586, 
	591, 595, 598, 603, 606, 611, 615, 618, 
	622, 624, 626, 628, 630, 632, 634, 639, 
	642, 647, 652, 655, 660, 665, 668, 673, 
	678, 681, 687, 689, 694, 697, 703, 708, 
	711, 716, 720, 723, 728, 731, 736, 739, 
	743, 746, 750, 753, 757, 760, 762, 764, 
	766, 768, 770, 777, 780, 785, 789, 792, 
	794, 796, 798, 803, 806, 811, 815, 818, 
	822, 825, 829, 831, 833, 837, 839, 841, 
	843, 848, 851, 856, 860, 863, 866, 868, 
	871, 873, 875, 877, 879, 881, 883
};

static const char _SSAtag_trans_keys[] = {
	92, 125, 125, 49, 50, 51, 52, 75, 
	97, 98, 99, 102, 105, 107, 109, 111, 
	112, 113, 114, 115, 116, 117, 125, 120, 
	121, 97, 99, 125, 38, 72, 125, 48, 
	57, 65, 70, 97, 102, 38, 72, 125, 
	48, 57, 65, 70, 97, 102, 125, 48, 
	57, 65, 70, 97, 102, 38, 92, 125, 
	48, 57, 65, 70, 97, 102, 92, 125, 
	38, 72, 125, 48, 57, 65, 70, 97, 
	102, 38, 72, 125, 48, 57, 65, 70, 
	97, 102, 125, 48, 57, 65, 70, 97, 
	102, 38, 92, 125, 48, 57, 65, 70, 
	97, 102, 92, 125, 97, 99, 125, 38, 
	72, 125, 48, 57, 65, 70, 97, 102, 
	38, 72, 125, 48, 57, 65, 70, 97, 
	102, 125, 48, 57, 65, 70, 97, 102, 
	38, 92, 125, 48, 57, 65, 70, 97, 
	102, 92, 125, 38, 72, 125, 48, 57, 
	65, 70, 97, 102, 38, 72, 125, 48, 
	57, 65, 70, 97, 102, 125, 48, 57, 
	65, 70, 97, 102, 38, 92, 125, 48, 
	57, 65, 70, 97, 102, 92, 125, 97, 
	99, 125, 38, 72, 125, 48, 57, 65, 
	70, 97, 102, 38, 72, 125, 48, 57, 
	65, 70, 97, 102, 125, 48, 57, 65, 
	70, 97, 102, 38, 92, 125, 48, 57, 
	65, 70, 97, 102, 92, 125, 38, 72, 
	125, 48, 57, 65, 70, 97, 102, 38, 
	72, 125, 48, 57, 65, 70, 97, 102, 
	125, 48, 57, 65, 70, 97, 102, 38, 
	92, 125, 48, 57, 65, 70, 97, 102, 
	92, 125, 97, 99, 125, 38, 72, 125, 
	48, 57, 65, 70, 97, 102, 38, 72, 
	125, 48, 57, 65, 70, 97, 102, 125, 
	48, 57, 65, 70, 97, 102, 38, 92, 
	125, 48, 57, 65, 70, 97, 102, 92, 
	125, 38, 72, 125, 48, 57, 65, 70, 
	97, 102, 38, 72, 125, 48, 57, 65, 
	70, 97, 102, 125, 48, 57, 65, 70, 
	97, 102, 38, 92, 125, 48, 57, 65, 
	70, 97, 102, 92, 125, 45, 102, 111, 
	125, 48, 57, 125, 48, 57, 92, 125, 
	48, 57, 45, 125, 48, 57, 45, 108, 
	110, 125, 48, 57, 125, 48, 57, 92, 
	125, 48, 57, 112, 125, 104, 125, 97, 
	125, 38, 72, 125, 48, 57, 65, 70, 
	97, 102, 38, 72, 125, 48, 57, 65, 
	70, 97, 102, 125, 48, 57, 65, 70, 
	97, 102, 38, 92, 125, 48, 57, 65, 
	70, 97, 102, 92, 125, 45, 125, 48, 
	57, 125, 48, 57, 92, 125, 48, 57, 
	45, 101, 108, 111, 125, 48, 57, 125, 
	48, 57, 92, 125, 48, 57, 45, 46, 
	125, 48, 57, 125, 48, 57, 46, 92, 
	125, 48, 57, 92, 125, 48, 57, 125, 
	48, 57, 117, 125, 114, 125, 114, 125, 
	100, 125, 45, 46, 125, 48, 57, 125, 
	48, 57, 46, 92, 125, 48, 57, 92, 
	125, 48, 57, 125, 48, 57, 38, 72, 
	108, 125, 48, 57, 65, 70, 97, 102, 
	105, 125, 112, 125, 40, 125, 41, 125, 
	97, 101, 110, 114, 115, 125, 100, 125, 
	120, 121, 40, 101, 125, 92, 125, 92, 
	125, 45, 46, 122, 125, 48, 57, 120, 
	121, 125, 48, 57, 46, 92, 125, 48, 
	57, 92, 125, 48, 57, 125, 48, 57, 
	45, 46, 125, 48, 57, 45, 46, 99, 
	112, 125, 48, 57, 125, 48, 57, 46, 
	92, 125, 48, 57, 92, 125, 48, 57, 
	125, 48, 57, 120, 121, 125, 45, 46, 
	125, 48, 57, 125, 48, 57, 46, 92, 
	125, 48, 57, 92, 125, 48, 57, 125, 
	48, 57, 45, 46, 125, 48, 57, 125, 
	48, 57, 46, 92, 125, 48, 57, 92, 
	125, 48, 57, 125, 48, 57, 45, 46, 
	125, 48, 57, 125, 48, 57, 46, 92, 
	125, 48, 57, 92, 125, 48, 57, 125, 
	48, 57, 99, 125, 48, 49, 92, 125, 
	108, 125, 111, 125, 118, 125, 101, 125, 
	40, 125, 45, 46, 125, 48, 57, 125, 
	48, 57, 44, 46, 125, 48, 57, 45, 
	46, 125, 48, 57, 125, 48, 57, 44, 
	46, 125, 48, 57, 45, 46, 125, 48, 
	57, 125, 48, 57, 44, 46, 125, 48, 
	57, 45, 46, 125, 48, 57, 125, 48, 
	57, 41, 44, 46, 125, 48, 57, 92, 
	125, 45, 46, 125, 48, 57, 125, 48, 
	57, 41, 44, 46, 125, 48, 57, 45, 
	46, 125, 48, 57, 125, 48, 57, 41, 
	46, 125, 48, 57, 41, 125, 48, 57, 
	125, 48, 57, 41, 44, 125, 48, 57, 
	125, 48, 57, 41, 44, 125, 48, 57, 
	125, 48, 57, 44, 125, 48, 57, 125, 
	48, 57, 44, 125, 48, 57, 125, 48, 
	57, 44, 125, 48, 57, 125, 48, 57, 
	114, 125, 103, 125, 40, 125, 41, 125, 
	92, 125, 45, 46, 98, 111, 125, 48, 
	57, 125, 48, 57, 46, 92, 125, 48, 
	57, 92, 125, 48, 57, 125, 48, 57, 
	111, 125, 115, 125, 40, 125, 45, 46, 
	125, 48, 57, 125, 48, 57, 44, 46, 
	125, 48, 57, 44, 125, 48, 57, 125, 
	48, 57, 45, 125, 48, 57, 125, 48, 
	57, 92, 125, 48, 57, 92, 125, 92, 
	125, 104, 125, 48, 49, 92, 125, 97, 
	125, 100, 125, 45, 46, 125, 48, 57, 
	125, 48, 57, 46, 92, 125, 48, 57, 
	92, 125, 48, 57, 125, 48, 57, 125, 
	48, 49, 92, 125, 98, 115, 125, 111, 
	125, 114, 125, 100, 125, 104, 125, 97, 
	125, 92, 123, 0
};

static const char _SSAtag_single_lengths[] = {
	2, 1, 20, 3, 3, 3, 1, 3, 
	2, 3, 3, 1, 3, 2, 3, 3, 
	3, 1, 3, 2, 3, 3, 1, 3, 
	2, 3, 3, 3, 1, 3, 2, 3, 
	3, 1, 3, 2, 3, 3, 3, 1, 
	3, 2, 3, 3, 1, 3, 2, 4, 
	1, 2, 2, 4, 1, 2, 2, 2, 
	2, 3, 3, 1, 3, 2, 2, 1, 
	2, 5, 1, 2, 3, 1, 3, 2, 
	1, 2, 2, 2, 2, 3, 1, 3, 
	2, 1, 4, 2, 2, 2, 2, 6, 
	2, 3, 2, 2, 4, 1, 3, 2, 
	1, 3, 5, 1, 3, 2, 1, 3, 
	3, 1, 3, 2, 1, 3, 1, 3, 
	2, 1, 3, 1, 3, 2, 1, 2, 
	2, 2, 2, 2, 2, 2, 3, 1, 
	3, 3, 1, 3, 3, 1, 3, 3, 
	1, 4, 2, 3, 1, 4, 3, 1, 
	3, 2, 1, 3, 1, 3, 1, 2, 
	1, 2, 1, 2, 1, 2, 2, 2, 
	2, 2, 5, 1, 3, 2, 1, 2, 
	2, 2, 3, 1, 3, 2, 1, 2, 
	1, 2, 2, 2, 2, 2, 2, 2, 
	3, 1, 3, 2, 1, 1, 2, 3, 
	2, 2, 2, 2, 2, 2, 0
};

static const char _SSAtag_range_lengths[] = {
	0, 0, 1, 0, 3, 3, 3, 3, 
	0, 3, 3, 3, 3, 0, 0, 3, 
	3, 3, 3, 0, 3, 3, 3, 3, 
	0, 0, 3, 3, 3, 3, 0, 3, 
	3, 3, 3, 0, 0, 3, 3, 3, 
	3, 0, 3, 3, 3, 3, 0, 1, 
	1, 1, 1, 1, 1, 1, 0, 0, 
	0, 3, 3, 3, 3, 0, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 0, 0, 0, 0, 1, 1, 1, 
	1, 1, 3, 0, 0, 0, 0, 0, 
	1, 0, 0, 0, 2, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 0, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	0, 0, 0, 0, 0, 0, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 0, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0, 0, 0, 
	0, 0, 1, 1, 1, 1, 1, 0, 
	0, 0, 1, 1, 1, 1, 1, 1, 
	1, 1, 0, 0, 1, 0, 0, 0, 
	1, 1, 1, 1, 1, 1, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const short _SSAtag_index_offsets[] = {
	0, 3, 5, 27, 31, 38, 45, 50, 
	57, 60, 67, 74, 79, 86, 89, 93, 
	100, 107, 112, 119, 122, 129, 136, 141, 
	148, 151, 155, 162, 169, 174, 181, 184, 
	191, 198, 203, 210, 213, 217, 224, 231, 
	236, 243, 246, 253, 260, 265, 272, 275, 
	281, 284, 288, 292, 298, 301, 305, 308, 
	311, 314, 321, 328, 333, 340, 343, 347, 
	350, 354, 361, 364, 368, 373, 376, 381, 
	385, 388, 391, 394, 397, 400, 405, 408, 
	413, 417, 420, 428, 431, 434, 437, 440, 
	447, 451, 455, 458, 461, 468, 471, 476, 
	480, 483, 488, 495, 498, 503, 507, 510, 
	514, 519, 522, 527, 531, 534, 539, 542, 
	547, 551, 554, 559, 562, 567, 571, 574, 
	578, 581, 584, 587, 590, 593, 596, 601, 
	604, 609, 614, 617, 622, 627, 630, 635, 
	640, 643, 649, 652, 657, 660, 666, 671, 
	674, 679, 683, 686, 691, 694, 699, 702, 
	706, 709, 713, 716, 720, 723, 726, 729, 
	732, 735, 738, 745, 748, 753, 757, 760, 
	763, 766, 769, 774, 777, 782, 786, 789, 
	793, 796, 800, 803, 806, 810, 813, 816, 
	819, 824, 827, 832, 836, 839, 842, 845, 
	849, 852, 855, 858, 861, 864, 867
};

static const unsigned char _SSAtag_trans_targs[] = {
	2, 197, 1, 197, 1, 3, 14, 25, 
	36, 47, 51, 65, 82, 87, 119, 47, 
	122, 157, 162, 175, 178, 180, 85, 189, 
	197, 191, 1, 4, 9, 197, 1, 5, 
	5, 197, 7, 7, 7, 1, 6, 6, 
	197, 7, 7, 7, 1, 197, 7, 7, 
	7, 1, 8, 2, 197, 7, 7, 7, 
	1, 2, 197, 1, 10, 10, 197, 12, 
	12, 12, 1, 11, 11, 197, 12, 12, 
	12, 1, 197, 12, 12, 12, 1, 13, 
	2, 197, 12, 12, 12, 1, 2, 197, 
	1, 15, 20, 197, 1, 16, 16, 197, 
	18, 18, 18, 1, 17, 17, 197, 18, 
	18, 18, 1, 197, 18, 18, 18, 1, 
	19, 2, 197, 18, 18, 18, 1, 2, 
	197, 1, 21, 21, 197, 23, 23, 23, 
	1, 22, 22, 197, 23, 23, 23, 1, 
	197, 23, 23, 23, 1, 24, 2, 197, 
	23, 23, 23, 1, 2, 197, 1, 26, 
	31, 197, 1, 27, 27, 197, 29, 29, 
	29, 1, 28, 28, 197, 29, 29, 29, 
	1, 197, 29, 29, 29, 1, 30, 2, 
	197, 29, 29, 29, 1, 2, 197, 1, 
	32, 32, 197, 34, 34, 34, 1, 33, 
	33, 197, 34, 34, 34, 1, 197, 34, 
	34, 34, 1, 35, 2, 197, 34, 34, 
	34, 1, 2, 197, 1, 37, 42, 197, 
	1, 38, 38, 197, 40, 40, 40, 1, 
	39, 39, 197, 40, 40, 40, 1, 197, 
	40, 40, 40, 1, 41, 2, 197, 40, 
	40, 40, 1, 2, 197, 1, 43, 43, 
	197, 45, 45, 45, 1, 44, 44, 197, 
	45, 45, 45, 1, 197, 45, 45, 45, 
	1, 46, 2, 197, 45, 45, 45, 1, 
	2, 197, 1, 48, 50, 50, 197, 49, 
	1, 197, 49, 1, 2, 197, 49, 1, 
	48, 197, 49, 1, 52, 54, 62, 197, 
	53, 1, 197, 53, 1, 2, 197, 53, 
	1, 55, 197, 1, 56, 197, 1, 57, 
	197, 1, 58, 58, 197, 60, 60, 60, 
	1, 59, 59, 197, 60, 60, 60, 1, 
	197, 60, 60, 60, 1, 61, 2, 197, 
	60, 60, 60, 1, 2, 197, 1, 63, 
	197, 64, 1, 197, 64, 1, 2, 197, 
	64, 1, 66, 68, 73, 75, 197, 67, 
	1, 197, 67, 1, 2, 197, 67, 1, 
	69, 72, 197, 70, 1, 197, 70, 1, 
	71, 2, 197, 70, 1, 2, 197, 71, 
	1, 197, 71, 1, 74, 197, 1, 68, 
	197, 1, 76, 197, 1, 77, 197, 1, 
	78, 81, 197, 79, 1, 197, 79, 1, 
	80, 2, 197, 79, 1, 2, 197, 80, 
	1, 197, 80, 1, 10, 10, 83, 197, 
	12, 12, 12, 1, 84, 197, 1, 85, 
	197, 1, 86, 197, 1, 0, 197, 86, 
	88, 50, 90, 92, 98, 197, 1, 89, 
	197, 68, 1, 86, 85, 197, 1, 2, 
	197, 91, 2, 197, 91, 93, 96, 97, 
	197, 94, 68, 1, 197, 94, 1, 95, 
	2, 197, 94, 1, 2, 197, 95, 1, 
	197, 95, 1, 93, 96, 197, 94, 1, 
	99, 102, 103, 114, 197, 100, 1, 197, 
	100, 1, 101, 2, 197, 100, 1, 2, 
	197, 101, 1, 197, 101, 1, 104, 109, 
	197, 1, 105, 108, 197, 106, 1, 197, 
	106, 1, 107, 2, 197, 106, 1, 2, 
	197, 107, 1, 197, 107, 1, 110, 113, 
	197, 111, 1, 197, 111, 1, 112, 2, 
	197, 111, 1, 2, 197, 112, 1, 197, 
	112, 1, 115, 118, 197, 116, 1, 197, 
	116, 1, 117, 2, 197, 116, 1, 2, 
	197, 117, 1, 197, 117, 1, 121, 197, 
	120, 1, 2, 197, 1, 83, 197, 1, 
	123, 197, 1, 124, 197, 1, 125, 197, 
	1, 126, 197, 1, 127, 156, 197, 128, 
	1, 197, 128, 1, 129, 155, 197, 128, 
	1, 130, 154, 197, 131, 1, 197, 131, 
	1, 132, 153, 197, 131, 1, 133, 152, 
	197, 134, 1, 197, 134, 1, 135, 151, 
	197, 134, 1, 136, 150, 197, 137, 1, 
	197, 137, 1, 138, 139, 149, 197, 137, 
	1, 2, 197, 1, 140, 148, 197, 141, 
	1, 197, 141, 1, 138, 142, 147, 197, 
	141, 1, 143, 146, 197, 144, 1, 197, 
	144, 1, 138, 145, 197, 144, 1, 138, 
	197, 145, 1, 197, 145, 1, 138, 142, 
	197, 147, 1, 197, 147, 1, 138, 139, 
	197, 149, 1, 197, 149, 1, 135, 197, 
	151, 1, 197, 151, 1, 132, 197, 153, 
	1, 197, 153, 1, 129, 197, 155, 1, 
	197, 155, 1, 158, 197, 1, 159, 197, 
	1, 160, 197, 1, 161, 197, 160, 2, 
	197, 1, 163, 166, 167, 168, 197, 164, 
	1, 197, 164, 1, 165, 2, 197, 164, 
	1, 2, 197, 165, 1, 197, 165, 1, 
	68, 197, 1, 169, 197, 1, 170, 197, 
	1, 171, 174, 197, 172, 1, 197, 172, 
	1, 142, 173, 197, 172, 1, 142, 197, 
	173, 1, 197, 173, 1, 176, 197, 177, 
	1, 197, 177, 1, 2, 197, 177, 1, 
	2, 197, 179, 2, 197, 179, 182, 197, 
	181, 1, 2, 197, 1, 183, 197, 1, 
	184, 197, 1, 185, 188, 197, 186, 1, 
	197, 186, 1, 187, 2, 197, 186, 1, 
	2, 197, 187, 1, 197, 187, 1, 197, 
	190, 1, 2, 197, 1, 192, 195, 197, 
	1, 193, 197, 1, 194, 197, 1, 68, 
	197, 1, 196, 197, 1, 194, 197, 1, 
	198, 0, 197, 197, 0
};

static const short _SSAtag_trans_actions[] = {
	0, 33, 0, 33, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	33, 0, 0, 0, 0, 33, 0, 0, 
	0, 33, 19, 19, 19, 0, 0, 0, 
	33, 19, 19, 19, 0, 33, 19, 19, 
	19, 0, 23, 101, 206, 0, 0, 0, 
	0, 11, 50, 0, 0, 0, 33, 19, 
	19, 19, 0, 0, 0, 33, 19, 19, 
	19, 0, 33, 19, 19, 19, 0, 23, 
	86, 186, 0, 0, 0, 0, 1, 35, 
	0, 0, 0, 33, 0, 0, 0, 33, 
	19, 19, 19, 0, 0, 0, 33, 19, 
	19, 19, 0, 33, 19, 19, 19, 0, 
	23, 104, 210, 0, 0, 0, 0, 13, 
	53, 0, 0, 0, 33, 19, 19, 19, 
	0, 0, 0, 33, 19, 19, 19, 0, 
	33, 19, 19, 19, 0, 23, 89, 190, 
	0, 0, 0, 0, 3, 38, 0, 0, 
	0, 33, 0, 0, 0, 33, 19, 19, 
	19, 0, 0, 0, 33, 19, 19, 19, 
	0, 33, 19, 19, 19, 0, 23, 107, 
	214, 0, 0, 0, 0, 15, 56, 0, 
	0, 0, 33, 19, 19, 19, 0, 0, 
	0, 33, 19, 19, 19, 0, 33, 19, 
	19, 19, 0, 23, 92, 194, 0, 0, 
	0, 0, 5, 41, 0, 0, 0, 33, 
	0, 0, 0, 33, 19, 19, 19, 0, 
	0, 0, 33, 19, 19, 19, 0, 33, 
	19, 19, 19, 0, 23, 110, 218, 0, 
	0, 0, 0, 17, 59, 0, 0, 0, 
	33, 19, 19, 19, 0, 0, 0, 33, 
	19, 19, 19, 0, 33, 19, 19, 19, 
	0, 23, 95, 198, 0, 0, 0, 0, 
	7, 44, 0, 19, 0, 0, 33, 19, 
	0, 33, 0, 0, 21, 83, 0, 0, 
	19, 33, 19, 0, 19, 0, 0, 33, 
	19, 0, 33, 0, 0, 74, 174, 0, 
	0, 0, 33, 0, 0, 33, 0, 0, 
	33, 0, 0, 0, 33, 19, 19, 19, 
	0, 0, 0, 33, 19, 19, 19, 0, 
	33, 19, 19, 19, 0, 23, 98, 202, 
	0, 0, 0, 0, 9, 47, 0, 19, 
	33, 19, 0, 33, 0, 0, 77, 178, 
	0, 0, 19, 0, 0, 0, 33, 19, 
	0, 33, 0, 0, 62, 158, 0, 0, 
	19, 19, 33, 19, 0, 33, 0, 0, 
	0, 25, 137, 0, 0, 25, 137, 0, 
	0, 33, 0, 0, 0, 33, 0, 0, 
	33, 0, 0, 33, 0, 0, 33, 0, 
	19, 19, 33, 19, 0, 33, 0, 0, 
	0, 113, 222, 0, 0, 113, 222, 0, 
	0, 33, 0, 0, 0, 0, 0, 33, 
	19, 19, 19, 0, 0, 33, 0, 0, 
	33, 0, 0, 33, 0, 0, 33, 0, 
	0, 0, 0, 0, 0, 33, 0, 0, 
	33, 0, 0, 0, 0, 33, 0, 146, 
	262, 19, 140, 254, 0, 19, 19, 0, 
	33, 19, 0, 0, 33, 0, 0, 0, 
	131, 246, 0, 0, 131, 246, 0, 0, 
	33, 0, 0, 19, 19, 33, 19, 0, 
	19, 19, 0, 0, 33, 19, 0, 33, 
	0, 0, 0, 119, 230, 0, 0, 119, 
	230, 0, 0, 33, 0, 0, 0, 0, 
	33, 0, 19, 19, 33, 19, 0, 33, 
	0, 0, 0, 122, 234, 0, 0, 122, 
	234, 0, 0, 33, 0, 0, 19, 19, 
	33, 19, 0, 33, 0, 0, 0, 125, 
	238, 0, 0, 125, 238, 0, 0, 33, 
	0, 0, 19, 19, 33, 19, 0, 33, 
	0, 0, 0, 128, 242, 0, 0, 128, 
	242, 0, 0, 33, 0, 0, 0, 33, 
	19, 0, 65, 162, 0, 0, 33, 0, 
	0, 33, 0, 0, 33, 0, 0, 33, 
	0, 19, 33, 0, 0, 0, 33, 0, 
	0, 33, 0, 0, 0, 0, 33, 0, 
	0, 0, 0, 33, 0, 0, 33, 0, 
	0, 0, 0, 33, 0, 0, 0, 0, 
	33, 0, 0, 33, 0, 0, 0, 0, 
	33, 0, 0, 0, 0, 33, 0, 0, 
	33, 0, 0, 0, 0, 0, 33, 0, 
	0, 152, 270, 0, 0, 0, 33, 0, 
	0, 33, 0, 0, 0, 0, 0, 33, 
	0, 0, 0, 0, 33, 0, 0, 33, 
	0, 0, 0, 0, 33, 0, 0, 0, 
	33, 0, 0, 33, 0, 0, 0, 0, 
	33, 0, 0, 33, 0, 0, 0, 0, 
	33, 0, 0, 33, 0, 0, 0, 33, 
	0, 0, 33, 0, 0, 0, 33, 0, 
	0, 33, 0, 0, 0, 33, 0, 0, 
	33, 0, 0, 0, 33, 0, 0, 33, 
	0, 0, 33, 0, 0, 33, 0, 27, 
	155, 0, 19, 19, 0, 0, 33, 19, 
	0, 33, 0, 0, 0, 134, 250, 0, 
	0, 134, 250, 0, 0, 33, 0, 0, 
	0, 33, 0, 0, 33, 0, 19, 33, 
	0, 0, 0, 33, 0, 0, 33, 0, 
	0, 0, 0, 33, 0, 0, 0, 33, 
	0, 0, 33, 0, 0, 19, 33, 19, 
	0, 33, 0, 0, 80, 182, 0, 0, 
	149, 266, 19, 143, 258, 0, 0, 33, 
	19, 0, 71, 170, 0, 0, 33, 0, 
	0, 33, 0, 19, 19, 33, 19, 0, 
	33, 0, 0, 0, 116, 226, 0, 0, 
	116, 226, 0, 0, 33, 0, 0, 33, 
	19, 0, 68, 166, 0, 0, 0, 33, 
	0, 0, 33, 0, 0, 33, 0, 0, 
	33, 0, 0, 33, 0, 0, 33, 0, 
	0, 31, 0, 29, 0
};

static const short _SSAtag_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 31, 31
};

static const int SSAtag_start = 197;
static const int SSAtag_first_final = 197;
static const int SSAtag_error = -1;

static const int SSAtag_en_main = 197;


#line 263 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

NSArray *SubParsePacket(NSString *packet, SubContext *context, SubRenderer *delegate)
{
	packet = SubStandardizeStringNewlines(packet);
	NSArray *lines = (context->scriptType == kSubTypeSRT) ? [NSArray arrayWithObject:[packet substringToIndex:[packet length]-1]] : [packet componentsSeparatedByString:@"\n"];
	size_t line_count = [lines count];
	NSMutableArray *divs = [NSMutableArray arrayWithCapacity:line_count];
	NSInteger i;
	
	for (i = 0; i < line_count; i++) {
		NSString *inputText = [lines objectAtIndex:(context->collisions == kSubCollisionsReverse) ? (line_count - i - 1) : i];
		SubRenderDiv *div = [[SubRenderDiv alloc] init];
		NSMutableString *text = [[NSMutableString alloc] init];
		NSMutableArray *spans = [[NSMutableArray alloc] init];
		
		div->text  = text;
		div->spans = spans;
		
		if (context->scriptType == kSubTypeSRT) {
			div->styleLine = context->defaultStyle;
			div->marginL = div->styleLine->marginL;
			div->marginR = div->styleLine->marginR;
			div->marginV = div->styleLine->marginV;
			div->layer = 0;
			div->wrapStyle = kSubLineWrapTopWider;
		} else {
			NSArray *fields = SubSplitStringWithCount(inputText, @",", 9);
			if ([fields count] < 9) continue;
			div->layer = [[fields objectAtIndex:1] intValue];
			div->styleLine = [context styleForName:[fields objectAtIndex:2]];
			div->marginL = [[fields objectAtIndex:4] intValue];
			div->marginR = [[fields objectAtIndex:5] intValue];
			div->marginV = [[fields objectAtIndex:6] intValue];
			inputText = [fields objectAtIndex:8];
			if ([inputText length] == 0) continue;
			
			if (div->marginL == 0) div->marginL = div->styleLine->marginL;
			if (div->marginR == 0) div->marginR = div->styleLine->marginR;
			if (div->marginV == 0) div->marginV = div->styleLine->marginV;
			
			div->wrapStyle = context->wrapStyle;
		}
		
		div->alignH = div->styleLine->alignH;
		div->alignV = div->styleLine->alignV;
		
#undef send
#define send()  [[NSString alloc] initWithCharactersNoCopy:(unichar*)outputbegin length:p-outputbegin freeWhenDone:NO]
#define psend() [[NSString alloc] initWithCharactersNoCopy:(unichar*)parambegin length:p-parambegin freeWhenDone:NO]
#define tag(tagt, p) [delegate spanChangedTag:tag_##tagt span:current_span div:div param:&(p)]
				
		{
			size_t linelen = [inputText length];
			NSData *linebufData;
			const unichar *linebuf = SubUnicodeForString(inputText, &linebufData);
			const unichar *p = linebuf, *pe = linebuf + linelen, *outputbegin = p, *parambegin=p, *last_tag_start=p;
			const unichar *pb = p;
			int cs = 0;
			SubRenderSpan *current_span = [SubRenderSpan new];
			int chars_deleted = 0; float floatnum = 0;
			NSString *strval=NULL;
			double curX = 0.0, curY = 0;
			int intnum = 0;
			BOOL reachedEnd = NO, setWrapStyle = NO, setPosition = NO, setAlignForDiv = NO, dropThisSpan = NO;
			
			[delegate didCreateStartingSpan:current_span forDiv:div];
			
			
#line 518 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"

				
			
#line 1228 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
	{
	cs = SSAtag_start;
	}

#line 521 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
			
#line 1235 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
_resume:
	_keys = _SSAtag_trans_keys + _SSAtag_key_offsets[cs];
	_trans = _SSAtag_index_offsets[cs];

	_klen = _SSAtag_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _SSAtag_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	cs = _SSAtag_trans_targs[_trans];

	if ( _SSAtag_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _SSAtag_actions + _SSAtag_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 331 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(b, intnum);}
	break;
	case 1:
#line 332 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(i, intnum);}
	break;
	case 2:
#line 333 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(u, intnum);}
	break;
	case 3:
#line 334 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(s, intnum);}
	break;
	case 4:
#line 335 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(bord, floatnum);}
	break;
	case 5:
#line 336 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(shad, floatnum);}
	break;
	case 6:
#line 338 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(fn, strval);}
	break;
	case 7:
#line 339 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(fs, floatnum);}
	break;
	case 8:
#line 340 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(fscx, floatnum);}
	break;
	case 9:
#line 341 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(fscy, floatnum);}
	break;
	case 10:
#line 342 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(fsp, floatnum);}
	break;
	case 11:
#line 343 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(frz, floatnum);}
	break;
	case 12:
#line 346 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(1c, intnum);}
	break;
	case 13:
#line 347 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(2c, intnum);}
	break;
	case 14:
#line 348 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(3c, intnum);}
	break;
	case 15:
#line 349 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(4c, intnum);}
	break;
	case 16:
#line 350 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(alpha, intnum);}
	break;
	case 17:
#line 351 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(1a, intnum);}
	break;
	case 18:
#line 352 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(2a, intnum);}
	break;
	case 19:
#line 353 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(3a, intnum);}
	break;
	case 20:
#line 354 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(4a, intnum);}
	break;
	case 21:
#line 355 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(r, strval);}
	break;
	case 22:
#line 356 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{tag(p, floatnum); dropThisSpan = floatnum > 0;}
	break;
	case 23:
#line 358 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{parambegin=p;}
	break;
	case 24:
#line 359 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{intnum = [psend() intValue];}
	break;
	case 25:
#line 360 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{intnum = (int)strtoul([psend() UTF8String], NULL, 16);}
	break;
	case 26:
#line 361 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{floatnum = [psend() floatValue];}
	break;
	case 27:
#line 362 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{strval = psend();}
	break;
	case 28:
#line 363 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{strval = @"";}
	break;
	case 29:
#line 364 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{curX=curY=0; sscanf([psend() UTF8String], "(%lf,%lf", &curX, &curY);}
	break;
	case 30:
#line 366 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (!setAlignForDiv) {
						setAlignForDiv = YES;
						
						SubParseASSAlignment(SubASSFromSSAAlignment(intnum), &div->alignH, &div->alignV);
					}
				}
	break;
	case 31:
#line 374 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (!setAlignForDiv) {
						setAlignForDiv = YES;
						
						SubParseASSAlignment(intnum, &div->alignH, &div->alignV);
					}
				}
	break;
	case 32:
#line 382 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (!setWrapStyle) {
						setWrapStyle = YES;
						
						div->wrapStyle = intnum;

					}
				}
	break;
	case 33:
#line 391 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (!setPosition) {
						setPosition = YES;
						
						div->posX = curX;
						div->posY = curY;
						div->positioned = YES;
					}
				}
	break;
	case 34:
#line 401 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					div->shouldResetPens = YES;
				}
	break;
	case 35:
#line 465 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					p--;
					[text appendString:send()];
					unichar c = *(p+1), o=c;
					
					if (c) {
						switch (c) {
							case 'N': case 'n':
								o = '\n';
								break;
							case 'h':
								o = 0xA0; //non-breaking space
								break;
						}
						
						[text appendFormat:@"%C",o];
					}
					
					chars_deleted++;
					
					p++;
					outputbegin = p+1;
				}
	break;
	case 36:
#line 489 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (dropThisSpan) chars_deleted += p - outputbegin;
					else if (p > outputbegin) [text appendString:send()];
					if (p == pe) reachedEnd = YES;
					
					if (p != pb) {
						[spans addObject:current_span];
						
						if (!reachedEnd) current_span = [current_span copy];
					}
					
					last_tag_start = p;
				}
	break;
	case 37:
#line 503 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{			
					p++;
					chars_deleted += (p - last_tag_start);
					
					current_span->offset = (p - pb) - chars_deleted;
					outputbegin = p;
					
					p--;
				}
	break;
#line 1529 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
		}
	}

_again:
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	const char *__acts = _SSAtag_actions + _SSAtag_eof_actions[cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 36:
#line 489 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
	{
					if (dropThisSpan) chars_deleted += p - outputbegin;
					else if (p > outputbegin) [text appendString:send()];
					if (p == pe) reachedEnd = YES;
					
					if (p != pb) {
						[spans addObject:current_span];
						
						if (!reachedEnd) current_span = [current_span copy];
					}
					
					last_tag_start = p;
				}
	break;
#line 1559 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.c"
		}
	}
	}

	}

#line 522 "/Users/cwbetts/makestuff/SSAMacRendering/SSAMacRendering/SubParsing.m.rl"
			//%%write eof;

			if (!reachedEnd) Codecprintf(NULL, "parse error: %s\n", [inputText UTF8String]);
			linebufData = nil;
			[divs addObject:div];
		}
		
	}

	[divs sortWithOptions:NSSortStable|NSSortConcurrent usingComparator:^NSComparisonResult(id a, id b){
		SubRenderDiv *divA = a, *divB = b;

		if (divA->layer < divB->layer) return NSOrderedAscending;
		else if (divA->layer > divB->layer) return NSOrderedDescending;
		return NSOrderedSame;
	}];
	return divs;
}
