//
//  main.swift
//  ssa2pdf-Swift
//
//  Created by C.W. Betts on 8/4/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation
import CoreGraphics
import SSAMacRendering
import SSAMacRendering.SubContext
import SSAMacRendering.SubCoreTextRenderer
import SSAMacRendering.SubImport
import SSAMacRendering.SubParsing
import SSAMacRendering.SubRenderer
import SSAMacRendering.SubUtilities

func createPDF(fromFile inFile: String, toDirectory dir: String) {
	let ss = SubSerializer()
	var rect = CGRect()
	
	guard let s = autoreleasepool(invoking: { () -> SubCoreTextRenderer? in
		
		guard let header = SubLoadSSAFromPath(inFile, ss) else {
			return nil
		}
		ss.isFinished = true
		
		guard let (headers, styles, _) = parseSSAFile(header) else {
			return nil
		}
		
		let size: NSSize = {
			let sc = SubContext(scriptType: .SSA, headers: headers, styles: styles, delegate: nil)
			return NSSize(width: sc.resX, height: sc.resY)
		}()
		rect = CGRect(origin: .zero, size: size)
		
		return SubCoreTextRenderer(scriptType: .SSA, header: header, videoWidth: size.width, videoHeight: size.height)
	}) else {
		return
	}
	
	let allPDFs = URL(fileURLWithPath: dir).appendingPathComponent("all.pdf")
	guard let pdfA = CGContext(allPDFs as NSURL, mediaBox: &rect, nil) else {
		return
	}
	
	while !ss.isEmpty {
		autoreleasepool(invoking: { () -> Void in
			if let sl = ss.getSerializedPacket(),
				!sl.line.isEmpty {
				pdfA.beginPDFPage(nil)
				s.render(packet: sl.line, in: pdfA, size: rect.size)
				pdfA.endPDFPage()
			}
		})
	}
	pdfA.closePDF()
}

if CommandLine.arguments.count != 3 {
	exit(1)
}

createPDF(fromFile: CommandLine.arguments[1], toDirectory: CommandLine.arguments[2])

print("Done!")
