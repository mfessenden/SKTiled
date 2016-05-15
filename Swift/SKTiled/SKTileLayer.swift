//
//  SKTileLayer.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// MARK: - Base Layer Class

public class TiledLayerObject: SKNode {
    
    public var tilemap: SKTilemap
    public var mapSize: MapSize                     // map size, ie: 28 x 36
    public var uuid: String = NSUUID().UUIDString   // unique layer id
    public var index: Int = 0                       // index of the layer in the tmx file
    // properties
    public var properties: [String: String] = [:]   // generic layer properties
    
    // size & anchor point
    public var orientation: TilemapOrientation { return tilemap.orientation }
    public var size: CGSize { return mapSize.renderSize }
    public var mapAnchorPoint: CGPoint { return tilemap.anchorPoint }
    
    // colors
    public var gridColor = SKColor.blackColor()    
    public var offset: CGPoint = CGPointZero       // layer offset value
    
    // blending/visibility
    public var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = opacity }
    }
    
    public var visible: Bool {
        get { return !self.hidden }
        set { self.hidden = !visible }
    }
    
    public init?(layerName: String, tileMap: SKTilemap, attributes: [String: String]) {
        
        self.tilemap = tileMap
        self.mapSize = tileMap.mapSize
        super.init()
        self.name = layerName
        
        // layer offset
        var offsetx: CGFloat = 0
        var offsety: CGFloat = 0
        
        if let offsetX = attributes["offsetx"] {
            offsetx = CGFloat(Double(offsetX)!)
        }
        
        if let offsetY = attributes["offsety"] {
            offsety = CGFloat(Double(offsetY)!)
        }
        
        self.offset = CGPointMake(offsetx, offsety)
        
        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = Bool(Int(visibility)!)
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
    }

    public init(layerName: String, tileMap: SKTilemap){
        // create a unique id right away
        self.tilemap = tileMap
        self.mapSize = tileMap.mapSize
        super.init()
        self.name = layerName
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Coordinates
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter x: `Int` y-coordinate.
     - parameter y: `Int` x-coordinate.
     
     - returns: `CGPoint` position in layer.
     */
    public func pointForCoordinate(coord: TileCoord) -> CGPoint {
        var point = CGPointZero
        
        if (orientation == .Orthogonal) {
            let xpos = Int(coord.x) * Int(mapSize.tileSize.width) + Int(mapAnchorPoint.x * mapSize.tileSize.width)
            let ypos = Int(coord.y) * Int(-mapSize.tileSize.height) - Int(mapSize.tileSize.height - mapAnchorPoint.y * mapSize.tileSize.height)
            point = CGPointMake(CGFloat(xpos), CGFloat(ypos))
        }
        
        // apply the layer offset (if any)
        point.x = point.x + (offset.x - mapAnchorPoint.x * offset.x)
        point.y = point.y - (offset.y - mapAnchorPoint.y * offset.y)
        
        return point
    }
    
    /**
     Returns a tile coordinate for a point in the layer.
     
     - parameter point:   `CGPoint` position in layer (in pixels).
     - parameter offsetX: `CGFloat` offset in X.
     - parameter offsetY: `CGFloat` offset in Y.
     
     - returns: `TileCoord` coordinate for the point.
     */
    public func coordinateForPoint(point: CGPoint, offsetX: CGFloat=0, offsetY: CGFloat=0) -> TileCoord {
        var xpos = point.x - (self.offset.x * mapAnchorPoint.x) + (offsetX - mapAnchorPoint.x * offsetX )
        var ypos = point.y + (self.offset.y * mapAnchorPoint.y) - (offsetY - mapAnchorPoint.y * offsetY )
        
        if (orientation == .Orthogonal) {
            xpos = point.x / mapSize.tileSize.width
            ypos = point.y / -mapSize.tileSize.height
        }
        return TileCoord(Int(xpos), Int(ypos))
    }
    
    // MARK: - Properties
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
    
    // MARK: - Adding & Removing Nodes
    /**
     Add a node at the given coordinates. By default, the zPositon 
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter zPosition: `CGFloat` z-position.
     */
    public func addNode(node: SKNode, _ x: Int=0, _ y: Int=0, zPosition: CGFloat=0) {
        addChild(node)
        node.position = pointForCoordinate(TileCoord(x, y))
        node.zPosition = zPosition != 0 ? zPosition : self.zPosition + tilemap.zDeltaForLayers
    }

    // MARK: - Future Stuff
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    public func pruneTiles(outsideOf: CGRect) {
        /* override in subclass */
    }
    
    /**
     Flatten (render) the tile layer.
     */
    public func flattenLayer() {
        /* override in subclass */
    }
    
    override public var hashValue: Int {
        return self.uuid.hashValue
    }
}


// MARK: - Tiled Layer

public class SKTileLayer: TiledLayerObject {
    
    private typealias TilesArray = Array2D<SKTile>
    
    // container for the tile sprites
    private var tiles: TilesArray
    public var render: Bool = false                 // render tile layer as a single image
    
    // MARK: - Init
    
    override public init(layerName: String, tileMap: SKTilemap) {
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        // name, width and height are required
        guard let layerName = attributes["name"] else { return nil }
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tiles
    /**
     Add tile data to the layer.
     
     - parameter data: `[Int]` tile data.
     
     - returns: `Bool` data is valid.
     */
    public func setLayerData(data: [Int]) -> Bool {
        if !(data.count==mapSize.count) {
            print("[SKTileLayer]: ERROR: invalid data size: \(data.count), expected: \(mapSize.count)")
            return false
        }
        
        var errorCount: Int = 0
        for index in data.indices {
            let gid = data[index]
            
            // skip empty tiles
            if (gid == 0) { continue }
            
            var coord = TileCoord(index % Int(mapSize.width), index / Int(mapSize.width))
            let tile = addTileAtCoord(coord, gid: gid)
            if (tile == nil) {
                errorCount += 1
            }
        }
        
        if (errorCount != 0){
            print("[SKTileLayer]: \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.")
        }
        
        //return errorCount == 0
        return true
    }
    
    /**
     Add a tile at the given coordinate.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - parameter gid: `Int` tile id.
     
     - returns: `SKTile?` tile.
     */
    public func addTileAtCoord(coord: TileCoord, gid: Int) -> SKTile? {
        //let zDelta = tilemap.zDeltaForLayers
        if let tileData = tilemap.getTileData(gid) {
            let tile = SKTile(data: tileData)
            
            // set the layer property
            tile.layer = self
            self.tiles[Int(coord.x), Int(coord.y)] = tile
            
            tile.position = pointForCoordinate(coord)
            //tile.zPosition = CGFloat(index) * zDelta
            addChild(tile)
            return tile
        }
        return nil
    }
}


// object group draw order
public enum ObjectGroupDrawOrder: String {
    case TopDown
    case Manual
}


// MARK: - Objects Group

public class SKObjectGroup: TiledLayerObject {
    
    public var color: SKColor = SKColor(red: 255/200, green: 255/160, blue: 255/164, alpha: 1.0)
    public var drawOrder: ObjectGroupDrawOrder = ObjectGroupDrawOrder.TopDown
    private var objects: Set<SKTileObject> = []
    
    /// Returns the number of objects in this layer.
    public var count: Int {
        return objects.count
    }
    
    // MARK: - Init
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
        
        // set objects color
        if let layerColor = attributes["color"] {
            self.color = SKColor.fromHexCode(layerColor)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Objects
    
    /**
     Add an object to the objects set.
     
     - parameter object:    `SKTileObject` object.
     - parameter withColor: `SKColor?` optional override color (otherwise defaults to parent layer color).
     
     - returns: `SKTileObject?` added object.
     */
    public func addObject(object: SKTileObject, withColor: SKColor? = nil) -> SKTileObject? {
        if objects.contains({ $0.hashValue == object.hashValue }) {
            return nil
        }
        // if the override color is nil, use the layer color
        let objectColor: SKColor = (withColor == nil) ? self.color : withColor!
        
        object.setColor(objectColor)
        objects.insert(object)
        object.layer = self
        addChild(object)
        return object
    }
    
    public func objectNames() -> [String] {
        return objects.flatMap({$0.name})
    }
    
    /**
     Returns an object with the given id.
     
     - parameter id: `Int` Object id
     
     - returns: `SKTileObject?`
     */
    public func getObject(id id: Int) -> SKTileObject? {
        if let index = objects.indexOf( { $0.id == id } ) {
            return objects[index]
        }
        return nil
    }
    
    /**
     Return objects of a given type.
     
     - parameter type: `String` object type.
     
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects(ofType type: String) -> [SKTileObject] {
        return objects.filter( {$0.type == type})
    }
    
    /**
     Returns an object with the given name.
     
     - parameter name: `String` Object name.
     
     - returns: `SKTileObject?`
     */
    public func getObject(named name: String) -> SKTileObject? {
        if let index = objects.indexOf( { $0.name == name } ) {
            return objects[index]
        }
        return nil
    }
}


// MARK: - Image Layer

public class SKImageLayer: TiledLayerObject {
    
    public var image: String!                       // image name for layer
    public var sprite: SKSpriteNode?                // sprite (private)
    
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
    }
    
    /**
     Set the layer image as a sprite.
     
     - parameter named: `String` image name.
     */
    public func setLayerImage(named: String) {
        self.image = named
        
        let texture = SKTexture(imageNamed: named)
        let textureSize = texture.size()
        texture.filteringMode = .Nearest
        
        self.sprite = SKSpriteNode(texture: texture)
        addChild(self.sprite!)
        
        self.sprite!.position.x += textureSize.width / 2
        // if we're going to flip coordinates, this should be +=
        self.sprite!.position.y -= textureSize.height / 2.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// MARK - Extensions

extension TiledLayerObject {
    
    public func pointForCoordinate(x: Int, _ y: Int) -> CGPoint {
        return self.pointForCoordinate(TileCoord(x, y))
    }
    
    /**
     Returns the center point of a layer.
     */
    public var center: CGPoint {
        return CGPointMake((size.width / 2) - (size.width * mapAnchorPoint.x), (size.height / 2) - (size.height * mapAnchorPoint.y))
    }
    
    /**
     Calculate the distance from the layer's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVectorMake(dx, dy)
    }
    
    /// visualize the layer grid.
    public var visualizeGrid: Bool {
        get{
            return childNodeWithName("DEBUG_GRID") != nil
        } set {
            childNodeWithName("DEBUG_GRID")?.removeFromParent()
            
            if (newValue == true) {
                let texture = mapSize.generateGridTexture(2, gridColor: self.gridColor)
                // create the debugging node
                let gridObject = SKSpriteNode(texture: texture, color: SKColor.clearColor(), size: mapSize.renderSize)
                gridObject.name = "DEBUG_GRID"
                addChild(gridObject)
                gridObject.zPosition = CGFloat(tilemap.lastIndex + 1) * tilemap.zDeltaForLayers
                gridObject.alpha = 0.15
                
                let xpos = mapSize.renderSize.width  * mapAnchorPoint.x
                let ypos = -mapSize.renderSize.height * mapAnchorPoint.y
                
                gridObject.position.x = xpos
                gridObject.position.y = ypos
            }
        }
    }
    
    /**
     Returns a string representation of the layer.
     
     - returns: `String?` layer type.
     */
    public func typeForLayer() -> String? {
        // query the layer type
        var layerType: String? = nil
        if let _ = self as? SKTileLayer { layerType = "tile" }
        if let _ = self as? SKObjectGroup { layerType = "object" }
        if let _ = self as? SKImageLayer { layerType = "image" }
        return layerType
    }
    
    override public var description: String { return "Layer: \"\(name!)\"" }
    override public var debugDescription: String { return description }
}


public extension SKTileLayer {
    
    /// Returns a count of valid tiles.
    public var tileCount: Int {
        return self.validTiles().count
    }
    
    /**
     Returns only tiles that are valid.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func validTiles() -> [SKTile] {
        return tiles.flatMap({$0})
    }
}


public extension String {
    /**
     Returns an array of hexadecimal components.
     
     - returns: `[String]?` hexadecimal components.
     */
    public func hexComponents() -> [String?] {
        let code = self
        let offset = code.hasPrefix("#") ? 1 : 0
        let start: String.Index = code.startIndex
        return [
            code[start.advancedBy(offset)..<start.advancedBy(offset + 2)],
            code[start.advancedBy(offset + 2)..<start.advancedBy(offset + 4)],
            code[start.advancedBy(offset + 4)..<start.advancedBy(offset + 6)]
        ]
    }
}


public extension SKColor {
    
    /**
     Returns an SKColor from a hexidecimal string.
     
     - parameter code:  `String` hexidecimal code.
     - parameter alpha: `Double` alpha value.
     
     - returns: `SKColor`
     */
    public class func fromHexCode(code: String, alpha: Double=1.0) -> SKColor {
        let rgbValues = code.hexComponents().map {
            (component: String?) -> CGFloat in
            if let hex = component {
                var rgb: CUnsignedInt = 0
                if NSScanner(string: hex).scanHexInt(&rgb) {
                    return CGFloat(rgb) / 255.0
                }
            }
            return 0.0
        }
        return SKColor(red: rgbValues[0], green: rgbValues[1], blue: rgbValues[2], alpha: 1.0)
    }
}
