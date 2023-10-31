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

//#include <libavcodec/avcodec.h>
//#include <libavcodec/bytestream.h>
#include "CommonUtils.h"

typedef struct LanguageTriplet {
	char twoChar[3];
	char threeChar[4];	// (ISO 639-2 3 char code)
	ScriptCode qtLang;
} LanguageTriplet;

// don't think there's a function already to do ISO 639-1/2 -> language code 
// that SetMediaLanguage() accepts
static const LanguageTriplet ISO_QTLanguages[] = {
	{ "",   "und", langUnspecified },
	{ "af", "afr", langAfrikaans },
	{ "sq", "alb", langAlbanian },
	{ "sq", "sqi", langAlbanian },
	{ "am", "amh", langAmharic },
	{ "ar", "ara", langArabic },
	{ "hy", "arm", langArmenian },
	{ "hy", "hye", langArmenian },
	{ "as", "asm", langAssamese }, 
	{ "ay", "aym", langAymara },
	{ "az", "aze", langAzerbaijani },
	{ "eu", "baq", langBasque },
	{ "eu", "eus", langBasque },
	{ "bn", "ben", langBengali },
	{ "br", "bre", langBreton },
	{ "bg", "bul", langBulgarian },
	{ "my", "bur", langBurmese },
	{ "my", "mya", langBurmese },
	{ "ca", "cat", langCatalan },
	{ "zh", "chi", langTradChinese },
	{ "zh", "zho", langTradChinese },
	{ "cs", "cze", langCzech },
	{ "cs", "ces", langCzech },
	{ "da", "dan", langDanish },
	{ "nl", "dut", langDutch },
	{ "nl", "nld", langDutch },
	{ "dz", "dzo", langDzongkha },
	{ "en", "eng", langEnglish },
	{ "eo", "epo", langEsperanto },
	{ "et", "est", langEstonian },
	{ "fo", "fao", langFaroese },
	{ "fi", "fin", langFinnish },
	{ "fr", "fre", langFrench },
	{ "fr", "fra", langFrench },
	{ "ka", "geo", langGeorgian },
	{ "ka", "kat", langGeorgian },
	{ "de", "ger", langGerman },
	{ "de", "deu", langGerman },
	{ "gl", "glg", langGalician },
	{ "gd", "gla", langScottishGaelic },
	{ "ga", "gle", langIrishGaelic },
	{ "gv", "glv", langManxGaelic },
	{ "",   "grc", langGreekAncient },
	{ "el", "gre", langGreek },
	{ "el", "ell", langGreek },
	{ "gn", "grn", langGuarani },
	{ "gu", "guj", langGujarati },
	{ "he", "heb", langHebrew },
	{ "hi", "hin", langHindi },
	{ "hu", "hun", langHungarian },
	{ "is", "ice", langIcelandic },
	{ "is", "isl", langIcelandic },
	{ "id", "ind", langIndonesian },
	{ "it", "ita", langItalian },
	{ "jv", "jav", langJavaneseRom },
	{ "ja", "jpn", langJapanese },
	{ "kl", "kal", langGreenlandic },
	{ "kn", "kan", langKannada },
	{ "ks", "kas", langKashmiri },
	{ "kk", "kaz", langKazakh },
	{ "km", "khm", langKhmer },
	{ "rw", "kin", langKinyarwanda },
	{ "ky", "kir", langKirghiz },
	{ "ko", "kor", langKorean },
	{ "ku", "kur", langKurdish },
	{ "lo", "lao", langLao },
	{ "la", "lat", langLatin },
	{ "lv", "lav", langLatvian },
	{ "lt", "lit", langLithuanian },
	{ "mk", "mac", langMacedonian },
	{ "mk", "mkd", langMacedonian },
	{ "ml", "mal", langMalayalam },
	{ "mr", "mar", langMarathi },
	{ "ms", "may", langMalayRoman },
	{ "ms", "msa", langMalayRoman },
	{ "mg", "mlg", langMalagasy },
	{ "mt", "mlt", langMaltese },
	{ "mo", "mol", langMoldavian },
	{ "mn", "mon", langMongolian },
	{ "ne", "nep", langNepali },
	{ "nb", "nob", langNorwegian },		// Norwegian Bokmal
	{ "no", "nor", langNorwegian },
	{ "nn", "nno", langNynorsk },
	{ "ny", "nya", langNyanja },
	{ "or", "ori", langOriya },
	{ "om", "orm", langOromo },
	{ "pa", "pan", langPunjabi },
	{ "fa", "per", langPersian },
	{ "fa", "fas", langPersian },
	{ "pl", "pol", langPolish },
	{ "pt", "por", langPortuguese },
	{ "qu", "que", langQuechua },
	{ "ro", "rum", langRomanian },
	{ "ro", "ron", langRomanian },
	{ "rn", "run", langRundi },
	{ "ru", "rus", langRussian },
	{ "sa", "san", langSanskrit },
	{ "sr", "scc", langSerbian },
	{ "sr", "srp", langSerbian },
	{ "hr", "scr", langCroatian },
	{ "hr", "hrv", langCroatian },
	{ "si", "sin", langSinhalese },
	{ "",   "sit", langTibetan },		// Sino-Tibetan (Other)
	{ "sk", "slo", langSlovak },
	{ "sk", "slk", langSlovak },
	{ "sl", "slv", langSlovenian },
	{ "se", "sme", langSami },
	{ "",   "smi", langSami },			// Sami languages (Other)
	{ "sd", "snd", langSindhi },
	{ "so", "som", langSomali },
	{ "es", "spa", langSpanish },
	{ "su", "sun", langSundaneseRom },
	{ "sw", "swa", langSwahili },
	{ "sv", "swe", langSwedish },
	{ "ta", "tam", langTamil },
	{ "tt", "tat", langTatar },
	{ "te", "tel", langTelugu },
	{ "tg", "tgk", langTajiki },
	{ "tl", "tgl", langTagalog },
	{ "th", "tha", langThai },
	{ "bo", "tib", langTibetan },
	{ "bo", "bod", langTibetan },
	{ "ti", "tir", langTigrinya },
	{ "",   "tog", langTongan },		// Tonga (Nyasa, Tonga Islands)
	{ "tr", "tur", langTurkish },
	{ "tk", "tuk", langTurkmen },
	{ "ug", "uig", langUighur },
	{ "uk", "ukr", langUkrainian },
	{ "ur", "urd", langUrdu },
	{ "uz", "uzb", langUzbek },
	{ "vi", "vie", langVietnamese },
	{ "cy", "wel", langWelsh },
	{ "cy", "cym", langWelsh },
	{ "yi", "yid", langYiddish }
};

ScriptCode ISO639_1ToQTLangCode(const char *lang)
{
	int i;
	
	if (strlen(lang) != 2)
		return langUnspecified;
	
	for (i = 0; i < sizeof(ISO_QTLanguages) / sizeof(LanguageTriplet); i++) {
		if (strcasecmp(lang, ISO_QTLanguages[i].twoChar) == 0)
			return ISO_QTLanguages[i].qtLang;
	}
	
	return langUnspecified;
}

ScriptCode ISO639_2ToQTLangCode(const char *lang)
{
	int i;
	
	if (strlen(lang) != 3)
		return langUnspecified;
	
	for (i = 0; i < sizeof(ISO_QTLanguages) / sizeof(LanguageTriplet); i++) {
		if (strcasecmp(lang, ISO_QTLanguages[i].threeChar) == 0)
			return ISO_QTLanguages[i].qtLang;
	}
	
	return langUnspecified;
}

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
