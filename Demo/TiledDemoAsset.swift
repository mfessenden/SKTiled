//
//  TiledDemoAsset.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation


/// :nodoc:
public struct TiledDemoAsset {

    /// Asset url.
    var url: URL

    /// Inidcates the asset is a user asset.
    var isUserAsset: Bool

    /// Default initializer.
    ///
    /// - Parameters:
    ///   - fileurl: file url.
    ///   - isUser: asset is a user asset.
    init(_ fileurl: URL, isUser: Bool) {
        url = fileurl
        isUserAsset = isUser
    }
}


// MARK: - Extensions


/// :nodoc:
extension TiledDemoAsset {

    /// Indicates the asset is a Tiled tilemap file.
    var isTilemap: Bool {
        return url.pathExtension.lowercased() == "tmx"
    }

    /// Indicates the asset is a Tiled tileset file.
    var isTileset: Bool {
        return url.pathExtension.lowercased() == "tsx"
    }

    /// Indicates the asset is a Tiled template file.
    var isTemplate: Bool {
        return url.pathExtension.lowercased() == "tx"
    }

    /// Indicates the asset is an image file.
    var isImageType: Bool {
        return TiledGlobals.default.validImageTypes.contains(url.pathExtension.lowercased())
    }

    var isBundled: Bool {
        return url.isBundled
    }

    var relativePath: String {
        return url.relativePath
    }

    var filename: String {
        return url.filename
    }

    var basename: String {
        return url.basename
    }
}
