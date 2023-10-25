//
//  main.swift
//  ssa2pdf-CT-Swift
//
//  Created by C.W. Betts on 10/19/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation
import CoreGraphics
import SSAMacRendering

func createPDF(fromFile inFile: String, toDirectory dir: String) {
	let ss = SubSerializer()
	var rect = CGRect()
	
	guard let s = autoreleasepool(invoking: { () -> SubCTRenderer? in
		
		guard let header = SubLoadSSAFromPath(inFile, ss) else {
			return nil
		}
		ss.isFinished = true
		
		guard let (headers, styles, _) = SubParseSSAFile(header) else {
			return nil
		}
		
		let size: NSSize = {
			let sc = SubContext(scriptType: SubType.SSA, headers: headers, styles: styles, delegate: nil)
			return NSSize(width: sc.resX, height: sc.resY)
		}()
		rect = CGRect(origin: .zero, size: size)
		
		return SubCTRenderer(scriptType: SubType.SSA, header: header, videoWidth: size.width, videoHeight: size.height)
	}) else {
		return
	}
	
	let allPDFs = URL(fileURLWithPath: dir).appendingPathComponent("all-CT.pdf")
	guard let pdfA = CGContext(allPDFs as NSURL, mediaBox: &rect, nil) else {
		return
	}
	
	while !ss.isEmpty {
		autoreleasepool(invoking: { () -> Void in
			if let sl = ss.getSerializedPacket(),
				sl.line.count > 1 {
				pdfA.beginPDFPage(nil)
				s.render(packet: sl.line, in: pdfA, width: rect.width, height: rect.height)
				pdfA.endPDFPage()
			}
		})
	}
	pdfA.closePDF()
}

guard CommandLine.arguments.count == 3 else {
	exit(1)
}

createPDF(fromFile: CommandLine.arguments[1], toDirectory: CommandLine.arguments[2])

print("Done!")

