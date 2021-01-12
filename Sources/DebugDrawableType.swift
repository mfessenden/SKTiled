//
//  DebugDrawableType.swift
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

import Foundation
import SpriteKit


/// ## Overview
///
/// The `DebugDrawableType` protocol provides an interface to visualizing various object attributes, such as displaying a visual grid over the container, or highlighting object bounds.

/// ### Properties
///
/// | Property             | Description                        |
/// |:---------------------|:-----------------------------------|
/// | `debugDrawOptions`   | Debugging visualization options    |
///
@objc public protocol DebugDrawableType: class {

    /// Optionset of properties for visualizing node attributes.
    @objc var debugDrawOptions: DebugDrawOptions { get set }
}


// TODO: implement this
public struct DebugDrawProperties {
    
    /// Object frame color.
    public var frameColor: SKColor = TiledGlobals.default.debug.frameColor
    
    /// Grid color.
    public var gridColor: SKColor = TiledGlobals.default.debug.gridColor
    
    /// Highlight color.
    public var highlightColor: SKColor = TiledGlobals.default.debug.tileHighlightColor
}



// TODO: add frameColor, hightlightColor?
// TODO: merge this with `highlightNode` function
// TODO: add draw method?


// MARK: - Extensions



extension DebugDrawableType {

    // MARK: - Convenience Properties

    /// Property to show/hide all `SKTileObject` objects in this object.
    public var isShowingObjectBounds: Bool {
        get {
            return debugDrawOptions.contains(.drawObjectFrames)
        } set {
            if (newValue == true) {
                debugDrawOptions.insert(.drawObjectFrames)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawObjectFrames)
            }
        }
    }

    /// Property to show/hide container bounds.
    public var isShowingBounds: Bool {
        get {
            return debugDrawOptions.contains(.drawFrame)
        } set {
            if (newValue == true) {
                debugDrawOptions.insert(.drawFrame)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawFrame)
            }
        }
    }

    /// Property to show/hide container tile grid.
    public var isShowingTileGrid: Bool {
        get {
            return debugDrawOptions.contains(.drawGrid)
        } set {
            if (newValue == true) {
                debugDrawOptions.insert(.drawGrid)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawGrid)
            }
        }
    }

    /// Property to show/hide both grid & bounds.
    public var isShowingTileGridAndBounds: Bool {
        get {
            return debugDrawOptions.contains(.drawGrid) && debugDrawOptions.contains(.drawFrame)
        } set {
            guard (newValue != isShowingTileGridAndBounds) else {
                return
            }
            
            if (newValue == true) {
                debugDrawOptions.insert(.drawFrame)
                debugDrawOptions.insert(.drawGrid)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawFrame)
                debugDrawOptions = debugDrawOptions.subtracting(.drawGrid)
            }
        }
    }
    
    /// Property to show/hide container pathfinding graph.
    public var isShowingGridGraph: Bool {
        get {
            return debugDrawOptions.contains(.drawGraph)
        } set {
            if (newValue == true) {
                debugDrawOptions.insert(.drawGraph)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawGraph)
            }
        }
    }
}



extension DebugDrawOptions {


    /// Descriptor values for each option.
    public var strings: [String] {
        
        var result: [String] = []

        if self.contains(.drawGrid) {
            result.append("Draw Grid")
        }
        
        if self.contains(.drawFrame) {
            result.append("Draw Bounds")
        }
        
        if self.contains(.drawGraph) {
            result.append("Draw Graphs")
        }
        
        if self.contains(.drawObjectFrames) {
            result.append("Draw Object Bounds")
        }
        
        if self.contains(.drawAnchor) {
            result.append("Draw Anchor")
        }
        
        return result
    }

    /// Default options.
    public static let `default`: DebugDrawOptions = []

    /// All options.
    public static let all: DebugDrawOptions = [.drawGrid, .drawFrame, .drawGraph, .drawObjectFrames, .drawAnchor]
}


/// :nodoc:
extension DebugDrawOptions: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    public var description: String {
        guard (strings.isEmpty == false) else {
            return "none"
        }
        return "[ \(strings.joined(separator: ", ")) ]"
    }

    public var debugDescription: String {
        return description
    }
    
    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {
        return Mirror(reflecting: DebugDrawOptions.self)
    }
}

