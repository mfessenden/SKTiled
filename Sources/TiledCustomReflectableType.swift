//
//  TiledCustomReflectableType.swift
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
/// The `TiledCustomReflectableType` protocol outlines internal debugging elements that can be used to query objects for state changes.
///
///
/// ### Properties
///
/// | Property               | Description                                 |
/// | -----------------------| ------------------------------------------- |
/// | `tiledNodeName`        | Tiled node type                             |
/// | `tiledNodeNiceName`    | Proper node name                            |
/// | `tiledIconName`        | Node icon representation                    |
/// | `tiledListDescription` | Description of the node used for list views |
/// | `tiledDescription`     | Description of the node                     |
/// :nodoc:
@objc public protocol TiledCustomReflectableType: class {

    /// Returns the internal **Tiled** node type, for XML nodes, or our custom types.
    @objc optional var tiledNodeName: String { get }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc optional var tiledNodeNiceName: String { get }

    /// Returns the internal **Tiled** node type icon.
    @objc optional var tiledIconName: String { get }

    /// A description of the node used in list views.
    @objc optional var tiledListDescription: String { get }

    /// A description of the node.
    @objc optional var tiledDescription: String { get }

    /// Dump the current object's properties to the console.
    @objc optional func dumpStatistics()
}




// MARK: - Extensions


extension TiledCustomReflectableType {

    /// Creates a new string representing a source string with a line of symbols below it.
    ///
    /// - Parameters:
    ///   - string: source string.
    ///   - symbol: prefix symbol.
    ///   - colon: use a colon.
    /// - Returns: underlined string.
    func underlined(for string: String,
                    symbol: String? = nil,
                    colon: Bool = true) -> String {

        let symbolString = symbol ?? "#"
        let colonString = (colon == true) ? ":" : ""
        let spacer = String(repeating: " ", count: symbolString.count)
        let formattedString = "\(symbolString)\(spacer)\(string)\(colonString)"
        let underlinedString = String(repeating: "-", count: formattedString.count)
        return "\n\(formattedString)\n\(underlinedString)\n"
    }
}


/// :nodoc:
extension SKLabelNode: TiledCustomReflectableType {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "label"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Label"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "label-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Label\(nameString)"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "SpriteKit label node."
    }
}


/// :nodoc:
extension SKSpriteNode: TiledCustomReflectableType {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "sprite"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Sprite Node"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "sprite-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Sprite\(nameString)"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "SpriteKit sprite node."
    }
}


/// :nodoc:
extension SKCropNode: TiledCustomReflectableType {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "crop"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Crop Node"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "crop-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Crop\(nameString)"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "SpriteKit crop node."
    }
}

/// :nodoc:
extension SKEffectNode: TiledCustomReflectableType {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "effect"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Effect Node"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "effect-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Effect\(nameString)"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "SpriteKit effect node. Used to contain content that may be rendered to a private buffer."
    }
}



/// :nodoc:
extension SKShapeNode: TiledCustomReflectableType {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "shape"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Shape"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "shape-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Shape\(nameString)"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "SpriteKit shape node."
    }
}
