//
//  SubCoreTextRenderer.h
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubRenderer.h"
#import "SubContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubCoreTextRenderer : SubRenderer

/** @brief Creates a \c CGFont object and registers it for font matching via CoreText.
 *
 */
+ (nullable CGFontRef)registerFontFromData:(NSData*)data error:(NSError*_Nullable __autoreleasing*_Nullable)error CF_RETURNS_RETAINED;

/** @brief Unregisters a font from CoreText and releases it.
 *
 * @discussion The font will \b always be released, no matter if the unregistration was successful.
 */
+ (BOOL)unregisterFont:(CF_CONSUMED CGFontRef)font error:(NSError*_Nullable __autoreleasing*_Nullable)error;


- (nullable instancetype)initWithScriptType:(SubType)type header:(nullable NSString*)header videoWidth:(CGFloat)width videoHeight:(CGFloat)height;


-(void)didCompleteHeaderParsing:(SubContext*)sc;
-(void)didCompleteStyleParsing:(SubStyle*)s;

-(void)didCreateStartingSpan:(SubRenderSpan*)span forDiv:(SubRenderDiv*)div;

-(void)spanChangedTag:(SubSSATagName)tag span:(SubRenderSpan*)span div:(SubRenderDiv*)div param:(void*)p;

@property (readonly) CGFloat aspectRatio;
-(void)renderPacket:(NSString *)packet inContext:(CGContextRef)c width:(CGFloat)cWidth height:(CGFloat)cHeight;
@end

NS_ASSUME_NONNULL_END
