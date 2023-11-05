/*
 * SubImport.mm
 * Created by Alexander Strange on 7/24/07.
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

#include <string.h>
#include <unistd.h>

#include "CommonUtils.h"
#include "Codecprintf.h"
#import "SubImport.h"
#import "SubParsing.h"
#import "SubRenderer.h"
#import "SubUtilities.h"

//#define SS_DEBUG

#pragma mark C

static NSString *MatroskaPacketizeLine(NSDictionary *sub, NSInteger n)
{
	NSString *name = [sub objectForKey:@"Name"];
	if (!name) name = [sub objectForKey:@"Actor"];
	
	return [NSString stringWithFormat:@"%ld,%d,%@,%@,%@,%@,%@,%@,%@\n",
		(long)(n+1),
		[[sub objectForKey:@"Layer"] intValue],
		[sub objectForKey:@"Style"],
		name,
		[sub objectForKey:@"MarginL"],
		[sub objectForKey:@"MarginR"],
		[sub objectForKey:@"MarginV"],
		[sub objectForKey:@"Effect"],
		[sub objectForKey:@"Text"]];
}

static int ParseSubTime(const char *time, int secondScale, BOOL hasSign)
{
	unsigned hour, minute, second, subsecond, timeval;
	char separator;
	int sign = 1;
	
	if (hasSign && *time == '-') {
		sign = -1;
		time++;
	}
	
	if (sscanf(time,"%u:%u:%u%c%u",&hour,&minute,&second,&separator,&subsecond) < 5 ||
	   (separator != ',' && separator != '.' && separator != ':'))
		return 0;
	
	timeval = hour * 60 * 60 + minute * 60 + second;
	timeval = secondScale * timeval + subsecond;
	
	return timeval * sign;
}

static NSString *SubLoadSSAFromData(NSString *ssa, SubSerializer *ss)
{
	NSDictionary *headers;
	NSArray *subs;
	
	SubParseSSAFile(ssa, &headers, NULL, &subs);
	
	NSInteger numlines = [subs count];
	
	for (NSInteger i = 0; i < numlines; i++) {
		NSDictionary *sub = [subs objectAtIndex:i];
		SubLine *sl = [[SubLine alloc] initWithLine:MatroskaPacketizeLine(sub, i)
											  start:ParseSubTime([[sub objectForKey:@"Start"] UTF8String],100,NO)
												end:ParseSubTime([[sub objectForKey:@"End"] UTF8String],100,NO)];
		
		[ss addLine:sl];
	}
	
	return [ssa substringToIndex:[ssa rangeOfString:@"[Events]" options:NSLiteralSearch].location];
}

NSString *SubLoadSSAFromPath(NSString *path, SubSerializer *ss)
{
	return SubLoadSSAFromURL([NSURL fileURLWithPath:path], ss);
}

NSString *SubLoadSSAFromURL(NSURL *path, SubSerializer *ss)
{
	NSString *ssa = SubLoadURLWithUnknownEncoding(path);
	
	if (!ssa) return nil;
	
	return SubLoadSSAFromData(ssa, ss);
}

NSString *_Nullable SubLoadSSAFromNSData(NSData *data, SubSerializer *ss)
{
	NSString *ssa = SubLoadDataWithUnknownEncoding(data);
	if ([ssa rangeOfString:@"\r\n"].location != NSNotFound) {
		ssa = [ssa stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
	}
	
	if (!ssa) return nil;

	return SubLoadSSAFromData(ssa, ss);
}

//

#pragma mark SAMI Parsing

void SubLoadSRTFromPath(NSString *path, SubSerializer *ss)
{
	NSURL *url = [NSURL fileURLWithPath:path];
	SubLoadSRTFromURL(url, ss);
}

void SubLoadSRTFromURL(NSURL *path, SubSerializer *ss)
{
	NSMutableString *srt = [SubStandardizeStringNewlines(SubLoadURLWithUnknownEncoding(path)) mutableCopy];
	if (![srt length]) return;
		
	if ([srt characterAtIndex:0] == 0xFEFF) [srt deleteCharactersInRange:NSMakeRange(0,1)];
	if ([srt characterAtIndex:[srt length]-1] != '\n') [srt appendFormat:@"%c",'\n'];
	
	NSScanner *sc = [NSScanner scannerWithString:srt];
	NSString *res=nil;
	[sc setCharactersToBeSkipped:nil];
	
	int startTime=0, endTime=0;
	
	enum {
		INITIAL,
		TIMESTAMP,
		LINES
	} state = INITIAL;
	
	do {
		switch (state) {
			case INITIAL:
				if ([sc scanInt:NULL] == TRUE && [sc scanUpToString:@"\n" intoString:&res] == FALSE) {
					state = TIMESTAMP;
					[sc scanString:@"\n" intoString:nil];
				} else
					[sc setScanLocation:[sc scanLocation]+1];
				break;
			case TIMESTAMP:
				[sc scanUpToString:@" --> " intoString:&res];
				[sc scanString:@" --> " intoString:nil];
				startTime = ParseSubTime([res UTF8String], 1000, NO);
				
				[sc scanUpToString:@"\n" intoString:&res];
				[sc scanString:@"\n" intoString:nil];
				endTime = ParseSubTime([res UTF8String], 1000, NO);
				state = LINES;
				break;
			case LINES:
				[sc scanUpToString:@"\n\n" intoString:&res];
				[sc scanString:@"\n\n" intoString:nil];
				SubLine *sl = [[SubLine alloc] initWithLine:res start:startTime end:endTime];
				[ss addLine:sl];
				state = INITIAL;
				break;
		};
	} while (![sc isAtEnd]);
}

static int parse_SYNC(NSString *str)
{
	NSScanner *sc = [NSScanner scannerWithString:str];

	int res=0;

	if ([sc scanString:@"START=" intoString:nil])
		[sc scanInt:&res];

	return res;
}

static NSArray *parse_STYLE(NSString *str)
{
	NSScanner *sc = [NSScanner scannerWithString:str];

	NSString *firstRes;
	NSString *secondRes;
	NSArray *subArray;
	int secondLoc;

	[sc scanUpToString:@"<P CLASS=" intoString:nil];
	if ([sc scanString:@"<P CLASS=" intoString:nil])
		[sc scanUpToString:@">" intoString:&firstRes];
	else
		firstRes = @"noClass";

	secondLoc = [str length] * .9;
	[sc setScanLocation:secondLoc];

	[sc scanUpToString:@"<P CLASS=" intoString:nil];
	if ([sc scanString:@"<P CLASS=" intoString:nil])
		[sc scanUpToString:@">" intoString:&secondRes];
	else
		secondRes = @"noClass";

	if ([firstRes isEqualToString:secondRes])
		secondRes = @"noClass";

	subArray = [NSArray arrayWithObjects:firstRes, secondRes, nil];

	return subArray;
}

static int parse_P(NSString *str, NSArray<NSString*> *subArray)
{
	NSScanner *sc = [NSScanner scannerWithString:str];

	NSString *res;
	int subLang;

	if ([sc scanString:@"CLASS=" intoString:nil])
		[sc scanUpToString:@">" intoString:&res];
	else
		res = @"noClass";

	if ([res isEqualToString:[subArray objectAtIndex:0]])
		subLang = 1;
	else if ([res isEqualToString:[subArray objectAtIndex:1]])
		subLang = 2;
	else
		subLang = 3;

	return subLang;
}

static NSString *parse_COLOR(NSString *str)
{
	NSString *cvalue;
	NSMutableString *cname = [NSMutableString stringWithString:str];

	if (![str length]) return str;
	
	if ([cname characterAtIndex:0] == '#' && [cname lengthOfBytesUsingEncoding:NSASCIIStringEncoding] == 7)
		cvalue = [NSString stringWithFormat:@"{\\1c&H%@%@%@&}", [cname substringWithRange:NSMakeRange(5,2)], [cname substringWithRange:NSMakeRange(3,2)], [cname substringWithRange:NSMakeRange(1,2)]];
	else {
		[cname replaceOccurrencesOfString:@"Aqua" withString:@"00FFFF" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Black" withString:@"000000" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Blue" withString:@"0000FF" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Fuchsia" withString:@"FF00FF" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Gray" withString:@"808080" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Green" withString:@"008000" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Lime" withString:@"00FF00" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Maroon" withString:@"800000" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Navy" withString:@"000080" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Olive" withString:@"808000" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Purple" withString:@"800080" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Red" withString:@"FF0000" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Silver" withString:@"C0C0C0" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Teal" withString:@"008080" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"White" withString:@"FFFFFF" options:1 range:NSMakeRange(0,[cname length])];
		[cname replaceOccurrencesOfString:@"Yellow" withString:@"FFFF00" options:1 range:NSMakeRange(0,[cname length])];

		if ([cname lengthOfBytesUsingEncoding:NSASCIIStringEncoding] == 6)
			cvalue = [NSString stringWithFormat:@"{\\1c&H%@%@%@&}", [cname substringWithRange:NSMakeRange(4,2)], [cname substringWithRange:NSMakeRange(2,2)], [cname substringWithRange:NSMakeRange(0,2)]];
		else
			cvalue = @"{\\1c&HFFFFFF&}";
	}

	return cvalue;
}

static NSString *parse_FONT(NSString *str)
{
	NSScanner *sc = [NSScanner scannerWithString:str];

	NSString *res;
	NSString *color;

	if ([sc scanString:@"COLOR=" intoString:nil]) {
		[sc scanUpToString:@">" intoString:&res];
		color = parse_COLOR(res);
	}
	else
		color = @"{\\1c&HFFFFFF&}";

	return color;
}

static NSMutableString *StandardizeSMIWhitespace(NSString *str)
{
	if (!str) return nil;
	NSMutableString *ms = [NSMutableString stringWithString:str];
	[ms replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0,[ms length])];
	[ms replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0,[ms length])];
	[ms replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:0 range:NSMakeRange(0,[ms length])];
	return ms;
}

void SubLoadSMIFromPath(NSString *path, SubSerializer *ss, int subCount)
{
	NSURL *url = [NSURL fileURLWithPath:path];
	SubLoadSMIFromURL(url, ss, subCount);
}

void SubLoadSMIFromURL(NSURL *path, SubSerializer *ss, int subCount)
{
	NSMutableString *smi = StandardizeSMIWhitespace(SubLoadURLWithUnknownEncoding(path));
	if (!smi) return;
		
	NSScanner *sc = [NSScanner scannerWithString:smi];
	NSString *res = nil;
	[sc setCharactersToBeSkipped:nil];
	[sc setCaseSensitive:NO];
	
	NSMutableString *cmt = [NSMutableString string];
	NSArray *subLanguage = parse_STYLE(smi);

	int startTime=-1, endTime=-1, syncTime=-1;
	int cc=1;
	
	enum {
		TAG_INIT,
		TAG_SYNC,
		TAG_P,
		TAG_BR_OPEN,
		TAG_BR_CLOSE,
		TAG_B_OPEN,
		TAG_B_CLOSE,
		TAG_I_OPEN,
		TAG_I_CLOSE,
		TAG_FONT_OPEN,
		TAG_FONT_CLOSE,
		TAG_COMMENT
	} state = TAG_INIT;
	
	do {
		switch (state) {
			case TAG_INIT:
				[sc scanUpToString:@"<SYNC" intoString:nil];
				if ([sc scanString:@"<SYNC" intoString:nil])
					state = TAG_SYNC;
				break;
			case TAG_SYNC:
				[sc scanUpToString:@">" intoString:&res];
				syncTime = parse_SYNC(res);
				if (startTime > -1) {
					endTime = syncTime;
					if (subCount == 2 && cc == 2)
						[cmt insertString:@"{\\an8}" atIndex:0];
					if ((subCount == 1 && cc == 1) || (subCount == 2 && cc == 2)) {
						SubLine *sl = [[SubLine alloc] initWithLine:cmt start:startTime end:endTime];
						[ss addLine:sl];
					}
				}
				startTime = syncTime;
				[cmt setString:@""];
				state = TAG_COMMENT;
				break;
			case TAG_P:
				[sc scanUpToString:@">" intoString:&res];
				cc = parse_P(res, subLanguage);
				[cmt setString:@""];
				state = TAG_COMMENT;
				break;
			case TAG_BR_OPEN:
				[sc scanUpToString:@">" intoString:nil];
				[cmt appendString:@"\\n"];
				state = TAG_COMMENT;
				break;
			case TAG_BR_CLOSE:
				[sc scanUpToString:@">" intoString:nil];
				[cmt appendString:@"\\n"];
				state = TAG_COMMENT;
				break;
			case TAG_B_OPEN:
				[sc scanUpToString:@">" intoString:&res];
				[cmt appendString:@"{\\b1}"];
				state = TAG_COMMENT;
				break;
			case TAG_B_CLOSE:
				[sc scanUpToString:@">" intoString:nil];
				[cmt appendString:@"{\\b0}"];
				state = TAG_COMMENT;
				break;
			case TAG_I_OPEN:
				[sc scanUpToString:@">" intoString:&res];
				[cmt appendString:@"{\\i1}"];
				state = TAG_COMMENT;
				break;
			case TAG_I_CLOSE:
				[sc scanUpToString:@">" intoString:nil];
				[cmt appendString:@"{\\i0}"];
				state = TAG_COMMENT;
				break;
			case TAG_FONT_OPEN:
				[sc scanUpToString:@">" intoString:&res];
				[cmt appendString:parse_FONT(res)];
				state = TAG_COMMENT;
				break;
			case TAG_FONT_CLOSE:
				[sc scanUpToString:@">" intoString:nil];
				[cmt appendString:@"{\\1c&HFFFFFF&}"];
				state = TAG_COMMENT;
				break;
			case TAG_COMMENT:
				[sc scanString:@">" intoString:nil];
				if ([sc scanUpToString:@"<" intoString:&res])
					[cmt appendString:res];
				else
					[cmt appendString:@"<>"];
				if ([sc scanString:@"<" intoString:nil]) {
					if ([sc scanString:@"SYNC" intoString:nil]) {
						state = TAG_SYNC;
						break;
					}
					else if ([sc scanString:@"P" intoString:nil]) {
						state = TAG_P;
						break;
					}
					else if ([sc scanString:@"BR" intoString:nil]) {
						state = TAG_BR_OPEN;
						break;
					}
					else if ([sc scanString:@"/BR" intoString:nil]) {
						state = TAG_BR_CLOSE;
						break;
					}
					else if ([sc scanString:@"B" intoString:nil]) {
						state = TAG_B_OPEN;
						break;
					}
					else if ([sc scanString:@"/B" intoString:nil]) {
						state = TAG_B_CLOSE;
						break;
					}
					else if ([sc scanString:@"I" intoString:nil]) {
						state = TAG_I_OPEN;
						break;
					}
					else if ([sc scanString:@"/I" intoString:nil]) {
						state = TAG_I_CLOSE;
						break;
					}
					else if ([sc scanString:@"FONT" intoString:nil]) {
						state = TAG_FONT_OPEN;
						break;
					}
					else if ([sc scanString:@"/FONT" intoString:nil]) {
						state = TAG_FONT_CLOSE;
						break;
					}
					else {
						[cmt appendString:@"<"];
						state = TAG_COMMENT;
						break;
					}
				}
		}
	} while (![sc isAtEnd]);
}

#pragma mark Obj-C Classes

@implementation SubSerializer
@synthesize finished;
@synthesize lastBeginTime = last_begin_time;
@synthesize lastEndTime = last_end_time;
@synthesize numberOfInputLines = num_lines_input;

-(instancetype)init
{
	if (self = [super init]) {
		lines = [[NSMutableArray alloc] init];
		self.finished = NO;
		self.lastBeginTime = self.lastEndTime = 0;
		self.numberOfInputLines = 0;
	}
	
	return self;
}

-(void)addLine:(SubLine *)line
{
	if (line.beginTime >= line.endTime) {
		if (line.beginTime)
			Codecprintf(NULL, "Invalid times (%lu and %lu) for line \"%s\"", (unsigned long)line.beginTime, (unsigned long)line.endTime, [line.line UTF8String]);
		return;
	}
	
	line.num = num_lines_input++;
	
	NSInteger i = [lines indexOfObject:line inSortedRange:NSMakeRange(0, [lines count])
				   options:NSBinarySearchingInsertionIndex|NSBinarySearchingLastEqual
				   usingComparator:^NSComparisonResult(id a, id b){
		SubLine *al = a, *bl = b;
					   
		if (al.beginTime > bl.beginTime) return NSOrderedDescending;
		if (al.beginTime < bl.beginTime) return NSOrderedAscending;
					   
		if (al.num > bl.num) return NSOrderedDescending;
		if (al.num < bl.num) return NSOrderedAscending;
		return NSOrderedSame;
	}];
	
	[lines insertObject:line atIndex:i];
}

-(SubLine*)copyNextRealSerializedPacket
{
	NSInteger nlines = [lines count];
	SubLine *first = [lines objectAtIndex:0];
	int i;

	if (!finished) {
		if (nlines > 1) {
			NSUInteger maxEndTime = first.endTime;
			
			for (i = 1; i < nlines; i++) {
				SubLine *l = [lines objectAtIndex:i];
				
				if (l.beginTime >= maxEndTime) {
					goto canOutput;
				}
				
				maxEndTime = MAX(maxEndTime, l.endTime);
			}
		}
		
		return nil;
	}
	
canOutput:
	NSMutableString *str = [NSMutableString stringWithString:first.line];
	NSUInteger begin_time = last_end_time, end_time = first.endTime;
	int deleted = 0;
		
	for (i = 1; i < nlines; i++) {
		SubLine *l = [lines objectAtIndex:i];
		if (l.beginTime >= end_time) break;
		
		//shorten packet end time if another shorter time (begin or end) is found
		//as long as it isn't the begin time
		end_time = MIN(end_time, l.endTime);
		if (l.beginTime > begin_time)
			end_time = MIN(end_time, l.beginTime);
		
		if (l.beginTime <= begin_time)
			[str appendString:l.line];
	}
	
	for (i = 0; i < nlines; i++) {
		SubLine *l = [lines objectAtIndex:i - deleted];
		
		if (l.endTime == end_time) {
			[lines removeObjectAtIndex:i - deleted];
			deleted++;
		}
	}
	
	return [[SubLine alloc] initWithLine:str start:begin_time end:end_time];
}

-(SubLine*)getSerializedPacket
{
	NSInteger nlines = [lines count];

	if (!nlines) return nil;
	
	SubLine *nextline = [lines objectAtIndex:0], *ret;
	
	if (nextline.beginTime > last_end_time) {
		ret = [[SubLine alloc] initWithLine:@"\n" start:last_end_time end:nextline.beginTime];
	} else {
		ret = [self copyNextRealSerializedPacket];
	}
	
	if (!ret) return nil;
	
	last_begin_time = ret.beginTime;
	last_end_time   = ret.endTime;
		
	return ret;
}

-(BOOL)isEmpty
{
	return [lines count] == 0;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"lines left: %lu finished inputting: %d",(unsigned long)[lines count],finished];
}
@end

@interface SubLine ()
@property (readwrite, copy) NSString *line;
@end

@implementation SubLine
@synthesize line;
@synthesize beginTime = begin_time;
@synthesize endTime = end_time;
@synthesize num;

-(instancetype)initWithLine:(NSString*)l start:(NSUInteger)s end:(NSUInteger)e
{
	if (self = [super init]) {
		NSInteger length = [l length];
		if (!length || [l characterAtIndex:length-1] != '\n') l = [l stringByAppendingString:@"\n"];
		self.line = l;
		begin_time = s;
		end_time = e;
		num = 0;
	}
	
	return self;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"\"%@\", from %lu s to %lu s",[line substringToIndex:[line length]-1],(unsigned long)begin_time,(unsigned long)end_time];
}
@end

@implementation VobSubSample
@synthesize timeStamp;
@synthesize fileOffset;

- (id)initWithTime:(long)time offset:(long)offset
{
	self = [super init];
	if(!self)
		return self;
	
	timeStamp = time;
	fileOffset = offset;
	
	return self;
}

@end

@interface VobSubTrack ()

@property (copy, readwrite) NSData *privateData;

@end

@implementation VobSubTrack
@synthesize privateData;
@synthesize language;
@synthesize index;

- (NSArray*)samples
{
	return [NSArray arrayWithArray:samples];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
	return [samples countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)initWithPrivateData:(NSData *)idxPrivateData language:(NSString *)lang andIndex:(int)trackIndex
{
	self = [super init];
	if(!self)
		return self;
	
	self.privateData = idxPrivateData;
	self.language = lang;
	self.index = trackIndex;
	samples = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)addSample:(VobSubSample *)sample
{
	[samples addObject:sample];
}

- (void)addSampleTime:(long)time offset:(long)offset
{
	VobSubSample *sample = [[VobSubSample alloc] initWithTime:time offset:offset];
	[self addSample:sample];
}

@end

#pragma mark C++ Wrappers

CXXSubSerializer::CXXSubSerializer() : retainCount(1)
{
	@autoreleasepool {
		priv = (void*)CFBridgingRetain([[SubSerializer alloc] init]);
	}
}

CXXSubSerializer::~CXXSubSerializer()
{
	@autoreleasepool {
		if (priv) {
			CFRelease(priv);
			priv = NULL;
		}
	}
}

void CXXSubSerializer::pushLine(const std::string &cppstr, unsigned long start, unsigned long end)
{
	@autoreleasepool {
		@try {
			NSMutableString *str = [[NSMutableString alloc] initWithBytes:cppstr.c_str() length:cppstr.length() encoding:NSUTF8StringEncoding];
			if (!str) return; // in case of invalid UTF-8?
			[str appendString:@"\n"];
			
			SubLine *sl = [[SubLine alloc] initWithLine:str start:start end:end];
			
			[(__bridge SubSerializer*)priv addLine:sl];
		} @catch(id) {
			Codecprintf(stderr, "Exception occured while reading Matroska subtitles");
		}
	}
}


void CXXSubSerializer::pushLine(const char *line, size_t size, unsigned long start, unsigned long end)
{
	@autoreleasepool {
		@try {
			NSMutableString *str = [[NSMutableString alloc] initWithBytes:line length:size encoding:NSUTF8StringEncoding];
			if (!str) return; // in case of invalid UTF-8?
			[str appendString:@"\n"];
			
			SubLine *sl = [[SubLine alloc] initWithLine:str start:start end:end];
			
			[(__bridge SubSerializer*)priv addLine:sl];
		} @catch(id) {
			Codecprintf(stderr, "Exception occured while reading Matroska subtitles");
		}
	}
}

void CXXSubSerializer::setFinished()
{
	@autoreleasepool {
		((__bridge SubSerializer*)priv).finished = YES;
	}
}

CFDataRef CXXSubSerializer::popPacket(NSUInteger *start, NSUInteger *end)
{
	@autoreleasepool {
		@try {
			SubLine *sl = [(__bridge SubSerializer*)priv getSerializedPacket];
			if (!sl) return NULL;
			*start = sl.beginTime;
			*end   = sl.endTime;
			
			return (CFDataRef)CFBridgingRetain([sl.line dataUsingEncoding:NSUTF8StringEncoding]);
			
		} @catch(id) {
			Codecprintf(stderr, "Exception occured while reading Matroska subtitles");
		}
		return NULL;
	}
}

void CXXSubSerializer::release()
{	
	retainCount--;
	
	if (!retainCount)
		delete this;
}

void CXXSubSerializer::retain()
{
	retainCount++;
}

bool CXXSubSerializer::empty()
{
	@autoreleasepool {
		return [(__bridge SubSerializer*)priv isEmpty];
	}
}
