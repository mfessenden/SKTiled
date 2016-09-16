//
//  SKTilemap+Properties.swift
//  SKTilemap
//
//  Created by Michael Fessenden on 8/12/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTilemap {
    /**
     Parse properties from the Tiled tmx file.
     */
    public func parseProperties() {
        for (attr, value) in properties {
            
            if (attr == "name") {
                name = value
            }
            
            if (attr == "debug") {
                debugDraw = boolForKey(value)
            }
            
            if (attr == "gridColor") {
                gridColor = SKColor(hexString: value)
                allLayers().forEach {$0.gridColor = gridColor}
            }
            
            if (attr == "gridOpacity") {
                baseLayer.gridOpacity = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 0.10
                allLayers().forEach {$0.gridOpacity = self.baseLayer.gridOpacity}
            }
            
            if (attr == "frameColor") {
                frameColor = SKColor(hexString: value)
                allLayers().forEach {$0.frameColor = frameColor}
            }
            
            if (attr == "highlightColor") {
                highlightColor = SKColor(hexString: value)
                allLayers().forEach {$0.highlightColor = highlightColor}
            }
            
            // initial world scale.
            if (attr == "worldScale") {
                worldScale = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : worldScale
            }
            
            if (attr == "allowZoom") {
                allowZoom = boolForKey(attr)
            }
            
            if (attr == "allowMovement") {
                allowMovement = boolForKey(attr)
            }
            
            if (attr == "zPosition") {
                zPosition = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : zPosition
            }
            
            // aspect scaling
            if (attr == "aspect") {
                yScale *= (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 1
            }
            
            if (attr == "lineWidth") {
                //lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
            
            if (attr == "tileOverlap") {
                tileOverlap = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : tileOverlap
            }
            
            if (attr == "minZoom") {
                minZoom = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : minZoom
            }
            
            if (attr == "maxZoom") {
                maxZoom = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : maxZoom
            }
            
            if (attr == "ignoreBackground") {
                ignoreBackground = boolForKey(attr)
        }
    }
}
}


public extension SKTileset {
    /**
     Parse the tileset's properties value.
     */
    public func parseProperties() {}
}


public extension TiledLayerObject {
    
    /**
     Parse the nodes properties value.
     */
    public func parseProperties() {
        
        for (attr, value) in properties {
            
            if (attr == "zPosition") {
                guard let zpos = Double(value) else { return }
                zPosition = CGFloat(zpos)
            }
            
            if (attr == "color") {
                setColor(color: SKColor(hexString: value))
            }
            
            if (attr == "hidden") {
                isHidden = boolForKey(attr)
            }
            
            if (attr == "visible") {
                visible = boolForKey(attr)
            }
        }
    }
    
    /**
     Returns a named property for the layer.
     
     - parameter name: `String` property name.
     
     - returns: `String?` the property value, or nil if it does not exist.
     */
    public func getValue(forProperty name: String) -> String? {
        return properties[name]
    }
    
    /**
     Add a property.
     
     - parameter name:  `String` property name.
     - parameter value: `String` property value.
     */
    public func setValue(_ value: String, forProperty name: String) {
        properties[name] = value
    }
}



public extension SKTileLayer {
    /**
     Parse the tile layer's properties.
    */
    override public func parseProperties() {
        super.parseProperties()
    }
}


public extension SKObjectGroup {
    /**
     Parse the object groups properties.
    */
    override public func parseProperties() {
        super.parseProperties()
        for (attr, value) in properties {
            if (attr == "lineWidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
        }
    }
}


public extension SKImageLayer {
    /**
     Parse the image layer's properties.
    */
    override public func parseProperties() {
        super.parseProperties()
    }
}


public extension SKTileObject {
    /**
     Parse the object's properties value.
     */
    public func parseProperties() {
        for (attr, value) in properties {
            if (attr == "color") {
                setColor(hexString: value)
            }
            
            if (attr == "lineWidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
        }
    }
}


public extension SKTilesetData {
    /**
     Parse the data's properties value.
     */
    public func parseProperties() {
        for (attr, value) in properties {
            //print("\(id): \(attr) = \(value)")
        }
    }
}
