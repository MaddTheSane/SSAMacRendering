//
//  CTRunAdditions.swift
//  CoreTextAdditions
//
//  Created by C.W. Betts on 10/20/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation
import CoreText.CTRun

extension CTRun {
	/// A bitfield passed back by the `CTRun.status` getter that is used to indicate the disposition of the run.
	public typealias Status = CTRunStatus
	
	/// Gets the glyph count for the run.
	///
	/// The number of glyphs that the run contains. It is totally
	/// possible that this function could return a value of zero,
	/// indicating that there are no glyphs in this run.
	public var glyphCount: Int {
		return CTRunGetGlyphCount(self)
	}
	
	/// Returns the attribute dictionary that was used to create the
	/// glyph run.
	///
	/// This dictionary returned is either the same exact one that was
	/// set as an attribute dictionary on the original attributed string
	/// or a dictionary that has been manufactured by the layout engine.
	/// Attribute dictionaries can be manufactured in the case of font
	/// substitution or if they are missing critical attributes.
	public var attributes: [String: Any] {
		return CTRunGetAttributes(self) as! [String: Any]
	}
	
	/// Returns the run's status.
	///
	/// In addition to attributes, runs also have status that can be
	/// used to expedite certain operations. Knowing the direction and
	/// ordering of a run's glyphs can aid in string index analysis,
	/// whereas knowing whether the positions reference the identity
	/// text matrix can avoid expensive comparisons. Note that this
	/// status is provided as a convenience, since this information is
	/// not strictly necessary but can certainly be helpful.
	public var status: Status {
		return CTRunGetStatus(self)
	}
	
	/*
/*!
@function   CTRunGetGlyphsPtr
@abstract   Returns a direct pointer for the glyph array stored in the run.

@discussion The glyph array will have a length equal to the value returned by
CTRunGetGlyphCount. The caller should be prepared for this
function to return NULL even if there are glyphs in the stream.
Should this function return NULL, the caller will need to
allocate their own buffer and call CTRunGetGlyphs to fetch the
glyphs.

@param      run
The run whose glyphs you wish to access.

@result     A valid pointer to an array of CGGlyph structures or NULL.
*/
@available(OSX 10.5, *)
public func CTRunGetGlyphsPtr(_ run: CTRun) -> UnsafePointer<CGGlyph>?


/*!
@function   CTRunGetGlyphs
@abstract   Copies a range of glyphs into user-provided buffer.

@param      run
The run whose glyphs you wish to copy.

@param      range
The range of glyphs to be copied, with the entire range having a
location of 0 and a length of CTRunGetGlyphCount. If the length
of the range is set to 0, then the operation will continue from
the range's start index to the end of the run.

@param      buffer
The buffer where the glyphs will be copied to. The buffer must be
allocated to at least the value specified by the range's length.
*/
@available(OSX 10.5, *)
public func CTRunGetGlyphs(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGGlyph>)
*/
	public var glyphs: AnyRandomAccessCollection<CGGlyph> {
		
		if let preGlyph = CTRunGetGlyphsPtr(self) {
			return AnyRandomAccessCollection(UnsafeBufferPointer(start: preGlyph, count: glyphCount))
		} else {
			var preArr = [CGGlyph](repeating: 0, count: glyphCount)
			CTRunGetGlyphs(self, CFRangeMake(0, 0), &preArr)
			return AnyRandomAccessCollection(preArr)
		}
	}

	public func glyphs(in range: CFRange) -> [CGGlyph] {
		guard range.length != 0 else {
			return []
		}
		var preArr = [CGGlyph](repeating: 0, count: range.length)
		CTRunGetGlyphs(self, range, &preArr)
		return preArr
	}
	
	/*
/*!
@function   CTRunGetPositionsPtr
@abstract   Returns a direct pointer for the glyph position array stored in
the run.

@discussion The glyph positions in a run are relative to the origin of the
line containing the run. The position array will have a length
equal to the value returned by CTRunGetGlyphCount. The caller
should be prepared for this function to return NULL even if there
are glyphs in the stream. Should this function return NULL, the
caller will need to allocate their own buffer and call
CTRunGetPositions to fetch the positions.

@param      run
The run whose positions you wish to access.

@result     A valid pointer to an array of CGPoint structures or NULL.
*/
@available(OSX 10.5, *)
public func CTRunGetPositionsPtr(_ run: CTRun) -> UnsafePointer<CGPoint>?


/*!
@function   CTRunGetPositions
@abstract   Copies a range of glyph positions into a user-provided buffer.

@discussion The glyph positions in a run are relative to the origin of the
line containing the run.

@param      run
The run whose positions you wish to copy.

@param      range
The range of glyph positions to be copied, with the entire range
having a location of 0 and a length of CTRunGetGlyphCount. If the
length of the range is set to 0, then the operation will continue
from the range's start index to the end of the run.

@param      buffer
The buffer where the glyph positions will be copied to. The buffer
must be allocated to at least the value specified by the range's
length.
*/
@available(OSX 10.5, *)
public func CTRunGetPositions(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGPoint>)
*/
	public var positions: AnyRandomAccessCollection<CGPoint> {
		if let preGlyph = CTRunGetPositionsPtr(self) {
			return AnyRandomAccessCollection(UnsafeBufferPointer(start: preGlyph, count: glyphCount))
		} else {
			var preArr = [CGPoint](repeating: CGPoint(), count: glyphCount)
			CTRunGetPositions(self, CFRangeMake(0, 0), &preArr)
			return AnyRandomAccessCollection(preArr)
		}
	}
	
	public func positions(in range: CFRange) -> [CGPoint] {
		guard range.length != 0 else {
			return []
		}
		var preArr = [CGPoint](repeating: CGPoint(), count: range.length)
		CTRunGetPositions(self, range, &preArr)
		return preArr
	}
	
	/*
/*!
@function   CTRunGetAdvancesPtr
@abstract   Returns a direct pointer for the glyph advance array stored in
the run.

@discussion The advance array will have a length equal to the value returned
by CTRunGetGlyphCount. The caller should be prepared for this
function to return NULL even if there are glyphs in the stream.
Should this function return NULL, the caller will need to
allocate their own buffer and call CTRunGetAdvances to fetch the
advances. Note that advances alone are not sufficient for correctly
positioning glyphs in a line, as a run may have a non-identity
matrix or the initial glyph in a line may have a non-zero origin;
callers should consider using positions instead.

@param      run
The run whose advances you wish to access.

@result     A valid pointer to an array of CGSize structures or NULL.
*/
@available(OSX 10.5, *)
public func CTRunGetAdvancesPtr(_ run: CTRun) -> UnsafePointer<CGSize>?


/*!
@function   CTRunGetAdvances
@abstract   Copies a range of glyph advances into a user-provided buffer.

@param      run
The run whose advances you wish to copy.

@param      range
The range of glyph advances to be copied, with the entire range
having a location of 0 and a length of CTRunGetGlyphCount. If the
length of the range is set to 0, then the operation will continue
from the range's start index to the end of the run.

@param      buffer
The buffer where the glyph advances will be copied to. The buffer
must be allocated to at least the value specified by the range's
length.
*/
@available(OSX 10.5, *)
public func CTRunGetAdvances(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGSize>)

	*/
	public var advances: AnyRandomAccessCollection<CGSize> {
		if let preAdv = CTRunGetAdvancesPtr(self) {
			return AnyRandomAccessCollection(UnsafeBufferPointer(start: preAdv, count: glyphCount))
		} else {
			var preArr = [CGSize](repeating: CGSize(), count: glyphCount)
			CTRunGetAdvances(self, CFRangeMake(0, 0), &preArr)
			return AnyRandomAccessCollection(preArr)
		}
	}
	
	public func advances(in range: CFRange) -> [CGSize] {
		guard range.length != 0 else {
			return []
		}
		var preArr = [CGSize](repeating: CGSize(), count: range.length)
		CTRunGetAdvances(self, range, &preArr)
		return preArr
	}
	
/*

/*!
@function   CTRunGetStringIndicesPtr
@abstract   Returns a direct pointer for the string indices stored in the run.

@discussion The indices are the character indices that originally spawned the
glyphs that make up the run. They can be used to map the glyphs in
the run back to the characters in the backing store. The string
indices array will have a length equal to the value returned by
CTRunGetGlyphCount. The caller should be prepared for this
function to return NULL even if there are glyphs in the stream.
Should this function return NULL, the caller will need to allocate
their own buffer and call CTRunGetStringIndices to fetch the
indices.

@param      run
The run whose string indices you wish to access.

@result     A valid pointer to an array of CFIndex structures or NULL.
*/
@available(OSX 10.5, *)
public func CTRunGetStringIndicesPtr(_ run: CTRun) -> UnsafePointer<CFIndex>?


/*!
@function   CTRunGetStringIndices
@abstract   Copies a range of string indices int o a user-provided buffer.

@discussion The indices are the character indices that originally spawned the
glyphs that make up the run. They can be used to map the glyphs
in the run back to the characters in the backing store.

@param      run
The run whose string indices you wish to copy.

@param      range
The range of string indices to be copied, with the entire range
having a location of 0 and a length of CTRunGetGlyphCount. If the
length of the range is set to 0, then the operation will continue
from the range's start index to the end of the run.

@param      buffer
The buffer where the string indices will be copied to. The buffer
must be allocated to at least the value specified by the range's
length.
*/
@available(OSX 10.5, *)
public func CTRunGetStringIndices(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CFIndex>)
	*/
	
	public var stringIndices: AnyRandomAccessCollection<CFIndex> {
		if let preGlyph = CTRunGetStringIndicesPtr(self) {
			return AnyRandomAccessCollection(UnsafeBufferPointer(start: preGlyph, count: glyphCount))
		} else {
			var preArr = [CFIndex](repeating: 0, count: glyphCount)
			CTRunGetStringIndices(self, CFRangeMake(0, 0), &preArr)
			return AnyRandomAccessCollection(preArr)
		}
	}
	
	public func stringIndicies(in range: CFRange) -> [CFIndex] {
		guard range.length != 0 else {
			return []
		}
		var preArr = [CFIndex](repeating: 0, count: range.length)
		CTRunGetStringIndices(self, range, &preArr)
		return preArr
	}
	
	/// Gets the range of characters that originally spawned the glyphs
	/// in the run.
	///
	/// Returns the range of characters that originally spawned the
	/// glyphs. If run is invalid, this will return an empty range.
	public var stringRange: CFRange {
		return CTRunGetStringRange(self)
	}
	
	/// Gets the typographic bounds of the run.
	/// - parameter range:
	/// The range of glyphs to be measured, with the entire range having
	/// a location of `0` and a length of `CTRun.glyphCount`. If the length
	/// of the range is set to `0`, then the operation will continue from
	/// the range's start index to the end of the run.
	public func typographicBounds(for range: CFRange) -> (width: Double, ascent: CGFloat, descent: CGFloat, leading: CGFloat) {
		var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
		let width = CTRunGetTypographicBounds(self, range, &ascent, &descent, &leading)
		return (width, ascent, descent, leading)
	}
	
	/// Calculates the image bounds for a glyph range.
	/// - parameter context:
	/// The context which the image bounds will be calculated for or `nil`,
	/// in which case the bounds are relative to `CGPoint.zero`.
	/// - parameter range: The range of glyphs to be measured, with the
	/// entire range having a location of `0` and a length of
	/// `CTRun.glyphCount`. If the length of the range is set to `0`,
	/// then the operation will continue from the range's start index to
	/// the end of the run.
	/// - returns: A rect that tightly encloses the paths of the run's glyphs. The
	/// rect origin will match the drawn position of the requested range;
	/// that is, it will be translated by the supplied context's text
	/// position and the positions of the individual glyphs. If the run
	/// or range is invalid, `CGRect.null` will be returned.
	///
	/// The image bounds for a run is the union of all non-empty glyph
	/// bounding rects, each positioned as it would be if drawn using
	/// `CTRunDraw` using the current context (for clients linked against
	/// macOS High Sierra or iOS 11 and later) or the text position of
	/// the supplied context (for all others). Note that the result is
	/// ideal and does not account for raster coverage due to rendering.
	/// This function is purely a convenience for using glyphs as an
	/// image and should not be used for typographic purposes.
	public func imageBounds(in range: CFRange, context: CGContext?) -> CGRect {
		return CTRunGetImageBounds(self, context, range)
	}
	
	/// The text matrix needed to draw this run.
	///
	/// To properly draw the glyphs in a run, the fields *'tx'* and *'ty'* of
	/// the `CGAffineTransform` returned by this function should be set to
	/// the current text position.
	public var textMatrix: CGAffineTransform {
		return CTRunGetTextMatrix(self)
	}
	
	/// Draws a complete run or part of one.
	/// - parameter context: The context to draw the run to.
	/// - parameter range:
	/// The range of glyphs to be drawn, with the entire range having a
	/// location of `0` and a length of `CTRun.glyphCount`. If the length
	/// of the range is set to `0`, then the operation will continue from
	/// the range's start index to the end of the run.
	///
	/// This is a convenience call, since the run could also be drawn by
	/// accessing its glyphs, positions, and text matrix. Unlike when
	/// drawing the entire line containing the run with `CTLineDraw`, the
	/// run's underline (if any) will not be drawn, since the underline's
	/// appearance may depend on other runs in the line. This call may
	/// leave the graphics context in any state and does not flush the
	/// context after drawing. This call also expects a text matrix with
	/// *'y'* values increasing from bottom to top; a flipped text matrix
	/// may result in misplaced diacritics.
	public func draw(in context: CGContext, range: CFRange) {
		CTRunDraw(self, context, range)
	}
}
