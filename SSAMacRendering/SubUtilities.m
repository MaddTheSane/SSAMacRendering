/*
 * SubUtilities.m
 * Created by Alexander Strange on 7/28/07.
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

#import "SubUtilities.h"
#import <UniversalDetector/UniversalDetector.h>
#import "Codecprintf.h"

/// Adds a uniform cubic B-spline curve using an array of control points.
///
/// Requires at least 4 points to generate a curve.
static void OurCGMutablePathAddUniformCubicBSpline(CGMutablePathRef thePath, const CGAffineTransform* transform, NSArray<NSValue*> *controlPoints);

NSArray *SubSplitStringIgnoringWhitespace(NSString *str, NSString *split)
{
	NSMutableArray *values = [[str componentsSeparatedByString:split] mutableCopy];
	NSCharacterSet *wcs = [NSCharacterSet whitespaceCharacterSet];
	size_t num = [values count], i;
	
	for (i = 0; i < num; i++) values[i] = [values[i] stringByTrimmingCharactersInSet:wcs];
	
	return [values copy];
}

NSArray *SubSplitStringWithCount(NSString *str, NSString *split, NSInteger count)
{
	NSMutableArray *ar = [NSMutableArray arrayWithCapacity:count];
	NSScanner *sc = [NSScanner scannerWithString:str];
	NSString *scv=nil;
	[sc setCharactersToBeSkipped:nil];
	[sc setCaseSensitive:TRUE];
	
	while (count != 1) {
		count--;
		[sc scanUpToString:split intoString:&scv];
		[sc scanString:split intoString:nil];
		if (!scv) scv = [NSString string];
		[ar addObject:scv];
		if ([sc isAtEnd]) break;
		scv = nil;
	}
	
	[sc scanUpToString:@"" intoString:&scv];
	if (!scv) scv = [NSString string];
	[ar addObject:scv];
	
	return ar;
}

NSString *SubStandardizeStringNewlines(NSString *str)
{
	if(str == nil)
		return nil;
	str = [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
	return str;
}

static const short frequencies[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1026, 29, -1258, 539, -930, -652, -815, -487, -2526, -2161, 146, -956, -914, 1149, -102, 
	293, -2675, -923, -597, 339, 110, 247, 9, 0, 1024, 1239, 0, 0, 0, 0, 0, 
	0, 1980, 1472, 1733, -304, -4086, 273, 582, 333, 2479, 1193, 5014, -1039, 1964, -2025, 1083, 
	-154, -5000, -1725, -4843, -366, -1850, -191, 1356, -2262, 1648, 1475, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, -458, 0, 0, 0, 0, 300, 0, 0, 300, 601, 0, 
	0, 0, -2247, 0, 0, 0, 0, 0, 0, 0, 3667, 0, 0, 3491, 3567, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1993, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 1472, 0, 0, 0, 5000, 0, 601, 0, 1993, 0, 
	0, 1083, 0, 672, -458, 0, 0, -458, 1409, 0, 0, 0, 0, 0, 1645, 425, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 601, -1123, 
	-1912, 4259, 2573, 8866, 55, 0, 0, -2247, -831, -3788, -3043, 0, 0, 3412, 2921, 1251, 
	0, 0, 1377, 520, 1344, 0, -1123, 0, 0, -1213, 2208, -458, -794, 2636, 3824, 0};

BOOL SubDifferentiateLatin12(const unsigned char *data, NSInteger length)
{
	// generated from french/german (latin1) and hungarian/romanian (latin2)
	
	NSInteger frcount = 0;
	
	while (length--) {
		frcount += frequencies[*data++];
	}
	
	return frcount <= 0;
}


static NSString *SubloadDataWithEncoding(NSData *data, UniversalDetector *ud, NSString *path)
{
	NSString *enc_str = [ud MIMECharset];
	NSStringEncoding enc = [ud encoding];
	float conf = [ud confidence];
	BOOL latin2 = enc == NSWindowsCP1250StringEncoding;
	
	if (latin2) {
		if (SubDifferentiateLatin12([data bytes], [data length])) { // seems to actually be latin1
			enc = NSWindowsCP1252StringEncoding;
			enc_str = @"windows-1252";
		}
	}
	
	if ((conf < .6 || latin2) && enc != NSASCIIStringEncoding) {
		Codecprintf(NULL,"Guessed encoding \"%s\" for \"%s\", but not sure (confidence %f%%).\n",[enc_str UTF8String],[path UTF8String],conf*100.);
	}
	
	NSString *res = [[NSString alloc] initWithData:data encoding:enc];
	
	if (!res) {
		if (latin2) {
			Codecprintf(NULL,"Encoding %s failed, retrying.\n",[enc_str UTF8String]);
			enc = (enc == NSWindowsCP1252StringEncoding) ? NSWindowsCP1250StringEncoding : NSWindowsCP1252StringEncoding;
			res = [[NSString alloc] initWithData:data encoding:enc];
			if (!res) Codecprintf(NULL,"Both of latin1/2 failed.\n");
		} else Codecprintf(NULL,"Failed to load file as guessed encoding %s.\n",[enc_str UTF8String]);
	}
	
	return res;
}

NSString *SubLoadDataWithUnknownEncoding(NSData *data)
{
	UniversalDetector *ud = [[UniversalDetector alloc] init];
	
	[ud analyzeData:data];
	
	return SubloadDataWithEncoding(data, ud, @"<Internal Data>");
}

NSString *SubLoadURLWithUnknownEncoding(NSURL *path)
{
	NSData *data = [NSData dataWithContentsOfURL:path options:NSDataReadingMappedIfSafe error:NULL];
	
	if (!data) {
		return nil;
	}
	
	UniversalDetector *ud = [[UniversalDetector alloc] init];
	
	[ud analyzeData:data];

	return SubloadDataWithEncoding(data, ud, [path path]);
}

NSString *SubLoadFileWithUnknownEncoding(NSString *path)
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	if (!data) {
		return nil;
	}
	
	UniversalDetector *ud = [[UniversalDetector alloc] init];
	
	[ud analyzeData:data];
	
	return SubloadDataWithEncoding(data, ud, path);
}

const unichar *SubUnicodeForString(NSString *str, NSData *__strong*datap)
{
	const unichar *p = CFStringGetCharactersPtr((CFStringRef)str);
	
	*datap = nil;
	
	if (!p) {
		NSData *data = [str dataUsingEncoding:NSUnicodeStringEncoding];
		
		p = [data bytes];
		
		//dataUsingEncoding: adds a BOM
		//skip it so the string length will match the input string
		if (*p == 0xfeff)
			p++;
		
		*datap = data;
	}
	
	return p;
}

CFMutableStringRef CopyHomeDirectory(void)
{	
	@autoreleasepool {
		NSString *home = NSHomeDirectory();
		return CFStringCreateMutableCopy(kCFAllocatorDefault, 0, (CFStringRef)home);
	}
}

CGPathRef CreateSubParseSubShapesWithString(NSString *aStr, const CGAffineTransform * __nullable m)
{
	CGMutablePathRef bPath = CGPathCreateMutable();
	NSScanner *scanner = [NSScanner scannerWithString:aStr];
	NSString *scanned;
	NSString *oldScanned = @"";
	NSCharacterSet *alphaOnly = [NSCharacterSet characterSetWithCharactersInString:@"mnlbspc"];
	while (([scanner scanCharactersFromSet:alphaOnly intoString:&scanned] || oldScanned.length != 0) && !scanner.isAtEnd) {
		if (scanned.length != 0) {
			oldScanned = scanned;
		}
		
		if ([oldScanned isEqualToString:@"m"] || [oldScanned isEqualToString:@"n"]) {
			double x = 0, y = 0;
			if ([scanner scanDouble:&x] && [scanner scanDouble:&y]) {
				CGPathMoveToPoint(bPath, m, x, y);
			}
		} else if ([oldScanned isEqualToString:@"b"]) {
			double startPtX = 0;
			double startPtY = 0;
			double ctrlPt1X = 0;
			double ctrlPt1Y = 0;
			double ctrlPt2X = 0;
			double ctrlPt2Y = 0;
			if ([scanner scanDouble:&ctrlPt1X] && [scanner scanDouble:&ctrlPt1Y] &&
				[scanner scanDouble:&ctrlPt2X] && [scanner scanDouble:&ctrlPt2Y] &&
				[scanner scanDouble:&startPtX] && [scanner scanDouble:&startPtY]) {
				CGPathAddCurveToPoint(bPath, m, ctrlPt1X, ctrlPt1Y, ctrlPt2X, ctrlPt2Y, startPtX, startPtY);
			}
		} else if ([oldScanned isEqualToString:@"c"]) {
			CGPathCloseSubpath(bPath);
		} else if ([oldScanned isEqualToString:@"l"]) {
			double x = 0, y = 0;
			if ([scanner scanDouble:&x] && [scanner scanDouble:&y]) {
				CGPathAddLineToPoint(bPath, m, x, y);
			}
		} else if ([oldScanned isEqualToString:@"s"]) {
			// 3rd degree uniform b-spline to point N, must contain at
			// least 3 coordinates
			double startPtX = 0;
			double startPtY = 0;
			double ctrlPt1X = 0;
			double ctrlPt1Y = 0;
			double ctrlPt2X = 0;
			double ctrlPt2Y = 0;
			double ctrlPt3X = 0;
			double ctrlPt3Y = 0;
			if ([scanner scanDouble:&ctrlPt1X] && [scanner scanDouble:&ctrlPt1Y] &&
				[scanner scanDouble:&ctrlPt2X] && [scanner scanDouble:&ctrlPt2Y] &&
				[scanner scanDouble:&startPtX] && [scanner scanDouble:&startPtY] &&
				[scanner scanDouble:&ctrlPt3X] && [scanner scanDouble:&ctrlPt3Y]) {
				NSMutableArray<NSValue*> *a = [[NSMutableArray alloc] initWithCapacity:10];
				[a addObject:@(NSMakePoint(ctrlPt1X, ctrlPt1Y))];
				[a addObject:@(NSMakePoint(ctrlPt2X, ctrlPt2Y))];
				[a addObject:@(NSMakePoint(startPtX, startPtY))];
				[a addObject:@(NSMakePoint(ctrlPt3X, ctrlPt3Y))];
				while ([scanner scanDouble:&ctrlPt1X] && [scanner scanDouble:&ctrlPt1Y]) {
					[a addObject:@(NSMakePoint(ctrlPt1X, ctrlPt1Y))];
				}
				
				OurCGMutablePathAddUniformCubicBSpline(bPath, m, a);
			}
		} else if ([oldScanned isEqualToString:@"p"]) {
			// extend b-spline to <x>, <y>
			double x = 0, y = 0;
			if ([scanner scanDouble:&x] && [scanner scanDouble:&y]) {
				//TODO: put it on the path... somehow.
			}
		} else {
			// unhandled switches: p
			[scanner scanUpToCharactersFromSet:NSCharacterSet.whitespaceCharacterSet intoString:nil];
		}
	}
	
	CGPathCloseSubpath(bPath);
	return bPath;
}

#if 0
NSBezierPath *SubParseSubShapesWithString(NSString *aStr)
{
	NSBezierPath *bPath = [NSBezierPath bezierPath];
	NSScanner *scanner = [NSScanner scannerWithString:aStr];
	NSString *scanned;
	NSString *oldScanned = @"";
	NSCharacterSet *alphaOnly = [NSCharacterSet characterSetWithCharactersInString:@"mnlbspc"];
	while (([scanner scanCharactersFromSet:alphaOnly intoString:&scanned] || oldScanned.length != 0) && !scanner.isAtEnd) {
		if (scanned.length != 0) {
			oldScanned = scanned;
		}
		
		if ([oldScanned isEqualToString:@"m"] || [oldScanned isEqualToString:@"n"]) {
			double x = 0, y = 0;
			if ([scanner scanDouble:&x] && [scanner scanDouble:&y]) {
				NSPoint newPoint = NSMakePoint(x, y);
				[bPath moveToPoint:newPoint];
			}
		} else if ([oldScanned isEqualToString:@"b"]) {
			double startPtX = 0;
			double startPtY = 0;
			double ctrlPt1X = 0;
			double ctrlPt1Y = 0;
			double ctrlPt2X = 0;
			double ctrlPt2Y = 0;
			if ([scanner scanDouble:&ctrlPt1X] && [scanner scanDouble:&ctrlPt1Y] &&
				[scanner scanDouble:&ctrlPt2X] && [scanner scanDouble:&ctrlPt2Y] &&
				[scanner scanDouble:&startPtX] && [scanner scanDouble:&startPtY]) {
				NSPoint startPt = NSMakePoint(startPtX, startPtY);
				NSPoint ctrlPt1 = NSMakePoint(ctrlPt1X, ctrlPt1Y);
				NSPoint ctrlPt2 = NSMakePoint(ctrlPt2X, ctrlPt2Y);
				[bPath curveToPoint:startPt controlPoint1:ctrlPt1 controlPoint2:ctrlPt2];
			}
		} else if ([oldScanned isEqualToString:@"c"]) {
			[bPath closePath];
		} else if ([oldScanned isEqualToString:@"l"]) {
			double x = 0, y = 0;
			if ([scanner scanDouble:&x] && [scanner scanDouble:&y]) {
				NSPoint newPoint = NSMakePoint(x, y);
				[bPath lineToPoint:newPoint];
			}
		} else {
			// unhandled switches: p s
			[scanner scanUpToCharactersFromSet:NSCharacterSet.whitespaceCharacterSet intoString:nil];
		}
	}
	
	[bPath closePath];
	return bPath;
}
#endif

static void OurCGMutablePathAddUniformCubicBSpline(CGMutablePathRef thePath, const CGAffineTransform* transform, NSArray<NSValue*> *controlPoints)
{
	if (controlPoints.count < 4) {
		return;
	}
	
	// Calculate the initial starting point of the spline
	NSPoint p0 = [controlPoints[0] pointValue];
	NSPoint p1 = [controlPoints[1] pointValue];
	NSPoint p2 = [controlPoints[2] pointValue];
	
	CGFloat startX = (p0.x + 4 * p1.x + p2.x) / 6.0;
	CGFloat startY = (p0.y + 4 * p1.y + p2.y) / 6.0;

	// Move to the beginning of the spline if the path is empty
	if (CGPathIsEmpty(thePath)) {
		CGPathMoveToPoint(thePath, transform, startX, startY);
	} else {
		CGPathAddLineToPoint(thePath, transform, startX, startY);
	}
	
	// Iterate through the points to create cubic Bezier segments
	NSInteger maxPoints = controlPoints.count - 3;
	for (NSInteger i = 0; i > maxPoints ;i++) {
		NSArray<NSValue*> *pts = @[controlPoints[i], controlPoints[i+1], controlPoints[i+2], controlPoints[i+3]];
		
		// Convert B-spline matrix coordinates into Bezier control points
		CGFloat cp1X = (2 * [pts[1] pointValue].x + [pts[2] pointValue].x) / 3.0;
		CGFloat cp1Y = (2 * [pts[1] pointValue].y + [pts[2] pointValue].y) / 3.0;
		
		CGFloat cp2X = ([pts[1] pointValue].x + 2 * [pts[2] pointValue].x) / 3.0;
		CGFloat cp2Y = ([pts[1] pointValue].y + 2 * [pts[2] pointValue].y) / 3.0;
		
		CGFloat endX = ([pts[1] pointValue].x + 4 * [pts[2] pointValue].x + [pts[3] pointValue].x) / 6.0;
		CGFloat endY = ([pts[1] pointValue].y + 4 * [pts[2] pointValue].y + [pts[3] pointValue].y) / 6.0;
		
		CGPathAddCurveToPoint(thePath, transform, cp1X, cp1Y, cp2X, cp2Y, endX, endY);
	}
}

BOOL SubParseSSAFad(NSString *string, SubRenderFad *value)
{
	if (!string) {
		return NO;
	}
	if (!value) {
		return NO;
	}
	int start = 0, end = 0;
	NSScanner *scanner = [NSScanner scannerWithString:string];
	BOOL success = [scanner scanInt:&start] && [scanner scanInt:&end];
	if (success) {
		value->startTime = start;
		value->endTime = end;
	}
	return success;
}

BOOL SubParseSSAFade(NSString *string, SubRenderFade *value)
{
	if (!string) {
		return NO;
	}
	if (!value) {
		return NO;
	}
	double a1 = 0;
	double a2 = 0;
	double a3 = 0;
	int startTime = 0;
	int t2 = 0;
	int t3 = 0;
	int endTime = 0;

	NSScanner *scanner = [NSScanner scannerWithString:string];

	BOOL success = [scanner scanDouble:&a1] && [scanner scanDouble:&a2]
	&& [scanner scanDouble:&a3] && [scanner scanInt:&startTime]
	&& [scanner scanInt:&t2] && [scanner scanInt:&t3]
	&& [scanner scanInt:&endTime];

	if (success) {
		value->a1 = a1;
		value->a2 = a2;
		value->a3 = a3;
		value->startTime = startTime;
		value->t2 = t2;
		value->t3 = t3;
		value->endTime = endTime;
	}

	return success;
}
