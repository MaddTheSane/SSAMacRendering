//
//  CTFrameAdditions.swift
//  CoreTextAdditions
//
//  Created by C.W. Betts on 11/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation
import CoreText.CTFrame

extension CTFrame {
	/// These constants specify frame progression types.
	///
	/// The lines of text within a frame may be stacked for either
	/// horizontal or vertical text. Values are enumerated for each
	/// stacking type supported by `CTFrame`. Frames created with a
	/// progression type specifying vertical text will rotate lines
	/// 90 degrees counterclockwise when drawing.
	public typealias Progression = CTFrameProgression
	
	/// These constants specify fill rule used by the frame.
	///
	/// When a path intersects with itself, the client should specify which rule to use for deciding the
	/// area of the path.
	public typealias PathFillRule = CTFramePathFillRule
	
	/// Returns the range of characters that were originally requested
	/// to fill the frame.
	///
	/// This function will return a `CFRange` containing the backing
	/// store range of characters that were originally requested
	/// to fill the frame. If the function call is not successful,
	/// then an empty range will be returned.
	public var stringRange: CFRange {
		return CTFrameGetStringRange(self)
	}
	
	/// Returns the range of characters that actually fit in the
	/// frame.
	///
	/// This can be used to chain frames, as it returns the range of
	/// characters that can be seen in the frame. The next frame would
	/// start where this frame ends.
	public var visibleStringRange: CFRange {
		return CTFrameGetVisibleStringRange(self)
	}
	
	/// Returns the frame attributes used to create the frame.
	public var frameAttributes: [String: Any]? {
		return CTFrameGetFrameAttributes(self) as! [String: Any]?
	}
	
	/// The path used to create the frame.
	public var path: CGPath {
		return CTFrameGetPath(self)
	}
	
	/// An array of lines stored in the frame.
	public var lines: [CTLine] {
		return CTFrameGetLines(self) as! [CTLine]
	}
	
	/// Copies a range of line origins for a frame.
	/// - parameter range:
	/// The range of line origins you wish to copy. If the length of the
	/// range is set to `0`, then the copy operation will continue from
	/// the range's start index to the last line origin.
	///
	/// This function will copy a range of `CGPoint` structures. Each
	/// CGPoint is the origin of the corresponding line in the array of
	/// lines returned by `CTFrame.lines`, relative to the origin of the
	/// frame's path. The maximum number of line origins returned by
	/// this function is the count of the array of lines.
	public func lineOrigins(in range: CFRange) -> [CGPoint] {
		let actualCount: Int
		if range.length == 0 {
			actualCount = lines.count
		} else {
			actualCount = range.length
		}
		var origins = [CGPoint](repeating: CGPoint(), count: actualCount)
		CTFrameGetLineOrigins(self, range, &origins)
		return origins
	}
	
	/// Draws an entire frame to a context.
	/// - parameter context: The context to draw the frame to.
	///
	/// This function will draw an entire frame to the context. Note
	/// that this call may leave the context in any state and does not
	/// flush it after the draw operation.
	public func draw(in context: CGContext) {
		CTFrameDraw(self, context)
	}
}
