/*
 * SubRenderer.h
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

#include <sys/cdefs.h>

#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdbool.h>

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>

__BEGIN_DECLS

CF_ASSUME_NONNULL_BEGIN

@class SubStyle, SubStyleExtra;
@class SubContext, SubRenderDiv, SubRenderSpan, SubRenderSpanExtra;

typedef NS_ENUM(int, SubSSATagName) {
	tag_b=0, tag_i, tag_u, tag_s, tag_bord, tag_shad, tag_be,
	tag_fn, tag_fs, tag_fscx, tag_fscy, tag_fsp, tag_frx,
	tag_fry, tag_frz, tag_1c, tag_2c, tag_3c, tag_4c, tag_alpha,
	tag_1a, tag_2a, tag_3a, tag_4a, tag_r, tag_p,
	tag_t, tag_pbo, tag_fad, tag_fade,
};

@protocol SubRenderer <NSObject>
@optional
-(void)didCompleteHeaderParsing:(SubContext*)sc;
-(void)didCompleteStyleParsing:(SubStyle*)s;

@required
@property (readonly, strong, null_unspecified) SubContext *context;
-(void)didCreateStartingSpan:(SubRenderSpan*)span forDiv:(SubRenderDiv*)div NS_SWIFT_NAME(didCreateStartingSpan(_:for:));

-(void)spanChangedTag:(SubSSATagName)tag span:(SubRenderSpan*)span div:(SubRenderDiv*)div param:(void*)p NS_SWIFT_NAME(spanChanged(tag:span:div:param:));

@property (readonly) CGFloat aspectRatio;
-(void)renderPacket:(NSString *)packet inContext:(CGContextRef)c size:(CGSize)size NS_SWIFT_NAME(render(packet:in:size:));
@end


#else // !__OBJC__

__BEGIN_DECLS
CF_ASSUME_NONNULL_BEGIN

#endif

//This is actually an Obj-C class conforming to the SubRenderer protocol
typedef struct CF_BRIDGED_TYPE(id) __SubRendererPtr *SubRendererRef CF_SWIFT_NAME(SubRendererRef);

// these are actually implemented in SubATSUIRenderer.m
extern SubRendererRef __nullable SubRendererCreate(bool isSSA,  char * _Nullable header, size_t headerLen, int width, int height) CF_RETURNS_RETAINED;
extern SubRendererRef __nullable SubRendererCreateCF(bool isSSA, __nullable CFStringRef header, int width, int height) CF_RETURNS_RETAINED;
extern void SubRendererPrerollFromHeader(char * _Nullable header, int headerLen);
extern void SubRendererPrerollFromCFHeader(CFStringRef _Nullable header);
extern void SubRendererRenderPacket(SubRendererRef s, CGContextRef c, CFStringRef str, int cWidth, int cHeight);
extern void SubRendererDispose(CF_CONSUMED SubRendererRef s) CF_SWIFT_UNAVAILABLE("Release is called automatically");

CF_ASSUME_NONNULL_END

__END_DECLS
