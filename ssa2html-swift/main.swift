//
//  main.swift
//  ssa2html-swift
//
//  Created by C.W. Betts on 10/25/23.
//  Copyright © 2023 C.W. Betts. All rights reserved.
//

import Foundation
import SSAMacRendering

if CommandLine.arguments.count != 2 {
	exit(1)
}

func makeHTML(from fileURL: URL) -> String {
	return autoreleasepool {
		let ss = SubSerializer()
		let htm = SubHTMLExporter()
		
		//start of lameness
		//it should only have to call subparsessafile here, or something
		guard let header = SubLoadSSAFromURL(fileURL, ss) else {
			return ""
		}
		ss.isFinished = true
		
		guard let (headers, styles, _) = parseSSAFile(header) else {
			return ""
		}
		let sc = SubContext(scriptType: .SSA, headers: headers, styles: styles, delegate: htm)
		//end(?) of lameness
		
		htm.endOfHead()
		
		autoreleasepool {
			while !ss.isEmpty {
				guard let sl = ss.getSerializedPacket() else {
					break
				}
				if sl.line.count == 1 {
					continue
				}
				
				htm.add(sl)
			}
		}
		
		htm.endOfFile()
		
		_=sc
		
		return htm.html
	}
}

let file = CommandLine.arguments[1]
let url = URL(fileURLWithPath: file)

let html = makeHTML(from: url)
puts(html)

