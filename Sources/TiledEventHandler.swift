//
//  TiledEventHandler.swift
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

import Foundation


enum EventMouseButton: UInt8 {
    case any
    case left
    case right
    case middle
}


/// ## Overview
///
/// Methods that provide *optional* handlers for mouse (macOS) and touch (iOS) events.
///
/// ### Instance Methods
///
/// | Method                   | Description                              | Platform |
/// |:-------------------------|:-----------------------------------------|:--------:|
/// | `mouseOverTileHandler`   | Custom tile mouse over event handler.    |  macOS   |
/// | `mouseOverObjectHandler` | Custom object mouse over event handler.  |  macOS   |
/// | `tileClickedHandler`     | Custom tile mouse click event handler.   |  macOS   |
/// | `objectClickedHandler`   | Custom object mouse click event handler. |  macOS   |
/// | `tileTouchedHandler`     | Custom tile touch event handler.         |   iOS    |
/// | `objectTouchedHandler`   | Custom object touch event handler.       |   iOS    |
///
/// :nodoc:
@objc public protocol TiledEventHandler: class {

    /// Custom mouse over handler for tiles matching the given properties (macOS only).
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - ofType: optional tile type.
    @objc optional func onCreate(globalID: UInt32, ofType: String?) -> ((SKTile) -> ())?
    
    
    #if os(macOS)

    /// Custom mouse over handler for tiles matching the given properties (macOS only).
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - ofType: optional tile type.
    @objc optional func mouseOverTileHandler(globalID: UInt32, ofType: String?) -> ((SKTile) -> ())?


    /// Custom mouse click handler for tiles matching the given properties (macOS only).
    ///
    /// - Parameters:
    ///   - clicks: number of mouse clicks required.
    ///   - globalID: tile global id.
    ///   - ofType: optional tile type.
    ///   - button: mouse button.
    @objc optional func tileClickedHandler(globalID: UInt32, ofType: String?, button: UInt8) -> ((SKTile) -> ())?


    /// Custom mouse over handler for objects matching the given properties (macOS only).
    ///
    /// - Parameters:
    ///   - withID: object id.
    ///   - ofType: optional object type.
    @objc optional func mouseOverObjectHandler(withID: UInt32, ofType: String?) -> ((SKTileObject) -> ())?


    /// Custom mouse click handler for objects matching the given properties (macOS only).
    ///
    /// - Parameters:
    ///   - withID: object id.
    ///   - ofType: optional object type.
    ///   - button: mouse button.
    @objc optional func objectClickedHandler(withID: UInt32, ofType: String?, button: UInt8) -> ((SKTileObject) -> ())?


    #elseif os(iOS)

    /// Custom touch handler for tiles matching the given properties (iOS only).
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - ofType: tile type.
    ///   - userData: dictionary of attributes.
    @objc optional func tileTouchedHandler(globalID: UInt32, ofType: String?, userData: [String: Any]?) -> ((SKTile) -> ())?


    /// Custom touch handler for objects matching the given properties (iOS only).
    ///
    /// - Parameters:
    ///   - withID: object id.
    ///   - ofType: object type.
    ///   - userData: dictionary of attributes.
    @objc optional func objectTouchedHandler(withID: UInt32, ofType: String?, userData: [String: Any]?) -> ((SKTileObject) -> ())?

    #endif
}