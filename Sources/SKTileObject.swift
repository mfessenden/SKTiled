//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit



/// Generic protocol for renderable Tiled objects.
protocol SKTiledGeometry {
    var visibleToCamera: Bool { get set }
    func draw(debug: Bool)
}



/**

 ## Overview ##

 Structure for managing basic font rendering attributes for [**text objects**][text-objects-url].

 ### Properties ###

 | Property      | Description                         |
 |---------------|-------------------------------------|
 | fontName      | Font name.                          |
 | fontSize      | Font size.                          |
 | fontColor     | Font color.                         |
 | alignment     | Horizontal/vertical text alignment. |
 | wrap          | Text wraps.                         |
 | isBold        | Text is bold.                       |
 | isItalic      | Text is italicized.                 |
 | isunderline   | Text is underlined.                 |
 | renderQuality | Font scaling attribute.             |

 [text-objects-url]:https://doc.mapeditor.org/en/stable/manual/objects/#insert-text
 */
public struct TextObjectAttributes {

    /// Font name.
    public var fontName: String  = "Arial"
    /// Font size.
    public var fontSize: CGFloat = 16
    /// Font color.
    public var fontColor: SKColor = .black

    /**

     ## Overview ##

     Structure describing text alignment.

     ### Properties ###
     
     | Property      | Description                         |
     |---------------|-------------------------------------|
     | horizontal    | Horizontal text alignment.          |
     | vertical      | Vertical text alignment.            |
     
    */
    public struct TextAlignment {

        var horizontal: HoriztonalAlignment = HoriztonalAlignment.left
        var vertical: VerticalAlignment = VerticalAlignment.top

        /// Horizontal text alignment.
        enum HoriztonalAlignment: String {
            case left
            case center
            case right
        }

        /// Vertical text alignment.
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
    public var renderQuality: CGFloat = TiledGlobals.default.renderQuality.text

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

 ### Properties ###

 | Property | Description                                                          |
 |----------|----------------------------------------------------------------------|
 | id       | Tiled object id.                                                     |
 | size     | Object size.                                                         |
 | tileData | Tile data (for [tile objects][tile-objects-url]).                    |
 | text     | Text string (for text objects). Setting this redraws the object.     |
 | bounds   | Returns the bounding box of the shape.                               |


 [tile-objects-url]:http://docs.mapeditor.org/en/stable/manual/objects/#insert-tile

 */
open class SKTileObject: SKShapeNode, SKTiledObject {

    /**
     ## Overview ##

     Describes the object type (tile object, text object, etc).

     ### Properties ###

     | Property  | Description                            |
     |-----------|----------------------------------------|
     | none      | Object is a simple vector object type. |
     | text      | Object is text object.                 |
     | tile      | Object is effectively a tile.          |

     */
    public enum TiledObjectType: String {
        case none
        case text
        case tile
    }

    /**
     ## Overview ##

      Describes a vector object shape.

     ### Properties ###

     | Property  | Description                    |
     |-----------|--------------------------------|
     | rectangle | Rectangular object shape.      |
     | ellipse   | Circular object shape.         |
     | polygon   | Closed polygonal object shape. |
     | polyline  | Open polygonal object shape.   |

     */
    public enum TiledObjectShape: String {
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

    /// Object is visible in camera.
    open var visibleToCamera: Bool = true
    
    internal var objectType: TiledObjectType = TiledObjectType.none          // object type
    internal var shapeType: TiledObjectShape = TiledObjectShape.rectangle    // shape type
    internal var points: [CGPoint] = []                                      // points that describe the object's shape

    /// Object keys.
    internal var tileObjectKey: String = "TILE_OBJECT"
    internal var textObjectKey: String = "TEXT_OBJECT"
    internal var boundsKey: String = "BOUNDS"
    internal var anchorKey: String = "ANCHOR"
    
    internal var _enableAnimation: Bool = true
    
    /// Enable tile animation.
    open var enableAnimation: Bool {
        get {
            return _enableAnimation
        }
        set {
            _enableAnimation = newValue
            tile?.enableAnimation = newValue
        }
    }
    
    /// Object tile (for tile objects)
    internal var tile: SKTile?                                               // optional tile
    internal var template: String?                                           // optional template reference
    internal var isInitialized: Bool = true
    
    /// Proxy object.
    weak internal var proxy: TileObjectProxy?

    /// Tile data (for tile objects).
    open var tileData: SKTilesetData? {
        return tile?.tileData
    }

    /// Object bounds color.
    open var frameColor: SKColor = TiledGlobals.default.debug.objectHighlightColor

    /**
     ## Overview ##

     Describes tile vector object collision type.
     
     ### Properties ###
     
     | Property  | Description                       |
     |-----------|-----------------------------------|
     | none      | No physics collisions.            |
     | dynamic   | Object is a dynamic physics body. |
     | collision | Object records collisions only.   |
     
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
    open var invertPhysics: Bool = false
    /// Text formatting attributes (for text objects)
    open var textAttributes: TextObjectAttributes!


    ///Text object render quality.
    open var renderQuality: CGFloat = TiledGlobals.default.renderQuality.object {
        didSet {
            guard (renderQuality != oldValue),
                (renderQuality <= 16) else {
                return
            }

            textAttributes?.renderQuality = renderQuality
            draw()
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
            draw()
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
        return (shapeType == .polygon) || (shapeType == .polyline)
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
     - parameter type:   `TiledObjectShape`   object shape type.
     */
    required public init(width: CGFloat, height: CGFloat, type: TiledObjectShape = .rectangle) {
        super.init()

        // Rectangular and ellipse objects get initial points.
        if (width > 0) && (height > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: width, y: 0),
                      CGPoint(x: width, y: height),
                      CGPoint(x: 0, y: height)
            ]
        }

        self.shapeType = type
        self.size = CGSize(width: width, height: height)
        draw()
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

        // pass the rest of the values to the setup method
        setObjectAttributes(attributes: attributes)
    }

    /**
     Set initial object attributes.

     - parameter attributes:  `[String: String]` object attributes.
     */
    func setObjectAttributes(attributes: [String: String]) {
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
        var initialSize: CGSize = CGSize.zero
        if (width > 0) && (height > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: width, y: 0),
                      CGPoint(x: width, y: height),
                      CGPoint(x: 0, y: height)
            ]

            initialSize = CGSize(width: width, height: height)
        }

        self.size = initialSize

        // object rotation
        if let degreesValue = attributes["rotation"] {
            if let doubleVal = Double(degreesValue) {
                let radiansValue = CGFloat(doubleVal).radians()
                self.zRotation = -radiansValue
            }
        }

        // optional template reference
        template = attributes["template"]
    }

    /**
     Initialize the object with an object group reference.

     - parameter layer:  `SKObjectGroup` object group.
     */
    required public init(layer: SKObjectGroup) {
        super.init()
        _ = layer.addObject(self)
        draw()
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
    open func setColor(color: SKColor, withAlpha alpha: CGFloat = 0.35, redraw: Bool = true) {
        self.strokeColor = color
        if !(self.shapeType == .polyline) && (self.gid == nil) {
            self.fillColor = color.withAlphaComponent(alpha)
        }
        // update proxy
        proxy?.objectColor = color
        proxy?.fillOpacity = alpha
        
        if redraw == true { draw() }
    }

    /**
     Set the fill & stroke colors with a hexadecimal string.

     - parameter color: `hexString` hex color string.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    open func setColor(hexString: String, withAlpha alpha: CGFloat = 0.35, redraw: Bool = true) {
        self.setColor(color: SKColor(hexString: hexString), withAlpha: alpha, redraw: redraw)
    }

    // MARK: - Rendering

    /**
     Render the object.
     */
    open func draw(debug: Bool = false) {

        guard let layer = layer,
            let vertices = getVertices(),
            points.count > 1 else { return }
        
        
        let uiScale: CGFloat = TiledGlobals.default.contentScale
        self.strokeColor = SKColor.clear
        self.fillColor = SKColor.clear
        self.isAntialiased = layer.antialiased
        self.lineJoin = .miter

        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 0.5

        // flip the vertex values on the y-value for our coordinate transform.
        // for some odd reason Tiled tile objects are flipped in the y-axis already, so ignore the translated
        var translatedVertices: [CGPoint] = (isPolyType == true) ? (gid == nil) ? vertices.map { $0.invertedY } : vertices : (gid == nil) ? vertices.map { $0.invertedY } : vertices

        switch shapeType {

        case .ellipse:
            var bezPoints: [CGPoint] = []

            for (index, point) in translatedVertices.enumerated() {
                let nextIndex = (index < translatedVertices.count - 1) ? index + 1 : 0
                bezPoints.append(lerp(start: point, end: translatedVertices[nextIndex], t: 0.5))
            }

            let bezierData = bezierPath(bezPoints, closed: true, alpha: shapeType.curvature)
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
            let closedPath: Bool = (self.shapeType == .polyline) ? false : true
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
            self.objectType = .tile
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
                
                // get tile object from delegate
                let Tile = (layer.tilemap.delegate != nil) ? layer.tilemap.delegate!.objectForTileType(named: tileData.type) : SKTile.self
                
                if let tileSprite = Tile.init(data: tileData) {
                    
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
                    
                    // tile objects should have no color
                    strokeColor = SKColor.clear
                    fillColor = SKColor.clear

                    // set tile property
                    self.tile = tileSprite

                    // flipped tile flags
                    tileSprite.xScale = (tileData.flipHoriz == true) ? -1 : 1
                    tileSprite.yScale = (tileData.flipVert == true) ? -1 : 1
                    
                    // add to tile cache
                    NotificationCenter.default.post(
                        name: Notification.Name.Layer.TileAdded,
                        object: tileSprite,
                        userInfo: ["layer": layer, "object": self]
                    )
                }
            }
        }

        // render text object as an image and use with a sprite
        if (text != nil) {
            // initialize the text attrbutes if none exist
            if (textAttributes == nil) {
                textAttributes = TextObjectAttributes()
            }

            self.objectType = .text

            // remove the current text object
            childNode(withName: textObjectKey)?.removeFromParent()
            //strokeColor = (debug == false) ? SKColor.clear : layer.gridColor.withAlphaComponent(0.75)
            strokeColor = SKColor.clear
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

     - parameter withScale: `CGFloat` render quality scaling.
     - returns: `CGImage` rendered text image.
     */
    open func drawTextObject(withScale: CGFloat = 8) -> CGImage? {

        let uiScale: CGFloat = TiledGlobals.default.contentScale

        // the object's bounding rect
        let textRect = self.bounds
        let scaledRect = textRect * withScale

        // absolute size of the texture rectangle
        let scaledRectSize: CGSize = fabs(textRect.size) * withScale

        return imageOfSize(scaledRectSize, scale: uiScale) { context, bounds, scale in
            context.saveGState()

            // text block style
            let textStyle = NSMutableParagraphStyle()

            // text block attributes
            textStyle.alignment = NSTextAlignment(rawValue: textAttributes.alignment.horizontal.intValue)!
            let textFontAttributes: [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font: textAttributes.font,
                    NSAttributedString.Key.foregroundColor: textAttributes.fontColor,
                    NSAttributedString.Key.paragraphStyle: textStyle
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
                __NSRectClip(textRect)
                #endif

                let offsetY = 2 * withScale
                self.text!.draw(in: adjustedRect.offsetBy(dx: 0, dy: offsetY), withAttributes: textFontAttributes)

            // top aligned...
            } else if (textAttributes.alignment.vertical == .top) {
                self.text!.draw(in: bounds, withAttributes: textFontAttributes)
                //self.text!.draw(in: bounds.offsetBy(dx: 0, dy: 1.25 * withScale), withAttributes: textFontAttributes)

            // bottom aligned
            } else {
                let adjustedRect: CGRect = CGRect(x: scaledRect.minX, y: scaledRect.minY, width: scaledRect.width, height: fontHeight)
                #if os(macOS)
                __NSRectClip(textRect)
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
    internal func addPoints(_ coordinates: [[CGFloat]], closed: Bool = true) {
        self.shapeType = (closed == true) ? TiledObjectShape.polygon : TiledObjectShape.polyline
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
            let coords = point.components(separatedBy: ",").compactMap { x in Double(x) }
            coordinates.append(coords.compactMap { CGFloat($0) })
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
     Returns the translated points array, correctly orientated.
     
     - returns: `[CGPoint]?` array of points.
     */
    internal func translatedVertices() -> [CGPoint]? {
        guard let vertices = getVertices() else { return nil }
        let translated = (isPolyType == true) ? (gid == nil) ? vertices.map { $0.invertedY } : vertices : (gid == nil) ? vertices.map { $0.invertedY } : vertices
        
        var result: [CGPoint] = []
        
        if (shapeType == TiledObjectShape.ellipse) {
            for (index, point) in translated.enumerated() {
                let nextIndex = (index < translated.count - 1) ? index + 1 : 0
                result.append(lerp(start: point, end: translated[nextIndex], t: 0.5))
            }
        } else {
            result = translated
        }

        return result
    }

    /**
     Draw the object's bounding shape.

     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor? = nil, zpos: CGFloat? = nil, duration: TimeInterval = 0) {

        childNode(withName: boundsKey)?.removeFromParent()
        childNode(withName: "FIRST_POINT")?.removeFromParent()

        let tileHeight = (layer != nil) ? layer.tilemap.tileHeight : 8

        // smaller maps look better with thinner lines
        var tileHeightDivisor: CGFloat = (tileHeight <= 16) ? 2 : 0.75

        // if effects are on
        tileHeightDivisor *= 2

        // if a color is not passed, use the default frame color
        let drawColor = (withColor != nil) ? withColor! : self.frameColor


        // default line width
        guard let vertices = getVertices() else { return }

        let flippedVertices = (gid == nil) ? vertices.map { $0.invertedY } : vertices
        let renderQuality = (layer != nil) ? layer!.renderQuality : 4

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

        bounds.lineWidth = ( renderQuality / tileHeightDivisor )

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
    open func didBeginRendering(completion: (() -> Void)? = nil) {
        if completion != nil { completion!() }
    }

    open func didFinishRendering(completion: (() -> Void)? = nil) {
        if completion != nil { completion!() }
    }

    // MARK: - Dynamics

    /**
     Setup physics for the object based on properties set up in Tiled.
     */
    open func setupPhysics() {
        guard let layer = layer,
              let vertices = getVertices() else {
                return
        }

        guard let objectPath = path else {
            log("object path not set: \"\(self.name != nil ? self.name! : "null")\"", level: .warning)
            return
        }

        var physicsPath: CGPath = objectPath

        // fix for flipped tile objects
        let flippedVertices = (gid == nil) ? vertices.map { $0.invertedY } : vertices
        let curvature: CGFloat = shapeType.curvature
        let bezierData = bezierPath(flippedVertices, closed: true, alpha: curvature)
        physicsPath = bezierData.path

        let tileSizeHalved = layer.tilemap.tileSizeHalved

        if let collisionShape = intForKey("collisionShape") {
            switch collisionShape {
            case 0:
                physicsBody = SKPhysicsBody(rectangleOf: tileSizeHalved)
            case 1:
                physicsBody = SKPhysicsBody(circleOfRadius: layer.tilemap.tileWidthHalf, center: physicsPath.boundingBox.center)
            default:
                physicsBody = SKPhysicsBody(polygonFrom: physicsPath)
        }

        } else {
            physicsBody = SKPhysicsBody(polygonFrom: physicsPath)
        }


        physicsBody?.isDynamic = (physicsType == .dynamic)
        physicsBody?.affectedByGravity = (physicsType == .dynamic)
        physicsBody?.mass = (doubleForKey("mass") != nil) ? CGFloat(doubleForKey("mass")!) : 1.0
        physicsBody?.friction = (doubleForKey("friction") != nil) ? CGFloat(doubleForKey("friction")!) : 0.2
        physicsBody?.restitution = (doubleForKey("restitution") != nil) ? CGFloat(doubleForKey("restitution")!) : 0.4  // bounciness
    }

    open func getPhysicsPath() -> CGPath? {
        return nil
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


// MARK: - Extensions


extension SKTileObject.TiledObjectType {

    /// Returns the name of the object.
    var name: String {
        switch self {
        case .none: return "Object"
        case .text: return "Text Object"
        case .tile: return "Tile Object"
        }
    }
}


extension SKTileObject.TiledObjectShape {
    
    /// Returns the curvature value for drawing the object path.
    var curvature: CGFloat {
        switch self {
        case .ellipse: return 0.75   // was 0.5
        default: return 0
        }
    }
}


extension SKTileObject {

    override open var hash: Int { return id.hashValue }

    /// Object description.
    override open var description: String {
        let comma = propertiesString.isEmpty == false ? ", " : ""
        var objectName = ""
        if let name = name {
            objectName = ", \"\(name)\""
        }
        let typeString = (type != nil) ? ", type: \"\(type!)\"" : ""
        let miscDesc = (objectType == .text) ? ", text quality: \(renderQuality)" : (objectType == .tile) ? ", tile id: \(gid ?? 0)" : ""
        let layerDescription = (layer != nil) ? ", Layer: \"\(layer.layerName)\"" : ""
        return "\(objectType.name) id: \(id)\(objectName)\(typeString)\(miscDesc)\(comma)\(propertiesString)\(layerDescription)"
    }

    override open var debugDescription: String {
        return "<\(description)>"
    }

    open var shortDescription: String {
        var result = "\(objectType.name) id: \(self.id)"
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



extension SKTileObject: Loggable {}
extension SKTileObject: SKTiledGeometry {}


extension SKTileObject.TiledObjectType: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .none: return "none"
        case .text: return "text"
        case .tile: return "tile"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}



extension SKTileObject.TiledObjectShape: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .rectangle: return "rectangle"
        case .ellipse: return "ellipse"
        case .polygon: return "polygon"
        case .polyline: return "polyline"
        }
    }
    
    public var debugDescription: String {
        return description
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
