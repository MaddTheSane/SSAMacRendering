//
//  main.m
//  ssa2png
//
//  Created by C.W. Betts on 2/16/18.
//  Copyright © 2018 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <ApplicationServices/ApplicationServices.h>
#import <SSAMacRendering/SubImport.h>
#import <SSAMacRendering/SubParsing.h>
#import <SSAMacRendering/SubRenderer.h>

int main(int argc, const char * argv[])
{
	if (argc != 3)
		return 1;

	@autoreleasepool {
		NSURL *inURL = [[NSURL alloc] initFileURLWithFileSystemRepresentation:argv[1] isDirectory:NO relativeToURL:nil];
		NSURL *outURL = [[NSURL alloc] initFileURLWithFileSystemRepresentation:argv[2] isDirectory:YES relativeToURL:nil];
		SubContext *sc; SubSerializer *ss = [[SubSerializer alloc] init];
		int i = 0;
		
		//loading copied from ssa2html, still duplicated
		NSString *header = SubLoadSSAFromURL(inURL, ss);
		ss.finished = YES;
		
		NSDictionary *headers;
		NSArray *styles;
		SubParseSSAFile(header, &headers, &styles, NULL);
		sc = [[SubContext alloc] initWithScriptType:kSubTypeSSA headers:headers styles:styles delegate:NULL];
		int width = sc.resX, height = sc.resY;
		CGRect rect = CGRectMake(0, 0, width, height);
		SubRendererRef s = SubRendererCreate(YES, (char*)[header UTF8String], [header length], width, height);
		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		
		while (![ss isEmpty]) @autoreleasepool {
			SubLine *sl = [ss getSerializedPacket];
			if ([sl.line length] > 1) {
				NSURL *pdf = [outURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", i]];
				CGImageDestinationRef datCon = CGImageDestinationCreateWithURL((CFURLRef)pdf, kUTTypePNG, 1, NULL);
				
				//CGImageRef img = CGImageCreate(width, height, 8, 32, width*4, nil, kCGImageAlphaPremultipliedLast, nil, nil, false, kCGRenderingIntentDefault);
				CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host) ;
				//CGPDFContextCreateWithURL((CFURLRef)[NSURL fileURLWithPath:pdf], &rect, NULL);
				//CGContextBeginPage(pdfC, NULL);
				SubRendererRenderPacket(s, ctx, (__bridge CFStringRef)sl.line, width, height);
				CGImageRef outImg = CGBitmapContextCreateImage(ctx);
				CGContextRelease(ctx);
				CGImageDestinationAddImage(datCon, outImg, NULL);
				CGImageRelease(outImg);
				//CGContextEndPage(pdfC);
				//CGContextRelease(pdfC);
				CGImageDestinationFinalize(datCon);
				CFRelease(datCon);
				
				i++;
			}
		}
		CGColorSpaceRelease(colorSpace);
	}
	return 0;
}
