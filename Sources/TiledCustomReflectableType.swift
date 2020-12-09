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
/// | ---------------------- | ------------------------------------------- |
/// | `tiledNodeName`        | Tiled node type                             |
/// | `tiledNodeNiceName`    | Proper node name                            |
/// | `tiledIconName`        | Node icon representation                    |
/// | `tiledListDescription` | Description of the node used for list views |
/// | `tiledDescription`     | Description of the node                     |
///
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

    // TODO: this should really be a different protocol.

    /// Dump the current object's properties to the console.
    @objc optional func dumpStatistics()
}



// TODO: see `menuDescription` attributes

// from: https://stackoverflow.com/a/36021870/832404
public struct ShortCodeGenerator {

    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let minBase : UInt32 = 32
    private static let maxBase : UInt32 = 62

    /// Generate a shortened code string of the given length.
    ///
    /// - Parameters:
    ///   - length: string length.
    /// - Returns: unique id string.
    static public func getCode(length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(minBase, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }

    /// Generate a shortened code string of the given length and the given base.
    ///
    /// - Parameters:
    ///   - base: base number.
    ///   - length: string length.
    /// - Returns: unique id string.
    static public func getCode(withBase base: UInt32, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
}



// MARK: - Extensions


extension TiledCustomReflectableType {

    /// Returns an array of `SKTiled` protocol conformance.
    ///
    /// - Returns: array of protocol name.s
    func protocolConformance() -> [String] {
        var output: [String] = []

        /*
        DebugDrawableType
        TiledAttributedType
        TiledCustomReflectableType
        TiledEventHandler
        TiledGeometryType
        TiledMappableGeometryType
        TiledObjectType
        TiledOverlayType
        TiledSceneCameraDelegate
        TiledSceneDelegate
        TilemapDelegate
        TilesetDataSource
        */

        if let _ = self as? DebugDrawableType {
            output.append("DebugDrawableType")
        }
        if let _ = self as? TiledAttributedType {
            output.append("TiledAttributedType")
        }

        if let _ = self as? TiledEventHandler {
            output.append("TiledEventHandler")
        }

        if let _ = self as? TiledGeometryType {
            output.append("TiledGeometryType")
        }
        if let _ = self as? TiledMappableGeometryType {
            output.append("TiledMappableGeometryType")
        }
        if let _ = self as? TiledObjectType {
            output.append("TiledObjectType")
        }
        if let _ = self as? TiledOverlayType {
            output.append("TiledOverlayType")
        }
        if let _ = self as? TiledSceneCameraDelegate {
            output.append("TiledSceneCameraDelegate")
        }
        if let _ = self as? TiledSceneDelegate {
            output.append("TiledSceneDelegate")
        }
        if let _ = self as? TilemapDelegate {
            output.append("TilemapDelegate")
        }
        if let _ = self as? TilesetDataSource {
            output.append("TilesetDataSource")
        }

        return output
    }

    public func outputProtocols(_ prefix: String = "⭑") {
        let nodeName = tiledNodeNiceName ?? tiledNodeName ?? "Unknown"
        var outputString = "\(prefix) [\(nodeName)]: protocols: "
        let allProtocols = protocolConformance()

        let pCount = allProtocols.count
        if (pCount == 0) {
            return
        }
        for (pindex, pname) in allProtocols.enumerated() {
            let isLastP = (pindex == pCount - 1)
            let comma = (isLastP == true) ? "" : ", "
            outputString += "'\(pname)'\(comma)"
        }
        print(outputString)
    }


    // DOCSTRING: reword this.

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

        if let nodeName = tiledNodeName {
            result["tiled-node-name"] = nodeName
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

        if let nodeDesc = tiledDescription {
            result["tiled-node-desc"] = nodeDesc
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
