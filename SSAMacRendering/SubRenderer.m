//
//  SubRenderer.m
//  SSAMacRendering
//
//  Created by C.W. Betts on 11/2/23.
//  Copyright © 2023 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SubRenderer.h"
#import "SubCoreTextRenderer.h"

void SubRendererRenderPacket(SubRendererRef s, CGContextRef c, CFStringRef str, int cWidth, int cHeight)
{
	@autoreleasepool {
		@try {
			[(__bridge id<SubRenderer>)s renderPacket:(__bridge NSString*)str inContext:c size:CGSizeMake(cWidth, cHeight)];
		}
		@catch (NSException *e) {
			NSLog(@"Caught exception during rendering - %@", e);
		}
	}
}

void SubRendererPrerollFromHeader(char *header, int headerLen)
{
	SubRendererRef s = SubRendererCreate(header!=NULL, header, headerLen, 640, 480);
	
	
	CGColorSpaceRef csp = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	void *buf = malloc(640 * 480 * 4);
	CGContextRef c = CGBitmapContextCreate(buf,640,480,8,640 * 4,csp,kCGImageAlphaPremultipliedFirst);
	
	if (!headerLen) {
		SubRendererRenderPacket(s, c, (CFStringRef)@"Abcde .", 640, 480);
	} else {
		NSArray<SubStyle*> *styles = [[((__bridge id<SubRenderer>)(s)) context]->styles allValues];
		
		for (SubStyle *sty in styles) {
			NSString *line = [NSString stringWithFormat:@"0,0,%@,,0,0,0,,Abcde .", sty->name];
			SubRendererRenderPacket(s, c, (__bridge CFStringRef)line, 640, 480);
		}
	}
	
	CGContextRelease(c);
	free(buf);
	CGColorSpaceRelease(csp);
	SubRendererDispose(s);
}

void SubRendererDispose(SubRendererRef s)
{
	@autoreleasepool {
		CFBridgingRelease(s);
	}
}

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
