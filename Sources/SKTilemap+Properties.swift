//
//  SKTilemap+Properties.swift
//  SKTiled
//
//  Created by Michael Fessenden on 8/12/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTilemap {
    // MARK: - Properties
    /**
     Parse properties from the Tiled TMX file.
     */
    public func parseProperties(completion: (() -> ())?) {
        for (attr, value) in properties {
            
            if (attr == "name") {
                name = value
            }
            
            if ["debug", "debugMode"].contains(attr){
                debugDraw = boolForKey(value)
                debugMode = boolForKey(value)
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
            
            if (attr == "antialiasLines") {
                antialiasLines = boolForKey(attr)
            }
            
            if (attr == "autoResize") {
                autoResize = boolForKey(attr)
            }
            
            if (attr == "showObjects") {
                showObjects = boolForKey(attr)
            }
            
            if (attr == "xGravity") {
                gravity.dx = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 0
            }
            
            if (attr == "yGravity") {
                gravity.dy = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : 0
            }
            
            if (attr == "showGrid") {
                baseLayer.showGrid = boolForKey(attr)
            }
            
            if (attr == "cropAtBoundary") {
                cropAtBoundary = boolForKey(attr)
            }
            
            if (attr == "overlayColor") {
                overlayColor = SKColor(hexString: value)
            }
        }
        
        if completion != nil { completion!() }
    }
}


public extension SKTileset {
    // MARK: - Properties
    /**
     Parse the tileset's properties value.
     */
    public func parseProperties(completion: (() -> ())?) {
        if completion != nil { completion!() }
    }
}


public extension TiledLayerObject {
    // MARK: - Properties
    /**
     Parse the layer's properties value.
     */
    public func parseProperties(completion: (() -> ())?) {
        
        for (attr, value) in properties {
            
            if (attr == "zPosition") {
                guard let zpos = Double(value) else { return }
                zPosition = CGFloat(zpos)
            }
            
            if (attr == "color") {
                setColor(color: SKColor(hexString: value))
            }
            
            if (attr == "backgroundColor") {
                background.color = SKColor(hexString: value)
                background.colorBlendFactor = 1.0
            }
            
            if (attr == "hidden") {
                isHidden = boolForKey(attr)
            }
            
            if (attr == "visible") {
                visible = boolForKey(attr)
            }
            
            if (attr == "antialiasing") {
                antialiased = boolForKey(attr)
            }
            
            if (attr == "antialiasing") {
                antialiased = boolForKey(attr)
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
        return properties[name]
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


public extension SKTileLayer {
    // MARK: - Properties
    /**
     Parse the tile layer's properties.
    */
    override public func parseProperties(completion: (() -> ())?) {
        super.parseProperties(completion: completion)
    }
}


public extension SKObjectGroup {
    // MARK: - Properties
    /**
     Parse the object group's properties.
    */
    override public func parseProperties(completion: (() -> ())?) {
        for (attr, _ ) in properties {
            if (attr == "lineWidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
        }
        
        super.parseProperties(completion: completion)
    }
}


public extension SKImageLayer {
    // MARK: - Properties
    /**
     Parse the image layer's properties.
    */
    override public func parseProperties(completion: (() -> ())?) {
        super.parseProperties(completion: completion)
    }
}


public extension SKTileObject {
    // MARK: - Properties
    /**
     Parse the object's properties value.
     */
    public func parseProperties(completion: (() -> ())?) {
        for (attr, value) in properties {
            if (attr == "color") {
                setColor(hexString: value)
            }
            
            if (attr == "lineWidth") {
                lineWidth = (doubleForKey(attr) != nil) ? CGFloat(doubleForKey(attr)!) : lineWidth
            }
        }
        
        // Physics
        let isDynamic:  Bool = boolForKey("isDynamic")
        let isCollider: Bool = boolForKey("isCollider")

        physicsType = Int(isDynamic) ^ Int(isCollider) == 0 ? .none : (isDynamic == true) ? .dynamic : .collision

        if completion != nil { completion!() }
    }
}


public extension SKTilesetData {
    // MARK: - Properties
    /**
     Parse the tile data's properties value.
     */
    public func parseProperties(completion: (() -> ())?) {        
        if completion != nil { completion!() }
    }
}
