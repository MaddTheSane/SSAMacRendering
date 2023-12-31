/*
 * SubParsing.h
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

#ifndef __SUBIMPORT_H__
#define __SUBIMPORT_H__

#include <sys/cdefs.h>
#include <CoreFoundation/CoreFoundation.h>

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubLine : NSObject
{
@private
	NSString *line;
	NSUInteger begin_time, end_time;
	NSInteger num; //!< line number, used only by SubSerializer
}
@property (readonly, copy) NSString *line;
@property NSUInteger beginTime;
@property NSUInteger endTime;
@property NSInteger num; //!< line number, used only by SubSerializer

- (instancetype)initWithLine:(NSString*)l start:(NSUInteger)s end:(NSUInteger)e;
@end

@interface SubSerializer : NSObject
{
@private
	//! input lines, sorted by: 1. beginning time, 2. original insertion order.
	NSMutableArray<SubLine*> *lines;
	BOOL finished;
	
	NSUInteger last_begin_time, last_end_time;
	NSInteger num_lines_input;
}

@property (assign, getter=isFinished) BOOL finished;
@property (readonly, getter=isEmpty) BOOL empty;
@property NSUInteger lastBeginTime;
@property NSUInteger lastEndTime;
@property NSInteger numberOfInputLines;

-(void)addLine:(SubLine *)sline;
-(nullable SubLine*)getSerializedPacket;
@end

@interface VobSubSample : NSObject
{
@private
	long		timeStamp;
	long		fileOffset;
}
@property long timeStamp;
@property long fileOffset;

- (instancetype)initWithTime:(long)time offset:(long)offset;
@end

@interface VobSubTrack : NSObject <NSFastEnumeration>
{
@private
	NSData			*privateData;
	NSString		*language;
	NSInteger		index;
	NSMutableArray<VobSubSample*>	*samples;
}

@property (copy, readonly) NSData *privateData;
@property (copy) NSString *language;
@property NSInteger index;
@property (copy, readonly) NSArray<VobSubSample*> *samples;

- (instancetype)initWithPrivateData:(NSData *)idxPrivateData language:(NSString *)lang andIndex:(int)trackIndex;
- (void)addSample:(VobSubSample *)sample;
- (void)addSampleTime:(long)time offset:(long)offset;

@end

__BEGIN_DECLS

NSString *_Nullable SubLoadSSAFromPath(NSString *path, SubSerializer *ss);
NSString *_Nullable SubLoadSSAFromURL(NSURL *path, SubSerializer *ss);
NSString *_Nullable SubLoadSSAFromNSData(NSData *data, SubSerializer *ss);
void SubLoadSRTFromPath(NSString *path, SubSerializer *ss);
void SubLoadSRTFromURL(NSURL *path, SubSerializer *ss);
void SubLoadSMIFromPath(NSString *path, SubSerializer *ss, int subCount);
void SubLoadSMIFromURL(NSURL *path, SubSerializer *ss, int subCount);

__END_DECLS

NS_ASSUME_NONNULL_END


#endif // ___OBJC__

#ifdef __cplusplus
#include <string>

CF_ASSUME_NONNULL_BEGIN

// TODO: make this work/use shared_ptr or similar?
class CXXSubSerializer
{
	void *_Nullable priv;
	int retainCount;
	
public:
	CXXSubSerializer();
	virtual ~CXXSubSerializer();
	
	void pushLine(const char *line, size_t size, unsigned long start, unsigned long end);
	void pushLine(const std::string &cppstr, unsigned long start, unsigned long end);
	void setFinished();
	CFDataRef _Nullable popPacket(unsigned long *start, unsigned long *end) CF_RETURNS_RETAINED;
	void release();
	void retain();
	bool empty();
};

CF_ASSUME_NONNULL_END

#endif // __cplusplus

#endif // __SUBIMPORT_H__
