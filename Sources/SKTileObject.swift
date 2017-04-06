//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit

/** 
 Describes the `SKTileObject` shape type.
 
 - rectangle:  rectangular shape
 - ellipse:    circular shape
 - polygon:    closed polygon
 - polyline:   open polygon
 */
public enum SKObjectType: String {
    case rectangle
    case ellipse
    case polygon
    case polyline
}


/**
 Represents the object's physics body type.
 
 - `none`:      object has no physics properties.
 - `dynamic`:   object is an active physics body.
 - `collision`: object is a passive physics body.
 */
public enum CollisionType {
    case none
    case dynamic
    case collision
}


/**
 Label description orientation.

 - `above`: labels are rendered above the object.
 - `below`: labels are rendered below the object.
 */
internal enum LabelPosition {
    case above
    case below
}


/**
 The `SKTileObject` object represents a Tiled object type (rectangle, ellipse, polygon & polyline).
 
 When the object is created, points can be added either with an array of `CGPoint` objects, or a string. In order to render the object, the `SKTileObject.getVertices()` method is called, which returns the points that make up the shape.
 */
open class SKTileObject: SKShapeNode, SKTiledObject {

    weak open var layer: SKObjectGroup!                     // layer parent, assigned on add
    open var uuid: String = UUID().uuidString               // unique id
    open var id: Int = 0                                    // object id
    open var gid: Int!                                      // tile gid
    open var type: String!                                  // object type
    
    internal var objectType: SKObjectType = .rectangle      // shape type
    internal var points: [CGPoint] = []                     // points that describe the object's shape.
    
    open var size: CGSize = CGSize.zero
    open var properties: [String: String] = [:]             // custom properties
    internal var physicsType: CollisionType = .none         // physics collision type
    
    /// Object opacity
    open var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    /// Object visibility
    open var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
    }
    
    /// Returns the bounding box of the shape.
    open var boundingRect: CGRect {
        return CGRect(x: 0, y: 0, width: size.width, height: -size.height)
    }
    
    // MARK: - Init
    override public init(){
        super.init()
        drawObject()
    }
    
    /**
     Initialize the object with width & height attributes.
     
     - parameter width:  `CGFloat` object size width.
     - parameter height: `CGFloat` object size height.
     - parameter type:   `SKObjectType` object shape type.
     */
    public init(width: CGFloat, height: CGFloat, type: SKObjectType = .rectangle){
        super.init()
    
        // Rectangular and ellipse objects get initial points.
        if (width > 0) && (height > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: width, y: 0),
                      CGPoint(x: width, y: height),
                      CGPoint(x: 0, y: height)
            ]
        }
        
        self.objectType = type
        self.size = CGSize(width: width, height: height)
        drawObject()
    }
    
    public init?(attributes: [String: String]) {
        // required attributes
        guard let objectID = attributes["id"] else { return nil }        
        guard let xcoord = attributes["x"] else { return nil }        
        guard let ycoord = attributes["y"] else { return nil }        
        
        id = Int(objectID)!
        super.init()
        
        let startPosition = CGPoint(x: CGFloat(Double(xcoord)!), y: CGFloat(Double(ycoord)!))
        position = startPosition
        
        if let objectName = attributes["name"] {
            self.name = objectName
        }
        
        // size properties
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        if let objectWidth = attributes["width"] {            
            width = CGFloat(Double(objectWidth)!)
        }
        
        if let objectHeight = attributes["height"] {
            height = CGFloat(Double(objectHeight)!)
        }
        
        if let objType = attributes["type"] {
            type = objType
        }
        
        if let objGID = attributes["gid"] {
            gid = Int(objGID)!
        }
        
        // Rectangular and ellipse objects need initial points.
        if (width > 0) && (height > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: width, y: 0),
                      CGPoint(x: width, y: height),
                      CGPoint(x: 0, y: height)
                    ]
        }
        
        self.size = CGSize(width: width, height: height)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    /**
     Set the fill & stroke colors (with optional alpha component for the fill)
     
     - parameter color: `SKColor` fill & stroke color.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    open func setColor(color: SKColor, withAlpha alpha: CGFloat=0.35) {
        self.strokeColor = color
        if !(self.objectType == .polyline)  {
            self.fillColor = color.withAlphaComponent(alpha)
        }
        drawObject()
    }
    
    /**
     Set the fill & stroke colors with a hexadecimal string.
     
     - parameter color: `hexString` hex color string.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    open func setColor(hexString: String, withAlpha alpha: CGFloat=0.35) {
        self.strokeColor = SKColor(hexString: hexString)
        if !(self.objectType == .polyline)  {
            self.fillColor = self.strokeColor.withAlphaComponent(alpha)
        }
        drawObject()
    }
    
    // MARK: - Rendering
    
    /**
     Render the object.
     */
    public func drawObject() {
        guard let layer = layer else { return }
        guard points.count > 1 else { return }

        
        // polyline objects should have no fill
        self.zPosition = layer.tilemap.lastZPosition + layer.tilemap.zDeltaForLayers
        self.fillColor = (self.objectType == .polyline) ? SKColor.clear : self.fillColor
        self.isAntialiased = layer.antialiased
        
        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 0.75
        
        if let vertices = getVertices() {
            
            // render tile image here if gid provided
            
            switch objectType {
            case .ellipse:
                
                let vertsInverted = vertices.map{$0.invertedY}
                var bezPoints: [CGPoint] = []
                for (index, point) in vertsInverted.enumerated() {
                    let nextIndex = (index < vertsInverted.count - 1) ? index + 1 : 0
                    bezPoints.append(lerp(start: point, end: vertsInverted[nextIndex], t: 0.5))
                }
                
                self.path = bezierPath(bezPoints, closed: true, alpha: 0.75)
                
                // draw a cage around the curve
                if layer.orientation == .isometric {
                    let controlPath = polygonPath(vertsInverted)
                    let controlShape = SKShapeNode(path: controlPath, centered: false)
                    addChild(controlShape)
                    controlShape.fillColor = SKColor.clear
                    controlShape.strokeColor = self.strokeColor.withAlphaComponent(0.2)
                    controlShape.isAntialiased = true
                    controlShape.lineWidth = self.lineWidth / 2
                }
                
            default:
                let closedPath: Bool =  (self.objectType == .polyline) ? false : true
                self.path = polygonPath(vertices.map{$0.invertedY}, closed: closedPath)
            }
            
            // draw the first point of poly objects
            if (self.objectType == .polyline) || (self.objectType == .polygon) {
                
                childNode(withName: "FirstPoint")?.removeFromParent()

                let anchor = SKShapeNode(circleOfRadius: self.lineWidth * 2.5)
                anchor.name = "FirstPoint"
                addChild(anchor)
                anchor.position = vertices[0].invertedY
                anchor.strokeColor = SKColor.clear
                anchor.fillColor = self.strokeColor
                anchor.isAntialiased = isAntialiased
            }
        }
        
        // render the object with a tile image
        if (self.gid != nil) {
            renderWith(gid: self.gid!)
        }
    }
    
    /**
     Render with a tile ID.
     */
    internal func renderWith(gid: Int) {
        if let objectGroup = layer {
            if let tileData = objectGroup.tilemap.getTileData(gid) {
                let boundingBox = calculateAccumulatedFrame()
                
                if (tileData.texture != nil) {
                    childNode(withName: "GID_Sprite")?.removeFromParent()
                    let sprite = SKSpriteNode(texture: tileData.texture)
                    sprite.name = "GID_Sprite"
                    sprite.size.width = boundingBox.size.width
                    sprite.size.height = boundingBox.size.height
                    addChild(sprite)
                    strokeColor = SKColor.clear
                    fillColor = SKColor.clear
                }
            }
        }
    }
    
    // MARK: - Polygon Points
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     - parameter closed: `Bool` close the object path.
     */
    internal func addPoints(_ coordinates: [[CGFloat]], closed: Bool=true) {
        self.objectType = (closed == true) ? SKObjectType.polygon : SKObjectType.polyline

        // create an array of points from the given coordinates
        points = coordinates.map { CGPoint(x: $0[0], y: $0[1]) }
    }
        
    /**
     Add points from a string.
        
     - parameter points: `String` string of coordinates.
     */
    internal func addPointsWithString(_ points: String) {
        var coordinates: [[CGFloat]] = []
        let pointsArray = points.components(separatedBy: " ")
        for point in pointsArray {
            let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
            coordinates.append(coords.flatMap { CGFloat($0) })
        }
        addPoints(coordinates)
    }
    
    /**
     Returns the internal `SKTileObject.points` translated into the current map projection.
     
     - returns: `[CGPoint]?` array of points.
     */
    public func getVertices() -> [CGPoint]? {
        guard let layer = layer else { return nil}
        guard points.count > 1 else { return nil}
                
        var vertices: [CGPoint] = []
        for point in points {
            var offset = layer.pixelToScreenCoords(point)
            offset.x -= layer.origin.x
            vertices.append(offset)
        }
        return vertices
    }
    
    // MARK: - Callbacks
    open func didBeginRendering(completion: (() -> ())? = nil) {
        if completion != nil { completion!() }
    }
    
    open func didFinishRendering(completion: (() -> ())? = nil) {
        if completion != nil { completion!() }
    }
    
    // MARK: - Dynamics
    
    /**
     Setup physics for the object based on properties set up in Tiled.
     */
    open func setupPhysics() {
        guard let objectPath = path else {
            print("[SKTileObject]: WARNING: object path not set: \"\(self.name != nil ? self.name! : "null")\"")
            return
        }
        
        physicsBody = SKPhysicsBody(polygonFrom: objectPath)
        physicsBody?.isDynamic = (physicsType == .dynamic)
        physicsBody?.affectedByGravity = (physicsType == .dynamic)
        physicsBody?.mass = (doubleForKey("mass") != nil) ? CGFloat(doubleForKey("mass")!) : 1.0
        physicsBody?.friction = (doubleForKey("friction") != nil) ? CGFloat(doubleForKey("friction")!) : 0.2
        physicsBody?.restitution = (doubleForKey("restitution") != nil) ? CGFloat(doubleForKey("restitution")!) : 0.2  // bounciness
    }
}



extension SKTileObject {
    override open var hashValue: Int { return id.hashValue }
    
    /// Tile data description.
    override open var description: String {
        let comma = propertiesString.characters.count > 0 ? ", " : ""
        return "Object: \(id), \(name ?? "null")\(comma)\(propertiesString)"
    }
    
    override open var debugDescription: String { return description }
}
