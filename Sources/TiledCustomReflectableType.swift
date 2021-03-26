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
/// - `tiledNodeType`: SKTiled node type.
/// - `tiledNodeNiceName`: proper node name.
/// - `tiledIconName`: node icon representation.
/// - `tiledListDescription`: description of the node used for list or outline views.
/// - `tiledMenuItemDescription`: description of the node used in dropdown & popu menus.
/// - `tiledDisplayItemDescription`: shortened debug description used for debug output text.
/// - `tiledHelpDescription`: description of the node type used for help features.
/// - `tiledTooltipDescription`: description suitable for a UI widget to display as a tooltip.
///
@objc public protocol TiledCustomReflectableType: AnyObject {

    /// Returns the internal **Tiled** node type, for XML nodes, or our custom types.
    @objc optional var tiledElementName: String { get }

    /// Returns the internal node type, used for UI Inspector.
    @objc optional var tiledNodeType: String { get }
    
    /// Returns a "nice" node name for usage in UI elements.
    @objc optional var tiledNodeNiceName: String { get }

    /// Returns the internal **Tiled** node type icon.
    @objc optional var tiledIconName: String { get }

    /// A description of the node used in list or outline views.
    @objc optional var tiledListDescription: String { get }

    /// A description of the node used in dropdown & popu menus.
    @objc optional var tiledMenuItemDescription: String { get }

    /// A shortened debug description of the node used for debug output text, such as the demo HUD.
    ///
    ///  (ie: `<SKGroupLayer 'Upper': (7 children)>`)
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
    
    /// Returns an array of Tiled node attributes, used for debugging.
    ///
    /// - Returns: dictionary of attributes.
    func tiledAttributes() -> [String: Any] {
        
        var result: [String: Any] = [:]
        
        if let nodeName = tiledElementName {
            result["tiled-element-name"] = nodeName
        }
        
        if let nodeType = tiledNodeType {
            result["tiled-node-type"] = nodeType
        }
        
        if let nodeNiceName = tiledNodeNiceName {
            result["tiled-node-nicename"] = nodeNiceName
        }
        
        if let nodeIconName = tiledIconName {
            result["tiled-node-icon"] = nodeIconName
        }
        
        if let nodeListDescription = tiledListDescription {
            result["tiled-node-listdesc"] = nodeListDescription
        }
        
        if let nodeDesc = tiledHelpDescription {
            result["tiled-help-desc"] = nodeDesc
        }
        
        if let skNode = self as? SKNode {
            
            let thisNodeType = String(describing: type(of: skNode))
            // string
            result["sk-node-type"] = thisNodeType
            
            // bool
            result["sk-node-hidden"] = skNode.isHidden
            result["sk-node-paused"] = skNode.isPaused
            
            // cgfloat
            result["sk-node-posx"] = skNode.position.x
            result["sk-node-posy"] = skNode.position.y
            result["sk-node-scalex"] = skNode.xScale
            result["sk-node-scaley"] = skNode.yScale
            result["sk-node-posz"] = skNode.zPosition
            result["sk-node-speed"] = skNode.speed
            result["sk-node-alpha"] = skNode.alpha
            result["sk-node-rotz"] = skNode.zRotation.degrees()
            
            for (attr, value) in skNode.getAttrs() {
                
                // TODO: figure out override rules here
                if (result[attr] != nil) {
                    result[attr] = value
                } else {
                    if let stringValue = result[attr] as? String {
                        print("⚠️ WARNING: duplicate value for \(thisNodeType) attribute '\(attr)' - current: '\(stringValue)', new: '\(value)'")
                    }
                }
            }
            
            if let skNodeName = skNode.name {
                result["sk-node-name"] = skNodeName
            }
            
            if let sprite = self as? SKSpriteNode {
                if let spriteTexture = sprite.texture {
                    result["sk-sprite-texture"] = spriteTexture
                }
            }
            
            
            
            if let tileNode = self as? SKTile {
                print("▸ selected tile '\(tileNode.description)' -> '\(tileNode.tileData.description)'")
                
                result["tile-node-tilesizew"] = tileNode.tileSize.width
                result["tile-node-tilesizeh"] = tileNode.tileSize.height
                
                result["tile-node-gid"] = tileNode.tileData.globalID
                result["tile-node-realgid"] = tileNode.realTileId
                result["tile-node-localid"] = tileNode.tileData.id
                result["tile-node-tileset"] = tileNode.tileData.tileset.name
                result["tile-node-tileset-first"] = tileNode.tileData.tileset.firstGID
                result["tile-node-fliph"] = tileNode.isFlippedHorizontally
                result["tile-node-flipv"] = tileNode.isFlippedVertically
                result["tile-node-flipd"] = tileNode.isFlippedDiagonally
                
                if let tileTexture = tileNode.texture {
                    result["tile-node-texture"] = tileTexture
                }
            }
            
            if let objNode = self as? SKTileObject {
                result["obj-node-id"] = objNode.id
                result["obj-node-sizew"] = objNode.size.width
                result["obj-node-sizeh"] = objNode.size.height
                result["obj-node-camvis"] = objNode.visibleToCamera
                
                // add proxy data
                if let objProxy = objNode.proxy {
                    if let proxyName = objProxy.name {
                        result["obj-node-proxy"] = proxyName
                    }
                }
                
                
                if (objNode.globalID != nil) {
                    result["obj-node-gid"] = objNode.globalID!
                }
            }
            
            if let cameraNode = self as? SKTiledSceneCamera {
                result["cam-node-allowzoom"] = cameraNode.allowZoom
                result["cam-node-zoom"] = cameraNode.zoom
                result["cam-node-zoomclamping"] = cameraNode.zoomClamping
            }
        }
        
        return result
    }
}


/// :nodoc:
extension SKLabelNode: TiledCustomReflectableType {

    
    @objc public var tiledNodeType: String {
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
    
    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        let textString = (text != nil) ? ": '\(text!)'" : ""
        return #"<\#(className)\#(nameString)\#(textString)>"#
    }
    
    /// A description of the node type used for help features.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit label node."
    }
}




/// :nodoc:
extension SKSpriteNode: TiledCustomReflectableType {
    
    /// Returns the internal node type for use with the Inspector.
    @objc public var tiledNodeType: String {
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

    /// A description of the node used in list or outline views.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Sprite\(nameString)"
    }

    /// A description of the node used in dropdown & popu menus.
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Sprite\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node type used for help features.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit sprite node."
    }
}


/// :nodoc:
extension SKCropNode: TiledCustomReflectableType {
    
    /// Returns the internal node type for use with the Inspector.
    @objc public var tiledNodeType: String {
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

    /// A description of the node used in list or outline views.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Crop\(nameString)"
    }

/// A description of the node used in dropdown & popu menus.
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Crop\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node type used for help features.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit crop node."
    }
}


/// :nodoc:
extension SKEffectNode: TiledCustomReflectableType {
    
    /// Returns the internal node type for use with the Inspector.
    @objc public var tiledNodeType: String {
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

    /// A description of the node used in list or outline views.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Effect\(nameString)"
    }

/// A description of the node used in dropdown & popu menus.
    @objc public var tiledMenuItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return "Effect\(nameString)"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        return #"<\#(className)\#(nameString)>"#
    }
    
    /// A description of the node type used for help features.
    @objc public var tiledHelpDescription: String {
        return "SpriteKit effect node. Used to contain content that may be rendered to a private buffer."
    }
}



/// :nodoc:
extension SKShapeNode: TiledCustomReflectableType {
    
    /// Returns the internal node type for use with the Inspector.
    @objc public var tiledNodeType: String {
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

    /// A description of the node type used for help features.
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
