/*
 * CommonUtils.h
 * Created by David Conrad on 10/13/06.
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

#ifndef __COMMONUTILS_H__
#define __COMMONUTILS_H__

#include <CoreServices/CoreServices.h>
#include <CoreText/CTFont.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

//! ISO 639-1 to language ID expected by SetMediaLanguage
ScriptCode ISO639_1ToQTLangCode(const char *lang);

//! ISO 639-2 to language ID expected by SetMediaLanguage
ScriptCode ISO639_2ToQTLangCode(const char *lang);

// mallocs the buffer and copies the codec-specific description to it, in the same format
// as is specified in Matroska and is used in libavcodec
//ComponentResult ReadESDSDescExt(Handle descExt, UInt8 **buffer, int *size);

//int isImageDescriptionExtensionPresent(ImageDescriptionHandle desc, FourCharCode type);

//! does the current process break if we signal droppable frames?
	bool IsFrameDroppingEnabled(void);

//! does the current process break if we return errors in Preflight?
	bool IsForcedDecodeEnabled(void);

//! CFPreferencesCopyAppValue() wrapper which checks the type of the value returned
CFPropertyListRef CopyPreferencesValueTyped(CFStringRef key, CFTypeID type) CF_RETURNS_RETAINED;

extern CGFloat GetWinCTFontSizeScale(CTFontRef font);

#define PERIAN_PREF_DOMAIN CFSTR("org.perian.Perian")
#define PERIAN_EXPORTED __attribute__((visibility("default")))
	
#ifdef __cplusplus
}
#endif

#endif
