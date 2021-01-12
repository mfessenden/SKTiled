//
//  TiledObjectType.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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

import SpriteKit


/// ## Overview
///
/// The `TiledObjectType` protocol defines a basic type used throughout the API.
///
///
/// ### Properties
///
/// | Property           | Description                                     |
/// |:-------------------|:------------------------------------------------|
/// | `uuid`             | Unique object id.                               |
/// | `type`             | Tiled object type.                              |
///
@objc public protocol TiledObjectType: TiledCustomReflectableType {

    /// Unique object id (layer & object names may not be unique).
    var uuid: String { get }

    /// Object type property.
    var type: String! { get set }
}



// MARK: - Extensions

/// :nodoc:
extension TiledObjectType {

    /// Shortened unique id string.
    public var shortId: String {
        return uuid.components(separatedBy: "-").first ?? "NULL"
    }

    /// Allows the type to be used in a hashable data structure.
    ///
    /// - Parameter hasher: hasher instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}




/// :nodoc: Typealias for v1.2 compatibility.
public typealias SKTiledObject = TiledObjectType
