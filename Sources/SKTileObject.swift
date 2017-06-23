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
 Text object attributes.
 */
public struct TextObjectAttributes {
    public var fontName: String = "Arial"
    public var fontSize: CGFloat = 12
    public var fontColor: SKColor = .black
    public var alignment: TextAlignment = TextAlignment()
    
    public var wrap: Bool = true
    public var isBold: Bool = false
    public var isItalic: Bool = false
    public var isUnderline: Bool = false
    public var isStrikeout: Bool = false
    public var renderQuality: CGFloat = 8
    
    public init() {}
    
    public init(font: String, size: CGFloat, color: SKColor = .black) {
        fontName = font
        fontSize = size
        fontColor = color
    }
    
    public struct TextAlignment {
        var horizontal: HoriztonalAlignment = .left
        var vertical: VerticalAlignment = .top
        
        enum HoriztonalAlignment: String {
            case left
            case center
            case right
        }
        
        enum VerticalAlignment: String {
            case top
            case center
            case bottom
        }
    }
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
    internal var points: [CGPoint] = []                     // points that describe the object's shape
    internal var tile: SKTile? = nil                        // optional tile
    
    open var size: CGSize = CGSize.zero
    open var properties: [String: String] = [:]             // custom properties
    open var ignoreProperties: Bool = false                 // ignore custom properties
    internal var physicsType: CollisionType = .none         // physics collision type
    
    open var textAttributes: TextObjectAttributes!          // text object attributes
    open var renderQuality: CGFloat = 8 {                   // text object render quality
        didSet {
            guard (renderQuality != oldValue),
                renderQuality <= 16 else  { return }
            textAttributes?.renderQuality = renderQuality
            drawObject()
        }
    }
    
    /// Text object attributes
    open var text: String! {
        didSet {
            guard text != oldValue else { return }
            drawObject()
        }
    }
    
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
    
    /// Returns the object anchor point (based on the current map's tile size).
    open var anchorPoint: CGPoint {
        guard let layer = layer else { return .zero }
        
        if (gid != nil) {
            let tileAlignmentX = layer.tilemap.tileWidthHalf
            let tileAlignmentY = layer.tilemap.tileHeightHalf
            return CGPoint(x: tileAlignmentX, y: tileAlignmentY)
        }
        return boundingRect.center
    }

    
    /// Signifies that this object is a text or tile object.
    open var isRenderableType: Bool {
        return (gid != nil) || (textAttributes != nil)
    }
    
    // MARK: - Init
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
        guard let objectID = attributes["id"],
                let xcoord = attributes["x"],
                let ycoord = attributes["y"] else { return nil }
        
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
    
    /**
     Initialize the object with tile gid & object group.
     
     - parameter tileID: `Int` tile id.
     - parameter layer:  `SKObjectGroup` object group.
     */
    public init(gid: Int, layer: SKObjectGroup){
        super.init()
        self.gid = gid
        self.layer = layer
        drawObject()
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
    open func setColor(color: SKColor, withAlpha alpha: CGFloat=0.35, redraw: Bool=true) {
        self.strokeColor = color
        if !(self.objectType == .polyline) && (self.gid == nil) {
            self.fillColor = color.withAlphaComponent(alpha)
        }
        //if redraw == true { drawObject() }
    }
    
    /**
     Set the fill & stroke colors with a hexadecimal string.
     
     - parameter color: `hexString` hex color string.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    open func setColor(hexString: String, withAlpha alpha: CGFloat=0.35, redraw: Bool=true) {
        self.setColor(color: SKColor(hexString: hexString), withAlpha: alpha, redraw: redraw)
    }
    
    // MARK: - Rendering
    
    /**
     Render the object.
     */
    open func drawObject(debug: Bool=false) {
        
        guard let layer = layer,
            let vertices = getVertices(),
            points.count > 1 else { return }
        
        
        let uiScale: CGFloat
        #if os(iOS)
        uiScale = UIScreen.main.scale
        #else
        uiScale = NSScreen.main()!.backingScaleFactor
        #endif
        
        // polyline objects should have no fill
        self.fillColor = (self.objectType == .polyline) ? SKColor.clear : self.fillColor
        self.isAntialiased = false //layer.antialiased
        self.lineJoin = .miter
        
        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 0.5
        
        // flip the vertex values on the y-value for our coordinate transform.
        // for some odd reason tile objects are flipped in the y-axis already, so ignore the translated
        var translatedVertices: [CGPoint] = vertices.map { $0.invertedY }
            
        switch objectType {
                
        case .ellipse:
            var bezPoints: [CGPoint] = []
                
            for (index, point) in translatedVertices.enumerated() {
                let nextIndex = (index < translatedVertices.count - 1) ? index + 1 : 0
                bezPoints.append(lerp(start: point, end: translatedVertices[nextIndex], t: 0.5))
            }
            
            self.path = bezierPath(bezPoints, closed: true, alpha: 0.75)
                
            // draw a cage around the curve
            if (layer.orientation == .isometric) {
                let controlPath = polygonPath(translatedVertices)
                let controlShape = SKShapeNode(path: controlPath, centered: false)
                addChild(controlShape)
                controlShape.fillColor = SKColor.clear
                controlShape.strokeColor = self.strokeColor.withAlphaComponent(0.2)
                controlShape.isAntialiased = true
                controlShape.lineWidth = self.lineWidth / 2
            }
            
        default:
            let closedPath: Bool = (self.objectType == .polyline) ? false : true
            self.path = polygonPath(translatedVertices, closed: closedPath)
        }
        
        // draw the first point of poly objects
        if (self.objectType == .polyline) || (self.objectType == .polygon) {
                
            if (self.gid == nil) {
                childNode(withName: "FirstPoint")?.removeFromParent()
                
                // the first-point radius should be larger for thinner (>1.0) line widths
                let anchorRadius = (self.lineWidth > 1) ? self.lineWidth * 2 : self.lineWidth * 3.5
                let anchor = SKShapeNode(circleOfRadius: anchorRadius)
                anchor.name = "FirstPoint"
                addChild(anchor)
                anchor.position = vertices[0].invertedY
                anchor.strokeColor = SKColor.clear
                anchor.fillColor = self.strokeColor
                anchor.isAntialiased = isAntialiased
            }
        }
        
        // if the object has a gid property, render it as a tile
        if let gid = gid {
            guard let tileData = layer.tilemap.getTileData(globalID: gid) else {
                print("Error: Tile object \"\(name ?? "null")\" cannot access tile data for id: \(gid)")
                return
            }
            
            // grab size from texture if initializing with a gid
            if (size == CGSize.zero) {
                size = tileData.texture.size()
            }
    
            let tileAttrs = flippedTileFlags(id: UInt32(gid))
                
            // set the tile data flip flags
            tileData.flipHoriz = tileAttrs.hflip
            tileData.flipVert  = tileAttrs.vflip
            tileData.flipDiag  = tileAttrs.dflip
            
            // remove existing tile
            self.tile?.removeFromParent()

            if (tileData.texture != nil) {
                
                childNode(withName: "TileObject")?.removeFromParent()
                if let tileSprite = SKTile(data: tileData) {
                    
                    let boundingBox = polygonPath(translatedVertices)
                    let rect = boundingBox.boundingBox
                    
                    tileSprite.name = "TileObject"
                    tileSprite.size.width = rect.size.width
                    tileSprite.size.height = rect.size.height
                    addChild(tileSprite)
                    
                    tileSprite.zPosition = zPosition - 1
                    tileSprite.position = rect.center
                    
                    // debug stroke color
                    isAntialiased = false
                    lineWidth = 0.75
                    strokeColor = (debug == false) ? SKColor.clear : layer.gridColor.withAlphaComponent(0.75)
                    fillColor = SKColor.clear
                    tileSprite.runAnimation()
                    
                    self.tile = tileSprite
                }
            }
        }
        
        // render text object as an image and use with a sprite
        if let _ = text {
            // initialize the text attrbutes if none exist
            if (textAttributes == nil) {
                textAttributes = TextObjectAttributes()
            }
            
            let image = drawTextObject(withScale: renderQuality)
            strokeColor = (debug == false) ? SKColor.clear : layer.gridColor.withAlphaComponent(0.75)
            fillColor = SKColor.clear
            
            childNode(withName: "TextObject")?.removeFromParent()
            let textTexture = SKTexture(cgImage: image)
            let textSprite = SKSpriteNode(texture: textTexture)
            textSprite.name = "TextObject"
            addChild(textSprite)
            
            // final scaling value depends on the quality factor
            let finalScaleValue: CGFloat = (1 / renderQuality) / uiScale
            textSprite.zPosition = zPosition - 1
            textSprite.setScale(finalScaleValue)
            textSprite.position = self.boundingRect.center
            
        }
    }
    
    /**
     Draw the text object. Scale factor is to allow for text to render clearly at higher zoom levels.
     
     - parameter textValue: `String` text string.
     - parameter withScale: `CGFloat` size scale.
     - returns: `CGImage` rendered text image.
     */
    open func drawTextObject(withScale: CGFloat=8) -> CGImage {
        let uiScale: CGFloat
        #if os(iOS)
        uiScale = UIScreen.main.scale
        #else
        uiScale = NSScreen.main()!.backingScaleFactor
        #endif
        
        // need absolute size
        let rectSize = fabs(self.boundingRect.size) * withScale
        return imageOfSize(rectSize, scale: uiScale) { context, bounds, scale in
            context.saveGState()
            
            // text block style
            let rectangleStyle = NSMutableParagraphStyle()
            
            // text block attributes            
            rectangleStyle.alignment = NSTextAlignment(rawValue: textAttributes.alignment.horizontal.intValue)!
            let rectangleFontAttributes: [String : Any] = [
                    NSFontAttributeName: textAttributes.font,
                    NSForegroundColorAttributeName: textAttributes.fontColor,
                    NSParagraphStyleAttributeName: rectangleStyle,
                    ]

            
            self.text!.draw(in: bounds, withAttributes: rectangleFontAttributes)
            context.restoreGState()
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
        guard let layer = layer,
                (points.count > 1) else { return nil}
                
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
            print("Warning: object path not set: \"\(self.name != nil ? self.name! : "null")\"")
            return
        }
        
        guard let layer = layer else { return }
        let tileSizeHalved = layer.tilemap.tileSizeHalved
        
        if let collisionShape = intForKey("collisionShape") {
            switch collisionShape {
            case 0:
                physicsBody = SKPhysicsBody(rectangleOf: tileSizeHalved)
            case 1:
                physicsBody = SKPhysicsBody(circleOfRadius: layer.tilemap.tileWidthHalf)
            default:
                physicsBody = SKPhysicsBody(polygonFrom: objectPath)
        }
        
        } else {
        physicsBody = SKPhysicsBody(polygonFrom: objectPath)
        }

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
        return "<Object: \(id), \"\(name ?? "null")\"\(comma)\(propertiesString)>"
    }
    
    override open var debugDescription: String { return description }
}


// Tile animation
extension SKTileObject {
    
    /// Returns true if the object references an animated tile.
    open var isAnimated: Bool {
        if let tile = self.tile {
            return tile.tileData.isAnimated
        }
        return false
    }
    
    /// Signifies that the object is a text object.
    open var isTextObject: Bool {
        return (textAttributes != nil)
    }
    
    /// Signifies that the object is a tile object.
    open var isTileObject: Bool {
        return (gid != nil)
    }
    
    /// Pause/unpause tile animation
    open var pauseAnimation: Bool {
        if let tile = self.tile {
            return tile.pauseAnimation
        }
        return false
    }
    
    /**
     Runs tile animation.
     */
    open func runAnimation() {
        if let tile = self.tile {
            tile.runAnimation()
        }
    }
}


extension TextObjectAttributes {
    #if os(iOS)
    public var font: UIFont {
        if let uifont = UIFont(name: fontName, size: fontSize * renderQuality) {
            return uifont
        }
        return UIFont.systemFont(ofSize: fontSize * renderQuality)
    }
    #else
    public var font: NSFont {
        if let nsfont = NSFont(name: fontName, size: fontSize * renderQuality) {
            return nsfont
        }
        return NSFont.systemFont(ofSize: fontSize * renderQuality)
    }
    #endif
}


extension TextObjectAttributes.TextAlignment.HoriztonalAlignment {
    /// Return a integer value for passing to NSTextAlignment.
    #if os(iOS)
    public var intValue: Int {
        switch self {
        case .left:
            return 0
        case .right:
            return 1
        case .center:
            return 2
        }
    }
    #else
    public var intValue: UInt {
        switch self {
        case .left:
            return 0
        case .right:
            return 1
        case .center:
            return 2
        }
    }
    #endif
}


extension TextObjectAttributes.TextAlignment.VerticalAlignment {
    /// Return a UInt value for passing to NSTextAlignment.
    #if os(iOS)
    public var intValue: Int {
        switch self {
        case .top:
            return 0
        case .center:
            return 1
        case .bottom:
            return 2
        }
    }
    #else
    public var intValue: UInt {
        switch self {
        case .top:
            return 0
        case .center:
            return 1
        case .bottom:
            return 2
        }
    }
    #endif
}
