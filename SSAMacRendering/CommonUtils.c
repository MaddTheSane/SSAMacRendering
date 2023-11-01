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


#include <Carbon/Carbon.h>
#include <pthread.h>
#include <dlfcn.h>
#include <fnmatch.h>

#include "CommonUtils.h"


static const CFStringRef defaultFrameDroppingList[] = {
	CFSTR("Finder"),
	CFSTR("Front Row"),
	CFSTR("Movie Time"),
	CFSTR("Movist"),
	CFSTR("NicePlayer"),
	CFSTR("QTKitServer"),
	CFSTR("QuickTime Player"),
	CFSTR("Spiral")
};

static const CFStringRef defaultForcedAppList[] = {
	CFSTR("iChat")
};

static bool findNameInList(CFStringRef loadingApp, const CFStringRef *names, CFIndex count)
{
	int i;

	for (i = 0; i < count; i++) {
		if (CFGetTypeID(names[i]) != CFStringGetTypeID())
			continue;
		if (CFStringCompare(loadingApp, names[i], 0) == kCFCompareEqualTo) return true;
	}

	return false;
}

static CFDictionaryRef copyMyProcessInformation(void)
{
	CFBundleRef main = CFBundleGetMainBundle();
	CFDictionaryRef processInformation = CFBundleGetInfoDictionary(main);
	return CFDictionaryCreateCopy(kCFAllocatorDefault, processInformation);
}

static CFStringRef copyProcessName(CFDictionaryRef processInformation)
{
	CFStringRef path = CFDictionaryGetValue(processInformation, kCFBundleExecutableKey);
	CFRange entireRange = CFRangeMake(0, CFStringGetLength(path)), basename;
	
	CFStringFindWithOptions(path, CFSTR("/"), entireRange, kCFCompareBackwards, &basename);
	
	basename.location += 1; //advance past "/"
	basename.length = entireRange.length - basename.location;
	
	CFStringRef myProcessName = CFStringCreateWithSubstring(NULL, path, basename);
	return myProcessName;
}

static int isApplicationNameInList(CFStringRef prefOverride, const CFStringRef *defaultList, unsigned int defaultListCount)
{
	CFDictionaryRef processInformation = copyMyProcessInformation();
	
	if (!processInformation)
		return FALSE;
	
	CFArrayRef list = CopyPreferencesValueTyped(prefOverride, CFArrayGetTypeID());
	CFStringRef myProcessName = copyProcessName(processInformation);
	int ret;
	
	if (list) {
		CFIndex count = CFArrayGetCount(list);
		CFStringRef names[count];
		
		CFArrayGetValues(list, CFRangeMake(0, count), (void *)names);
		ret = findNameInList(myProcessName, names, count);
		CFRelease(list);
	} else {
		ret = findNameInList(myProcessName, defaultList, defaultListCount);
	}
	CFRelease(myProcessName);
	CFRelease(processInformation);
	
	return ret;
}

bool IsFrameDroppingEnabled(void)
{
	static int enabled = -1;
	
	if (enabled == -1)
		enabled = isApplicationNameInList(CFSTR("FrameDroppingWhiteList"),
										  defaultFrameDroppingList,
										  sizeof(defaultFrameDroppingList)/sizeof(defaultFrameDroppingList[0]));
	return enabled;
}

bool IsForcedDecodeEnabled(void)
{
	static int forced = -1;
	
	if(forced == -1)
		forced = isApplicationNameInList(CFSTR("ForcePerianAppList"),
										 defaultForcedAppList,
										 sizeof(defaultForcedAppList)/sizeof(defaultForcedAppList[0]));
	return forced;
}

CFPropertyListRef CopyPreferencesValueTyped(CFStringRef key, CFTypeID type)
{
	CFPropertyListRef val = CFPreferencesCopyAppValue(key, PERIAN_PREF_DOMAIN);
	
	if (val && CFGetTypeID(val) != type) {
		CFRelease(val);
		val = NULL;
	}
	
	return val;
}
