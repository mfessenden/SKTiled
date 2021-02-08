//
//  TestController.swift
//  SKTiledTests
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import XCTest
@testable import SKTiled


enum ResourceMode {
    case none
    case tmx
    case tsx
}



/// Test global id matching & parsing.
public class TestController: NSObject {

    /// Default singleton instance.
    public static var `default` : TestController {
        return sharedTestController
    }

    /// Bundle path.
    public var testBundle: URL

    /// Array of test resources.
    public var resources: [URL] = []

    /// Default initializer.
    public override init() {
        testBundle = Bundle.init(for: type(of: self)).bundleURL
        super.init()

        if (resources.isEmpty) {
            scanForResources(url: testBundle)
        }
    }

    /// Scan the test bundle for resource types.
    ///
    /// - Parameter url: resource search path.
    private func scanForResources(url: URL) {
        let fm = FileManager.default
        resources = fm.listFiles(path: url.path, withExtensions: ["tmx", "tsx", "tx", "png"])
    }

    /// Return a named resource, given its filename. ( filename is **just** the filename, ie: `data.json` ).
    ///
    /// - Parameters:
    ///   - named: file name.
    ///   - withExtension: file extension (optional)
    public func getResource(named: String, withExtension: String? = nil) -> URL? {
        var result: URL?
        let filenameToSearchFor = (withExtension == nil) ? named.basename : "\(named.basename).\(withExtension!)"
        for item in resources {
            if (item.basename == filenameToSearchFor) || (item.filename == filenameToSearchFor){
                result = item
            }
        }
        return result
    }

    /// Load and return a named resource.
    ///
    /// - Parameters:
    ///   - named: file name.
    ///   - withExtension: file extension (optional).
    public func loadResource(named: String, withExtension: String? = nil) -> TiledObjectType? {
        var result: TiledObjectType?
        let filenameToLoad = (withExtension == nil) ? named : "\(named).\(withExtension!)"
        let mode: ResourceMode = (filenameToLoad.fileExtension == "tmx") ? ResourceMode.tmx : ResourceMode.tsx

        switch mode {
            case .tmx:
                result = loadTilemap(fileNamed: filenameToLoad)
            case .tsx:
                result = loadTileset(fileNamed: filenameToLoad)
            default:
                break
        }
        return result
    }

    /// Load and return the named tilemap.
    ///
    /// - Parameter fileNamed: tilemap filename.
    /// - Returns: tilemap instance.
    internal func loadTilemap(fileNamed: String) -> SKTilemap? {
        return SKTilemap.load(tmxFile: fileNamed)
    }

    /// Load and return the named tileset.
    ///
    /// - Parameter fileNamed: tileset filename.
    /// - Returns: tileset instance.
    internal func loadTileset(fileNamed: String) -> SKTileset? {
        let tilesets = SKTileset.load(tsxFiles: [fileNamed])
        return tilesets.first
    }
}


let sharedTestController = TestController()


// MARK: - Extensions


extension FileManager {

    /// Returns an array of files in the given directory matching the given file extensions.
    ///
    /// - Parameters:
    ///   - path: search directory.
    ///   - withExtensions: file extensions to search for.
    func listFiles(path: String, withExtensions: [String] = []) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls: [URL] = []
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }

            let url = URL(fileURLWithPath: s, relativeTo: baseurl)
            let pathExtension = url.pathExtension.lowercased()

            if withExtensions.contains(pathExtension) || (withExtensions.isEmpty) {
                urls.append(url)
            }
        })
        return urls
    }
}


extension String {

    /// Returns a url for the string.
    var url: URL {
        return URL(fileURLWithPath: self.expanded)
    }

    /// Expand the users home path.
    var expanded: String {
        return NSString(string: self).expandingTildeInPath
    }

    /// Returns the url parent directory.
    var parentURL: URL {
        var path = URL(fileURLWithPath: self.expanded)
        path.deleteLastPathComponent()
        return path
    }

    /// Returns the filename if string is a url.
    var filename: String {
        return FileManager.default.displayName(atPath: self.url.path)
    }

    /// Returns the file basename.
    var basename: String {
        return self.url.deletingPathExtension().lastPathComponent
    }

    /// Returns the file extension.
    var fileExtension: String {
        return self.url.pathExtension
    }
}
