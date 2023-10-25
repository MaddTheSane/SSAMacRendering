//
//  AppDelegate.swift
//  SSATestRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Cocoa
import SSAMacRendering
import SSAMacRendering.SubRenderer
import CoreTextAdditions

func createPDF(fromFile inFile: String, toDirectory dir: URL) {
	let ss = SubSerializer()
	var rect = CGRect()
	
	guard let s = autoreleasepool(invoking: { () -> SubCTRenderer? in
		
		guard let header = SubLoadSSAFromPath(inFile, ss) else {
			return nil
		}
		ss.isFinished = true
		
		guard let (headers, styles, _) = parseSSAFile(header) else {
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
	
	let allPDFs = dir.appendingPathComponent("all-CT.pdf")
	guard let pdfA = CGContext(allPDFs as NSURL, mediaBox: &rect, nil) else {
		return
	}
	
	while !ss.isEmpty {
		if let sl = ss.getSerializedPacket(),
			sl.line.count > 1 {
			pdfA.beginPDFPage(nil)
			s.render(packet: sl.line, in: pdfA, width: rect.width, height: rect.height)
			pdfA.endPDFPage()
		}
	}
	pdfA.closePDF()
}

func createPDFWithATSUI(fromFile inFile: String, toDirectory dir: URL) {
	let ss = SubSerializer()
	var rect = CGRect()
	
	guard let s = autoreleasepool(invoking: { () -> SubATSUIRenderer? in
		
		guard let header = SubLoadSSAFromURL(URL(fileURLWithPath: inFile), ss) else {
			return nil
		}
		ss.isFinished = true
		
		guard let (headers, styles, _) = parseSSAFile(header) else {
			return nil
		}
		
		let size: NSSize = {
			let sc = SubContext(scriptType: SubType.SSA, headers: headers, styles: styles, delegate: nil)
			return NSSize(width: sc.resX, height: sc.resY)
		}()
		rect = CGRect(origin: .zero, size: size)
		
		return SubATSUIRenderer(scriptType: SubType.SSA.rawValue, header: header, videoWidth: size.width, videoHeight: size.height)
	}) else {
		return
	}
	
	let allPDFs = dir.appendingPathComponent("all-ATSUI.pdf")
	guard let pdfA = CGContext(allPDFs as NSURL, mediaBox: &rect, nil) else {
		return
	}
	
	while !ss.isEmpty {
		if let sl = ss.getSerializedPacket(),
			sl.line.count > 1 {
			pdfA.beginPDFPage(nil)
			s.render(packet: sl.line, in: pdfA, width: rect.width, height: rect.height)
			pdfA.endPDFPage()
		}
	}
	pdfA.closePDF()
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		createPDF(fromFile: "/Users/cwbetts/mm.ssa", toDirectory: URL(fileURLWithPath: "/Users/cwbetts/Movies"))
		createPDFWithATSUI(fromFile: "/Users/cwbetts/mm.ssa", toDirectory: URL(fileURLWithPath: "/Users/cwbetts/Movies"))
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

