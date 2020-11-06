//
//  SKTiled+Properties.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
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


extension SKTilemap {
    // MARK: - Properties
    
    /**
     Parse properties from the Tiled TMX file.

     - parameter completion: `Void?` optional completion closure.
    */
    public func parseProperties(completion: (() -> Void)?) {

        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }

        for (attr, value) in properties {

            let lattr = attr.lowercased()

            if ["zdelta", "zdeltaforlayers", "layerdelta"].contains(lattr) {
                zDeltaForLayers = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zDeltaForLayers
            }

            if ["debug", "debugmode", "debugdraw"].contains(lattr) {
                debugDrawOptions = [.drawGrid, .drawBounds]
            }

            if (lattr == "gridcolor") {
                gridColor = SKColor(hexString: value)
                TiledGlobals.default.debug.gridColor = gridColor
                getLayers().forEach { $0.gridColor = gridColor }

                frameColor = gridColor

                // set base layer colors
                defaultLayer.gridColor = gridColor
                defaultLayer.frameColor = frameColor
            }

            if (lattr == "gridopacity") {
                defaultLayer.gridOpacity = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : TiledGlobals.default.debug.gridOpactity
                getLayers().forEach {$0.gridOpacity = self.defaultLayer.gridOpacity}
            }

            if (lattr == "framecolor") {
                frameColor = SKColor(hexString: value)
                getLayers().forEach {$0.frameColor = frameColor}

                // set base layer colors
                defaultLayer.frameColor = frameColor
            }

            if (lattr == "highlightcolor") {
                highlightColor = SKColor(hexString: value)
                getLayers().forEach {$0.highlightColor = highlightColor}

                // set base layer colors
                TiledGlobals.default.debug.tileHighlightColor = highlightColor
                defaultLayer.highlightColor = highlightColor
            }

            // aspect ratio.
            if (lattr == "aspect") {
                yScale *= (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 1
            }

            // initial world scale.
            if (lattr == "worldscale") {
                worldScale = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : worldScale
            }

            if (lattr == "allowzoom") {
                allowZoom = boolForKey(attr)
            }

            if (lattr == "allowmovement") {
                allowMovement = boolForKey(attr)
            }

            if (lattr == "zposition") {
                zPosition = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zPosition
            }

            if (lattr == "tileoverlap") {
                tileOverlap = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : tileOverlap
            }

            if (lattr == "minzoom") {
                zoomConstraints.min = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zoomConstraints.min
            }

            if (lattr == "maxzoom") {
                zoomConstraints.max = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zoomConstraints.max
            }

            if (lattr == "ignorebackground") {
                ignoreBackground = boolForKey(attr)
            }

            if (lattr == "antialiasLines") {
                antialiasLines = boolForKey(attr)
            }

            if (lattr == "autoresize") {
                autoResize = boolForKey(attr)
            }

            if (lattr == "showobjects") {
                showObjects = boolForKey(attr)
            }

            if (lattr == "xgravity") {
                gravity.dx = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 0
            }

            if (lattr == "ygravity") {
                gravity.dy = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 0
            }

            if (lattr == "showgrid") {
                if (boolForKey(attr) == true) {
                    debugDrawOptions.insert(.drawGrid)
                }
            }

            if (lattr == "showbounds") {
                if (boolForKey(attr) == true) {
                    debugDrawOptions.insert(.drawBounds)
                }
            }

            if (lattr == "overlaycolor") {
                overlayColor = SKColor(hexString: value)
            }

            if (lattr == "objectcolor") {
                objectColor = SKColor(hexString: value)
            }
            
            if ["nicename", "displayname"].contains(lattr) {
                displayName = value
            }

            if (lattr == "navigationcolor") {
                navigationColor = SKColor(hexString: value)
            }
            
            if ["enableeffects", "shouldenableeffects"].contains(lattr) {
                shouldEnableEffects = boolForKey(attr)
            }
        }

        if completion != nil { completion!() }
    }
}


extension SKTileset {

    /// Parse the tileset's properties value.
    public func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
         if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }

        for (attr, _) in properties {
            let lattr = attr.lowercased()
            if (lattr == "walkable") {
                if (keyValuePair(key: attr) != nil) {
                    let walkableIDs = integerArrayForKey(attr)
                    log("walkable id: \(walkableIDs)", level: .debug)
                    for id in walkableIDs {
                        if let tiledata = getTileData(localID: id) {
                            tiledata.walkable = true
                        }
                    }
                }
            }
        }


        if completion != nil { completion!() }
    }
}


extension SKTiledLayerObject {

    /// Parse the layer's properties value.
    public func parseProperties(completion: (() -> Void)?) {

        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }

        for (attr, value) in properties {

            let lattr = attr.lowercased()

            if (lattr == "zposition") {
                guard let zpos = Double(value) else { return }
                zPosition = CGFloat(zpos)
            }

            if (lattr == "color") {
                setColor(color: SKColor(hexString: value))
            }

            if (lattr == "backgroundcolor") {
                background.color = SKColor(hexString: value)
                background.colorBlendFactor = 1.0
            }

            if (lattr == "hidden") {
                isHidden = boolForKey(attr)
            }

            if (lattr == "visible") {
                visible = boolForKey(attr)
            }

            if (lattr == "antialiasing") {
                antialiased = boolForKey(attr)
            }


            if (lattr == "drawbounds") {
                if boolForKey(attr) == true {
                    drawBounds()
                }
            }

            if ["navigation", "navigationkey"].contains(lattr) {
                self.navigationKey = value
            }

            if completion != nil { completion!() }
        }
    }

    /**
     Returns a named property for the layer.

     - parameter name: `String` property name.
     - returns: `String?` the property value, or nil if it does not exist.
     */
    public func getValue(forProperty name: String) -> String? {
        return stringForKey(name)
    }

    /**
     Set a property/value pair.

     - parameter name:  `String` property name.
     - parameter value: `String` property value.
     */
    public func setValue(_ value: String, forProperty name: String) {
        properties[name] = value
    }
}


extension SKTileLayer {

    /// Parse the tile layer's properties.
    override public func parseProperties(completion: (() -> Void)?) {
        super.parseProperties(completion: completion)
    }
}


extension SKObjectGroup {

    /// Parse the object group's properties.
    override public func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        for (attr, _ ) in properties {
            let lattr = attr.lowercased()

            if (lattr == "linewidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
        }

        super.parseProperties(completion: completion)
    }
}


extension SKImageLayer {
    
    /// Parse the image layer's properties.
    override public func parseProperties(completion: (() -> Void)?) {
        super.parseProperties(completion: completion)
    }
}


// MARK: - Generic Properties

extension SKTileObject {
    
    /// Parse the object's properties value.
    public func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }
        for (attr, value) in properties {

            let lattr = attr.lowercased()

            if (lattr == "color") {
                setColor(hexString: value)
            }

            if (lattr == "linewidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }

            if (lattr == "zposition") {
                zPosition = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zPosition
            }
        }

        // Physics
        let isDynamic:  Bool = boolForKey("isDynamic")
        let isCollider: Bool = boolForKey("isCollider")

        physicsType = Int(isDynamic) ^ Int(isCollider) == 0 ? .none : (isDynamic == true) ? .dynamic : (isCollider == true) ? .collision : .none
        if completion != nil { completion!() }
    }
}





extension SKTilesetData {
    
    /// Parse the tile data's properties value.
    public func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }

        for (attr, _) in properties {
            let lattr = attr.lowercased()

            if (lattr == "weight") {
                weight = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : weight
            }

            if (lattr == "walkable") {
                walkable = boolForKey(attr)
            }
        }

        if completion != nil { completion!() }
    }
}
