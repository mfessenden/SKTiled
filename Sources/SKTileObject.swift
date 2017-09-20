//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/**

 ## Overview ##

 Structure for managing basic font rendering attributes for [text objects][text-objects].


 ### Properties ###

 
 ```swift
 TextObjectAttributes.fontName        // font name.
 TextObjectAttributes.fontSize        // font size.
 TextObjectAttributes.fontColor       // font color.
 TextObjectAttributes.alignment       // horizontal/vertical alignment.
 TextObjectAttributes.wrap            // wrap text.
 TextObjectAttributes.isBold          // font is bold.
 TextObjectAttributes.isItalic        // font is italicized.
 TextObjectAttributes.isUnderline     // font is underlined.
 TextObjectAttributes.renderQuality   // font resolution.
 ```

 [text-objects]:../objects.html#text-objects
 */
public struct TextObjectAttributes {

    /// Font name.
    public var fontName: String = "Arial"
    /// Font size.
    public var fontSize: CGFloat = 16
    /// Font color.
    public var fontColor: SKColor = .black
    /// Font alignment.
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


    /// Text alignment.
    public var alignment: TextAlignment = TextAlignment()

    public var wrap: Bool = true
    public var isBold: Bool = false
    public var isItalic: Bool = false
    public var isUnderline: Bool = false
    public var isStrikeout: Bool = false
    /// Font scaling property.
    public var renderQuality: CGFloat = 8

    public init() {}

    /**
     Initialize with basic font attributes.
     */
    public init(font: String, size: CGFloat, color: SKColor = .black) {
        fontName = font
        fontSize = size
        fontColor = color
    }
}

/**
 ## Overview ##

 The `SKTileObject` class represents a Tiled vector object type (rectangle, ellipse, polygon & polyline). When the object is created, points can be added either with an array of `CGPoint` objects, or a string. In order to render the object, the `SKTileObject.getVertices()` method is called, which returns the points needed to draw the path.

 */
open class SKTileObject: SKShapeNode, SKTiledObject {

    // Describes the object shape.
    public enum ObjectType: String {
        case rectangle
        case ellipse
        case polygon
        case polyline
    }

    /// Object parent layer.
    weak open var layer: SKObjectGroup!
    /// Unique id (layer & object names may not be unique).
    open var uuid: String = UUID().uuidString
    /// Tiled object id.
    open var id: Int = 0
    /// Tiled global id (for tile objects).
    internal var gid: Int!
    /// Object type.
    open var type: String!
    
    /// Object size.
    open var size: CGSize = CGSize.zero
    
    internal var objectType: ObjectType = .rectangle        // shape type
    internal var points: [CGPoint] = []                     // points that describe the object's shape

    /// Object keys
    internal var tileObjectKey: String = "TILE_OBJECT"
    internal var textObjectKey: String = "TEXT_OBJECT"
    internal var boundsKey: String = "BOUNDS"
    internal var anchorKey: String = "ANCHOR"

    internal var tile: SKTile?                              // optional tile

    /// Tile data (for tile objects).
    open var tileData: SKTilesetData? {
        return tile?.tileData
    }

    /// Object bounds color.
    open var frameColor: SKColor = TiledObjectColors.magenta
    
    /**
     ## Overview ##

     Enum defining object collision type.
     */
    public enum CollisionType {
        case none
        case dynamic
        case collision
    }

    /// Custom object properties.
    open var properties: [String: String] = [:]
    open var ignoreProperties: Bool = false                 // ignore custom properties
    /// Physics collision type.
    open var physicsType: CollisionType = .none

    /// Text formatting attributes (for text objects)
    open var textAttributes: TextObjectAttributes!


    ///Text object render quality.
    open var renderQuality: CGFloat = 8 {
        didSet {
            guard (renderQuality != oldValue),
                renderQuality <= 16 else {
                return
            }

            textAttributes?.renderQuality = renderQuality
            drawObject()
        }
    }

    /// Object label.
    internal enum LabelPosition {
        case above
        case below
    }

    /// Text string (for text objects). Setting this attribute will redraw the object automatically.
    open var text: String! {
        didSet {
            guard text != oldValue else { return }
            drawObject()
        }
    }

    /// Returns the bounding box of the shape.
    open var bounds: CGRect {
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
        return bounds.center
    }

    /// Signifies that this object is a text or tile object.
    open var isRenderableType: Bool {
        return (gid != nil) || (textAttributes != nil)
    }

    /// Signifies that this object is a polygonal type.
    open var isPolyType: Bool {
        return (objectType == .polygon) || (objectType == .polyline)
    }

    override open var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.tile?.speed = speed
        }
    }

    // MARK: - Init
    /**
     Initialize the object with width & height attributes.

     - parameter width:  `CGFloat`      object size width.
     - parameter height: `CGFloat`      object size height.
     - parameter type:   `ObjectType`   object shape type.
     */
    required public init(width: CGFloat, height: CGFloat, type: ObjectType = .rectangle) {
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

    /**
     Initialize the object attributes dictionary.

     - parameter attributes:  `[String: String]` object attributes.
     */
    required public init?(attributes: [String: String]) {
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

        if let objVis = attributes["visible"] {
            visible = (Int(objVis) == 1) ? true : false
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

        // object rotation
        if let degreesValue = attributes["rotation"] {

            if let doubleVal = Double(degreesValue) {
                let radiansValue = CGFloat(doubleVal).radians()
                self.zRotation = -radiansValue
            }
        }
    }

    /**
     Initialize the object with an object group reference.

     - parameter layer:  `SKObjectGroup` object group.
     */
    required public init(layer: SKObjectGroup) {
        super.init()
        _ = layer.addObject(self)
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
        if redraw == true { drawObject() }
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
    open func drawObject(debug: Bool = false) {

        guard let layer = layer,
            let vertices = getVertices(),
            points.count > 1 else { return }


        let uiScale: CGFloat = SKTiledContentScaleFactor

        // polyline objects should have no fill
        self.fillColor = (self.objectType == .polyline) ? SKColor.clear : self.fillColor
        self.isAntialiased = layer.antialiased
        self.lineJoin = .miter

        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 0.5

        // flip the vertex values on the y-value for our coordinate transform.
        // for some odd reason Tiled tile objects are flipped in the y-axis already, so ignore the translated
        var translatedVertices: [CGPoint] = (isPolyType == true) ? (gid == nil) ? vertices.map { $0.invertedY } : vertices : (gid == nil) ? vertices.map { $0.invertedY } : vertices

        switch objectType {

        case .ellipse:
            var bezPoints: [CGPoint] = []

            for (index, point) in translatedVertices.enumerated() {
                let nextIndex = (index < translatedVertices.count - 1) ? index + 1 : 0
                bezPoints.append(lerp(start: point, end: translatedVertices[nextIndex], t: 0.5))
            }

            let bezierData = bezierPath(bezPoints, closed: true, alpha: 0.75)
            self.path = bezierData.path

            //let controlPoints = bezierData.points

            // draw a cage around the curve
            if (layer.orientation == .isometric) {
                let controlPath = polygonPath(translatedVertices)
                let controlShape = SKShapeNode(path: controlPath, centered: false)
                addChild(controlShape)
                controlShape.fillColor = SKColor.clear
                controlShape.strokeColor = self.strokeColor.withAlphaComponent(0.2)
                controlShape.isAntialiased = layer.antialiased
                controlShape.lineWidth = self.lineWidth / 2
            }

        default:
            let closedPath: Bool = (self.objectType == .polyline) ? false : true
            self.path = polygonPath(translatedVertices, closed: closedPath)
        }

        // draw the first point of poly objects
        if (isPolyType == true) {

            childNode(withName: "FIRST_POINT")?.removeFromParent()

            // MARK: - Tile object drawing
            if (self.gid == nil) {

                // the first-point radius should be larger for thinner (>1.0) line widths
                let anchorRadius = self.lineWidth * 1.2
                let anchor = SKShapeNode(circleOfRadius: anchorRadius)
                anchor.name = "FIRST_POINT"
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
                log("Tile object \"\(name ?? "null")\" cannot access tile data for id: \(gid)", level: .error)
                return
            }

            // in Tiled, tile data type overrides object type
            self.type = (tileData.type == nil) ? self.type : tileData.type!

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

                childNode(withName: tileObjectKey)?.removeFromParent()
                if let tileSprite = SKTile(data: tileData) {

                    let boundingBox = polygonPath(translatedVertices)
                    let rect = boundingBox.boundingBox

                    tileSprite.name = tileObjectKey
                    tileSprite.size.width = rect.size.width
                    tileSprite.size.height = rect.size.height

                    addChild(tileSprite)

                    tileSprite.zPosition = zPosition - 1
                    tileSprite.position = rect.center

                    isAntialiased = false
                    lineWidth = 0.75
                    strokeColor = SKColor.clear
                    fillColor = SKColor.clear

                    // set tile property
                    self.tile = tileSprite

                    // flipped tile flags
                    tileSprite.xScale = (tileData.flipHoriz == true) ? -1 : 1
                    tileSprite.yScale = (tileData.flipVert == true) ? -1 : 1
                }
            }
        }

        // render text object as an image and use with a sprite
        if (text != nil) {
            // initialize the text attrbutes if none exist
            if (textAttributes == nil) {
                textAttributes = TextObjectAttributes()
            }

            // remove the current text object
            childNode(withName: textObjectKey)?.removeFromParent()

            strokeColor = (debug == false) ? SKColor.clear : layer.gridColor.withAlphaComponent(0.75)
            fillColor = SKColor.clear

            // render text to an image
            if let cgImage = drawTextObject(withScale: renderQuality) {
                let textTexture = SKTexture(cgImage: cgImage)
                let textSprite = SKSpriteNode(texture: textTexture)
                textSprite.name = textObjectKey
                addChild(textSprite)

                // final scaling value depends on the quality factor
                let finalScaleValue: CGFloat = (1 / renderQuality) / uiScale
                textSprite.zPosition = zPosition - 1
                textSprite.setScale(finalScaleValue)
                textSprite.position = self.bounds.center

            }
        }
    }

    /**
     Draw the text object. Scale factor is to allow for text to render clearly at higher zoom levels.

     - parameter withScale: `CGFloat` size scale.
     - returns: `CGImage` rendered text image.
     */
    open func drawTextObject(withScale: CGFloat=8) -> CGImage? {

        let uiScale: CGFloat = SKTiledContentScaleFactor

        // the object's bounding rect
        let textRect = self.bounds
        let scaledRect = textRect * withScale

        // need absolute size
        let scaledRectSize = fabs(textRect.size) * withScale

        return imageOfSize(scaledRectSize, scale: uiScale) { context, bounds, scale in
            context.saveGState()

            // text block style
            let textStyle = NSMutableParagraphStyle()

            // text block attributes
            textStyle.alignment = NSTextAlignment(rawValue: textAttributes.alignment.horizontal.intValue)!
            let textFontAttributes: [String : Any] = [
                    NSFontAttributeName: textAttributes.font,
                    NSForegroundColorAttributeName: textAttributes.fontColor,
                    NSParagraphStyleAttributeName: textStyle
                    ]

            // setup vertical alignment
            let fontHeight: CGFloat
            #if os(iOS) || os(tvOS)
            fontHeight = self.text!.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).height
            #else
            fontHeight = self.text!.boundingRect(with: CGSize(width: bounds.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes).height
            #endif
            // vertical alignment
            // center aligned...
            if (textAttributes.alignment.vertical == .center) {
                let adjustedRect: CGRect = CGRect(x: scaledRect.minX, y: scaledRect.minY + (scaledRect.height - fontHeight) / 2, width: scaledRect.width, height: fontHeight)
                #if os(macOS)
                NSRectClip(textRect)
                #endif
                self.text!.draw(in: adjustedRect.offsetBy(dx: 0, dy: 2 * withScale), withAttributes: textFontAttributes)

            // top aligned...
            } else if (textAttributes.alignment.vertical == .top) {
                self.text!.draw(in: bounds, withAttributes: textFontAttributes)
                //self.text!.draw(in: bounds.offsetBy(dx: 0, dy: 1.25 * withScale), withAttributes: textFontAttributes)

            // bottom aligned
            } else {
                let adjustedRect: CGRect = CGRect(x: scaledRect.minX, y: scaledRect.minY, width: scaledRect.width, height: fontHeight)
                #if os(macOS)
                NSRectClip(textRect)
                #endif
                self.text!.draw(in: adjustedRect.offsetBy(dx: 0, dy: 2 * withScale), withAttributes: textFontAttributes)
            }
            context.restoreGState()
        }
    }

    // MARK: - Geometry

    /**
     Add polygons points.

     - parameter points: `[[CGFloat]]` array of coordinates.
     - parameter closed: `Bool` close the object path.
     */
    internal func addPoints(_ coordinates: [[CGFloat]], closed: Bool=true) {
        self.objectType = (closed == true) ? ObjectType.polygon : ObjectType.polyline
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
     Returns the internal `SKTileObject.points` array, translated into the current map's projection.

     - returns: `[CGPoint]?` array of points.
     */
    public func getVertices() -> [CGPoint]? {
        guard let layer = layer,
            (points.count > 1) else {
            return nil
        }

        return points.map { point in
            var offset = layer.pixelToScreenCoords(point)
            offset.x -= layer.origin.x
            return offset
        }
    }

    /**
     Draw the object's bounding shape.
     
     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor?=nil, zpos: CGFloat?=nil, duration: TimeInterval = 0) {
        
        childNode(withName: boundsKey)?.removeFromParent()
        childNode(withName: "FIRST_POINT")?.removeFromParent()

        let tileHeight = (layer != nil) ? layer.tilemap.tileHeight : 8
        // smaller maps look better with thinner lines
        let tileHeightDivisor: CGFloat = (tileHeight <= 16) ? 2 : 0.75

        // if a color is not passed, use the default frame color
        let drawColor = (withColor != nil) ? withColor! : self.frameColor


        // default line width
        let defaultLineWidth: CGFloat = (self.layer != nil) ? self.layer.lineWidth * 3 : 4.5
        guard let vertices = getVertices() else { return }

        let flippedVertices = (gid == nil) ? vertices.map { $0.invertedY } : vertices
        let renderQuality = (layer != nil) ? layer!.renderQuality : 8

        //let vertices = frame.points

        // scale vertices
        let scaledVertices = flippedVertices.map { $0 * renderQuality }
        let path = polygonPath(scaledVertices)

        // create the bounds shape
        let bounds = SKShapeNode(path: path)
        bounds.name = boundsKey
        let shapeZPos = zPosition + 50

        // draw the path
        bounds.isAntialiased = layer.antialiased
        bounds.lineCap = .round
        bounds.lineJoin = .miter
        bounds.miterLimit = 0
        bounds.lineWidth = (defaultLineWidth * (renderQuality / 2) / tileHeightDivisor)

        bounds.strokeColor = drawColor.withAlphaComponent(0.4)
        bounds.fillColor = drawColor.withAlphaComponent(0.15)  // 0.35
        bounds.zPosition = shapeZPos
        bounds.isAntialiased = layer.antialiased

        // anchor point
        let anchorRadius: CGFloat = bounds.lineWidth
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)

        anchor.name = anchorKey
        bounds.addChild(anchor)
        anchor.fillColor = bounds.strokeColor
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = shapeZPos
        anchor.isAntialiased = layer.antialiased


        // first point
        let firstPoint = scaledVertices[0]
        let pointShape = SKShapeNode(circleOfRadius: anchorRadius)

        pointShape.name = "FIRST_POINT"
        bounds.addChild(pointShape)
        pointShape.fillColor = bounds.fillColor
        pointShape.strokeColor = SKColor.clear
        pointShape.zPosition = shapeZPos * 15
        pointShape.isAntialiased = layer.antialiased

        pointShape.position = firstPoint

        addChild(bounds)
        bounds.setScale(1 / renderQuality)

        if (duration > 0) {
            let fadeAction = SKAction.fadeAfter(wait: duration, alpha: 0)
            bounds.run(fadeAction, withKey: "FADEOUT_ACTION", completion: {
                bounds.removeFromParent()
            })
        }
    }

    // MARK: - Debugging

    /// Show/hide the object's boundary shape.
    open var showBounds: Bool {
        get {
            return (childNode(withName: boundsKey) != nil) ? childNode(withName: boundsKey)!.isHidden == false : false
        }
        set {
            childNode(withName: boundsKey)?.removeFromParent()

            if (newValue == true) {
                isHidden = false

                // draw the tile boundary shape
                drawBounds()

                guard let frameShape = childNode(withName: boundsKey) else { return }

                let highlightDuration: TimeInterval = (layer != nil) ? layer!.highlightDuration : 0

                if (highlightDuration > 0) {
                    let fadeAction = SKAction.fadeOut(withDuration: highlightDuration)
                    frameShape.run(fadeAction, completion: {
                        frameShape.removeFromParent()
                    })
                }
            }
        }
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
        guard let layer = layer else { return }
        guard let objectPath = path else {
            log("object path not set: \"\(self.name != nil ? self.name! : "null")\"", level: .warning)
            return
        }


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
        physicsBody?.restitution = (doubleForKey("restitution") != nil) ? CGFloat(doubleForKey("restitution")!) : 0.4  // bounciness
    }


    // MARK: - Memory
    internal func flush() {
        self.path = nil
        childNode(withName: tileObjectKey)?.removeFromParent()
        childNode(withName: textObjectKey)?.removeFromParent()
    }

    // MARK: - Updating

    /**
     Update the object before each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    open func update(_ deltaTime: TimeInterval) {
        tile?.update(deltaTime)
    }
}


extension SKTileObject {
    override open var hashValue: Int { return id.hashValue }

    /// Tile data description.
    override open var description: String {
        let comma = propertiesString.characters.isEmpty == false ? ", " : ""
        let objectName = name ?? "null"
        let typeString = (type != nil) ? ", type: \"\(type!)\"" : ""
        let layerDescription = (layer != nil) ? ", Layer: \"\(layer.layerName)\"" : ""
        return "Object ID: \(id), \"\(objectName)\"\(typeString)\(comma)\(propertiesString)\(layerDescription)"
    }

    override open var debugDescription: String {
        return "<\(description)>"
    }

    open var shortDescription: String {
        var result = "Object id: \(self.id)"
        result += (self.type != nil) ? ", type: \"\(self.type!)\"" : ""
        return result
    }
}


extension SKTileObject {

    /// Object opacity
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }

    /// Object visibility
    open var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

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
}


extension TextObjectAttributes {
    #if os(iOS) || os(tvOS)
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
    #if os(iOS) || os(tvOS)
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
    #if os(iOS) || os(tvOS)
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

// MARK: - Deprecated

extension SKTileObject {

    /**
     Runs tile animation.
     */
    @available(*, deprecated)
    open func runAnimation() {}
}
