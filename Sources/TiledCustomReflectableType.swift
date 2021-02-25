//
//  TiledCustomReflectableType.swift
//  SKTiled
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

import SpriteKit


/// The `TiledCustomReflectableType` protocol outlines internal debugging elements that can be used to describe objects in debugging interfaces.
///
/// ### Properties
///
/// - `tiledElementName`: Tiled element type.
/// - `tiledNodeNiceName`: proper node name.
/// - `tiledIconName`: node icon representation.
/// - `tiledListDescription`: description of the node used for list or outline views.
/// - `tiledMenuItemDescription`: description of the node used in dropdown & popu menus.
/// - `tiledDisplayItemDescription`: shortened debug description used for debug output text.
/// - `tiledHelpDescription`: description of the node type used for help features.
/// - `tiledTooltipDescription`: description suitable for a UI widget to display as a tooltip.
///
@objc public protocol TiledCustomReflectableType: class {

    /// Returns the internal **Tiled** node type, for XML nodes, or our custom types.
    @objc optional var tiledElementName: String { get }

    /// Returns a "nice" node name for usage in UI elements.
    @objc optional var tiledNodeNiceName: String { get }

    /// Returns the internal **Tiled** node type icon.
    @objc optional var tiledIconName: String { get }

    /// A description of the node used in list or outline views.
    @objc optional var tiledListDescription: String { get }

    /// A description of the node used in dropdown & popu menus.
    @objc optional var tiledMenuItemDescription: String { get }

    /// A shortened debug description of the node used for debug output text; (ie: `<SKObjectGroup 'Characters-Upper'>`)
    @objc optional var tiledDisplayItemDescription: String { get }
    
    /// A description of the node type used for help features; (ie: `"Container node for Tiled layer types."`)
    @objc optional var tiledHelpDescription: String { get }
    
    /// Returns a string suitable for a UI widget to display as a tooltip. Ideally this represents a path for objects referenced in dropdown menus.
    @objc optional var tiledTooltipDescription: String { get }

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
    
    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        let textString = (text != nil) ? ": '\(text!)'" : ""
        return #"<\#(className)\#(nameString)\#(textString)>"#
    }
    
    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit label node."
    }
}




/// :nodoc:
extension SKSpriteNode: TiledCustomReflectableType {

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
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Sprite\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit sprite node."
    }
}


/// :nodoc:
extension SKCropNode: TiledCustomReflectableType {

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
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Crop\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit crop node."
    }
}


/// :nodoc:
extension SKEffectNode: TiledCustomReflectableType {

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
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Effect\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit effect node. Used to contain content that may be rendered to a private buffer."
    }
}



/// :nodoc:
extension SKShapeNode: TiledCustomReflectableType {

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Shape"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "shape-icon"
    }

    /// A description of the node used in list or outline views.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Shape\(nameString)"
    }

    /// A description of the node used in dropdown & popu menus.
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Shape\(nameString)"
    }
    
    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }

    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit shape node."
    }
}



// MARK: - Deprecations


/// :nodoc:
extension SKTilemap {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension TiledLayerObject {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public override var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKTile {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public override var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKTileObject {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public override var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKSpriteNode {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKCropNode {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKEffectNode {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}


/// :nodoc:
extension SKShapeNode {

    /// A description of the node used in dropdown & popu menus.
    @available(*, deprecated, renamed: "tiledMenuItemDescription")
    @objc public var tiledMenuDescription: String {
        return tiledMenuItemDescription
    }
}
