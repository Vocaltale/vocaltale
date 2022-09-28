//
//  URL+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import CryptoKit
import Foundation

private let kSHA256BufferSize = 1024 * 1024
private let kSHA256ReadSize = 64 * 1024 * 1024

extension URL {
    var cleanFilename: String {
        var retval = self
        let component: String = self.lastPathComponent

        let nsString = component as NSString
        let results =
            (try? NSRegularExpression(pattern: "\\.(.*)\\.icloud", options: []))?.matches(
                in: component,
                options: [],
                range: NSRange(location: 0, length: nsString.length)
            ).map { match in
                (0..<match.numberOfRanges).map {
                    match.range(at: $0).location == NSNotFound
                        ? "" : nsString.substring(with: match.range(at: $0))
                }
            } ?? []

        if let result = results.first?[1] {
            retval = self.deletingLastPathComponent().appending(component: result)
        }

        let components = retval.pathComponents
        if let index = components.firstIndex(of: "Documents") {
            let strings: [String] = Array(components[index..<components.count])
            debugPrint(strings)

            return strings.joined(separator: "/")
        }

        return retval.relativeString
    }

    var ubiquityFilename: String {
        let component: String = self.lastPathComponent

        return ".\(component).icloud"
    }

    //    var sanitized: URL {
    //        let filename = self.cleanFilename
    //
    //        return self.deletingLastPathComponent().appendingPathComponent(filename)
    //    }

    var iCloud: URL {
        let filename = self.ubiquityFilename

        return self.deletingLastPathComponent().appendingPathComponent(filename)
    }
}

extension URL {
    var isDirectory: Bool? {
        do {
            return (try resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory)
        } catch {
            return nil
        }

    }

    var exists: Bool {
        return FileManager.default.fileExists(atPath: self.absoluteString)
    }

    func mkdirp() throws -> Bool {
        var isDirectory: ObjCBool = false

        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(
                at: self,
                withIntermediateDirectories: true,
                attributes: nil
            )

            return true
        }

        return isDirectory.boolValue
    }

    func hash() throws -> Int {
        let file = try FileHandle(forReadingFrom: self)

        var sha256 = SHA256()
        var buffer = Data()
        do {

            var count = 1

            while count > 0 {
                if let data = try file.read(upToCount: kSHA256ReadSize),
                   !data.isEmpty {
                    count = data.count
                    buffer += data
                    while buffer.count >= kSHA256BufferSize {
                        let subdata = buffer.subdata(in: 0..<kSHA256BufferSize)

                        sha256.update(data: subdata)

                        buffer.removeSubrange(0..<kSHA256BufferSize)
                    }
                } else {
                    count = 0
                }
            }

            if !buffer.isEmpty {
                sha256.update(data: buffer)
            }
        } catch {
            try? file.close()
            throw error
        }

        do {
            try file.close()
        } catch {}

        let digest = sha256.finalize()

        var retval: Int = 0
        for byte in digest {
            retval ^= Int(byte)

            let extra = retval & 0xff00_0000
            retval <<= 8

            retval ^= extra
        }

        return retval
    }
}
