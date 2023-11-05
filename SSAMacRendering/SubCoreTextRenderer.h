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

@interface SubCoreTextRenderer : NSObject <SubRenderer>

/** 
 * @brief Creates a \c CGFont object and registers it for font matching via CoreText.
 *
 * @discussion Register fonts via `+registerFontsAtURL:error:` if fonts are stored as local files, as
 * it handles font files with multiple fonts (.ttc) better than this. 
 */
+ (nullable CGFontRef)registerFontFromData:(NSData*)data error:(NSError*_Nullable __autoreleasing*_Nullable)error CF_RETURNS_RETAINED;

/** @brief Unregisters a font from CoreText and releases it.
 *
 * @discussion The font will \b always be released, no matter if the unregistration was successful.
 * If you used `+registerFontsAtURL:error:` to register a font, use `+unregisterFontsAtURL:error:` instead of this method.
 */
+ (BOOL)unregisterFont:(CF_CONSUMED CGFontRef)font error:(NSError*_Nullable __autoreleasing*_Nullable)error;

/**
 * Registers fonts that are in the specified file for the current process scope.
 *
 * @discussion This is equivalent to `CTFontManagerRegisterFontsForURL((CFURLRef)url, kCTFontManagerScopeProcess, error)`.
 * If you want to register fonts for a different scope, use CTFontManagerUnregisterFontsForURL directly.
 */
+ (BOOL)registerFontsAtURL:(NSURL*)url error:(NSError**)error;

/**
 * Unregisters fonts that are in the specified file.
 *
 * @discussion This is equivalent to `CTFontManagerUnregisterFontsForURL((CFURLRef)url, kCTFontManagerScopeProcess, error)`.
 * If you want to unregister fonts for a different scope, use CTFontManagerUnregisterFontsForURL directly.
 */
+ (BOOL)unregisterFontsAtURL:(NSURL*)url error:(NSError**)error;


- (nullable instancetype)initWithScriptType:(SubType)type header:(nullable NSString*)header videoWidth:(CGFloat)width videoHeight:(CGFloat)height;


-(void)didCompleteHeaderParsing:(SubContext*)sc;
-(void)didCompleteStyleParsing:(SubStyle*)s;

-(void)didCreateStartingSpan:(SubRenderSpan*)span forDiv:(SubRenderDiv*)div;

-(void)spanChangedTag:(SubSSATagName)tag span:(SubRenderSpan*)span div:(SubRenderDiv*)div param:(void*)p;

@property (readonly) CGFloat aspectRatio;
@end

NS_ASSUME_NONNULL_END
