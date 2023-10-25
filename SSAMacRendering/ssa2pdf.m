/*
 * ssa2pdf
 * Created by Alexander Strange on 8/11/09.
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

#import <ApplicationServices/ApplicationServices.h>
#import <SSAMacRendering/SubImport.h>
#import <SSAMacRendering/SubParsing.h>
#import <SSAMacRendering/SubRenderer.h>

extern CGContextRef CGPSContextCreateWithURL(CFURLRef url, const CGRect *mediaBox, CFDictionaryRef auxiliaryInfo);
extern void CGPSContextClose(CGContextRef c);

int main(int argc, char *argv[])
{	
	if (argc != 3)
		return 1;
	
	@autoreleasepool {
		NSURL *inURL = [[NSURL alloc] initFileURLWithFileSystemRepresentation:argv[1] isDirectory:NO relativeToURL:nil];
		NSURL *outURL = [[NSURL alloc] initFileURLWithFileSystemRepresentation:argv[2] isDirectory:YES relativeToURL:nil];
		SubContext *sc; SubSerializer *ss = [[SubSerializer alloc] init];
		//NSString *inFile = [NSString stringWithUTF8String:argv[1]], *outDir = [NSString stringWithUTF8String:argv[2]];
#ifdef CREATE_A_LOT_OF_PDFS
		int i = 0;
#endif
		
		//loading copied from ssa2html, still duplicated
		NSString *header = SubLoadSSAFromURL(inURL, ss);
		ss.finished = YES;
		
		NSDictionary *headers;
		NSArray *styles;
		SubParseSSAFile(header, &headers, &styles, NULL);
		sc = [[SubContext alloc] initWithScriptType:kSubTypeSSA headers:headers styles:styles delegate:NULL];
		int width = sc.resX, height = sc.resY;
		CGRect rect = CGRectMake(0, 0, width, height);
		SubRendererRef s = SubRendererCreateCF(YES, (__bridge CFStringRef _Nullable)(header), width, height);
		
		NSURL *allPDFs = [outURL URLByAppendingPathComponent:@"all.pdf"];
		NSURL *allEPS = [[outURL URLByAppendingPathComponent:@"all"] URLByAppendingPathExtension:@"eps"];
		CGContextRef pdfA = CGPDFContextCreateWithURL((CFURLRef)allPDFs, &rect, NULL);
		CGContextRef epsA = CGPSContextCreateWithURL((__bridge CFURLRef)allEPS, &rect, NULL);
		while (![ss isEmpty]) @autoreleasepool {
			SubLine *sl = [ss getSerializedPacket];
			if ([sl.line length] > 1) {
#ifdef CREATE_A_LOT_OF_PDFS
				NSString *pdf = [outDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.pdf", i]];
				CGContextRef pdfC = CGPDFContextCreateWithURL((CFURLRef)[NSURL fileURLWithPath:pdf], &rect, NULL);
				CGContextBeginPage(pdfC, NULL);
				SubRendererRenderPacket(s, pdfC, (CFStringRef)sl.line, width, height);
				CGContextEndPage(pdfC);
				CGContextRelease(pdfC);
				
				NSString *ps = [outDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.eps", i]];
				CGContextRef psC = CGPSContextCreateWithURL((CFURLRef)[NSURL fileURLWithPath:ps], &rect, NULL);
				CGContextBeginPage(psC, NULL);
				SubRendererRenderPacket(s, psC, (CFStringRef)sl.line, width, height);
				CGContextEndPage(psC);
				CGContextRelease(psC);
				i++;
#endif
				
				CGPDFContextBeginPage(pdfA, NULL);
				SubRendererRenderPacket(s, pdfA, (__bridge CFStringRef)sl.line, width, height);
				CGPDFContextEndPage(pdfA);
				
				CGContextBeginPage(epsA, NULL);
				SubRendererRenderPacket(s, epsA, (__bridge CFStringRef)sl.line, width, height);
				CGContextEndPage(epsA);

			}
		}
		//CGPSContextClose(epsA);
		CGContextRelease(epsA);
		CGPDFContextClose(pdfA);
		CGContextRelease(pdfA);
	}
	
	//while (1) sleep(60);
	
	return 0;
}
