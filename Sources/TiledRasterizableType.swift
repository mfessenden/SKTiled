//
//  TiledRasterizableType.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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

import SpriteKit


/// ## Overview
///
/// The `TiledRasterizableType` protocol describes an object that can.
///
/// ### Instance Methods
///
/// | Method            | Description                       |
/// |:------------------|:----------------------------------|
/// | `rasterize`       | rasterize the object to an image. |
/// :nodoc:
@objc public protocol TiledRasterizableType {

    /// Rasterize the current object to an image file.
    ///
    /// - Parameters:
    ///   - to: output image path.
    ///   - filtering: texture filtering.
    /// - Returns: node texture image.
    @objc optional func rasterize(to: URL, filtering: SKTextureFilteringMode) -> CGImage?
}


// MARK: - Extensions

/// :nodoc:
extension SKNode: TiledRasterizableType {

    /// Rasterize the current object to an image file.
    ///
    /// - Parameters:
    ///   - to: output image path.
    ///   - filtering: texture filtering.
    /// - Returns: node texture image.
    @objc public func rasterize(to: URL,
                                filtering: SKTextureFilteringMode = SKTextureFilteringMode.nearest) -> CGImage? {

        guard let scene = scene,
              let view = scene.view,
              let texture = view.texture(from: self) else {
            return nil
        }

        texture.filteringMode = filtering
        let cgImage = texture.cgImage()

        // write image to disk
        if (writeCGImage(cgImage, to: to) == true) {

        }
        return cgImage
    }
}
