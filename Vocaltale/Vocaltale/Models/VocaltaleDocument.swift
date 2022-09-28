//
//  VocaltaleDocument.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

class VocaltaleDocument: NSDocument {
    override func read(
        from fileWrapper: FileWrapper,
        ofType typeName: String
    ) throws {
        debugPrint(#function, "???")
        //        if let url = fileURL {
        //            debugPrint("opening \(url)")
        //            let pathExtension = url.pathExtension
        //            if UTType(filenameExtension: pathExtension, conformingTo: kDefaultProjectUTType) != nil {
        //                if LibraryService.instance.openLibrary(from: url) == .loaded {
        //                    return
        //                }
        //            }
        //
        //            LibraryService.instance.importFiles(from: url)
        //        }
    }
}
