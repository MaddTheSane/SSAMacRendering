import AppKit

public extension NSBezierPath {
    
	convenience init(path: CGPath) {
        self.init()
        
		let pathPtr = UnsafeMutablePointer<NSBezierPath>.allocate(capacity: 1)
		pathPtr.initialize(to: self)
        
		let infoPtr = UnsafeMutableRawPointer(pathPtr)
        
        // I hope the CGPathApply call manages the deallocation of the pointers passed to the applier
        // function, but I'm not sure.
		path.apply(info: infoPtr) { (infoPtr, elementPtr) -> Void in
            let path = infoPtr!.assumingMemoryBound(to: NSBezierPath.self).pointee
            let element = elementPtr.pointee
            
            let pointsPtr = element.points
            
            switch element.type {
			case .moveToPoint:
				path.move(to: pointsPtr.pointee)
                
			case .addLineToPoint:
				path.line(to: pointsPtr.pointee)

			case .addQuadCurveToPoint:
				let firstPoint = pointsPtr.pointee
				let secondPoint = pointsPtr.successor().pointee
                
				if #available(macOS 14.0, *) {
					path.curve(to: secondPoint, controlPoint: firstPoint)
				} else {
					let currentPoint = path.currentPoint
					let x = (currentPoint.x + 2 * firstPoint.x) / 3
					let y = (currentPoint.y + 2 * firstPoint.y) / 3
					let interpolatedPoint = CGPoint(x: x, y: y)
					
					let endPoint = secondPoint
					path.curve(to: endPoint, controlPoint1: interpolatedPoint, controlPoint2: interpolatedPoint)
				}

			case .addCurveToPoint:
                let firstPoint = pointsPtr.pointee
                let secondPoint = pointsPtr.successor().pointee
				let thirdPoint = pointsPtr.advanced(by: 2).pointee

				path.curve(to: thirdPoint, controlPoint1: firstPoint, controlPoint2: secondPoint)
                
			case .closeSubpath:
				path.close()
            }
            
			pointsPtr.deinitialize(count: 1)
        }
    }
	
	var quartzPath: CGPath? {
		guard elementCount != 0 else {
			return nil
		}
		
		let path = CGMutablePath()
		var points = [NSPoint(), NSPoint(), NSPoint()]
		var didClosePath = true
		
		for i in 0..<elementCount {
			switch element(at: i, associatedPoints: &points) {
			case .moveToBezierPathElement:
				path.move(to: points[0])
				
			case .lineToBezierPathElement:
				path.addLine(to: points[0])
				didClosePath = false
				
			case .cubicCurveTo:
				path.addCurve(to: points[0], control1: points[1], control2: points[2])
				didClosePath = false
				
			case .closePathBezierPathElement:
				path.closeSubpath()
				didClosePath = true
				
			case .quadraticCurveTo:
				path.addQuadCurve(to: points[0], control: points[1])
			}

		}
		
		// Be sure the path is closed or Quartz may not do valid hit detection.
		if !didClosePath {
			path.closeSubpath()
		}
		
		return path.copy()
	}
}
