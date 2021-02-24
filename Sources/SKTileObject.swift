//
//  SKTileObject.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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

/// The `SKTileObject` class represents a Tiled vector object type (rectangle, ellipse, polygon, point & polyline).
/// When the object is created, points can be added either with an array of points, or a string.
/// In order to render the object, the `SKTileObject.getVertices()` method is called, which returns the points needed to draw the path.
///
/// ### Properties
///
/// - `id`: Tiled object id.
/// - `size`: object size.
/// - `tileData`: tile data (for [tile objects][tile-objects-url]).
/// - `text`: text string (for text objects). Setting this redraws the object.
/// - `bounds`: returns the bounding box of the shape.
///
/// For more information, see the **[Working with Objects][objects-doc-url]** page in the **[official documentation][sktiled-docroot-url]**.
///
/// [objects-doc-url]:http://docs.mapeditor.org/en/stable/manual/objects/#insert-tile
/// [tile-objects-url]:https://mfessenden.github.io/SKTiled/1.3/working-with-objects.html
open class SKTileObject: SKShapeNode, CustomReflectable, TiledAttributedType {

    /// The `TiledObjectType` enumeration describes a vector object type (tile object, text object, etc).
    ///
    /// #### Properties
    ///
    /// - `none`: object is a simple vector object type.
    /// - `text`: object is text object.
    /// - `tile`: object is effectively a tile.
    /// - `point`: object is a references a single point.
    ///
    public enum TiledObjectType: String {
        case none
        case text
        case tile
        case point
    }

    /// The `TiledObjectType` enumeration describes the shape of vector objects.
    ///
    /// #### Properties
    ///
    /// - `rectangle`: rectangular object shape.
    /// - `ellipse`: circular object shape.
    /// - `polygon`: closed polygonal object shape.
    /// - `polyline`: ppen polygonal object shape.
    ///
    public enum TiledObjectShape: String {
        case rectangle
        case ellipse
        case polygon
        case polyline
    }

    /// Object parent layer.
    open weak var layer: SKObjectGroup!

    /// Unique id (layer & object names may not be unique).
    open var uuid: String = UUID().uuidString

    /// Tiled object id.
    open var id: UInt32 = 0

    /// Object type.
    open var type: String!

    /// Object size.
    open var size: CGSize = CGSize.zero

    /// Tiled global tile id (for tile objects).
    @TileID internal var tileId: UInt32 = 0

    /// Returns the *masked* tile global id. If the tile is not flipped at all, this will be the same as the `SKTileObject.tileId` value.
    internal var maskedTileId: UInt32 {
        return _tileId.realValue
    }

    /// Tiled global id (for tile objects).
    internal var globalID: UInt32! {
        get {
            let tid = _tileId.wrappedValue
            return (tid > 0) ? tid : nil
        } set {
            _tileId.wrappedValue = newValue
            draw()
        }
    }

    // MARK: - Object Handlers


    /// Handler for when the object is created.
    internal var onCreate: ((SKTileObject) -> ())?

    /// Handler for when the object is destroyed.
    internal var onDestroy: ((SKTileObject) -> ())?

    #if os(macOS)

    /// Mouse over handler.
    internal var onMouseOver: ((SKTileObject) -> ())?

    /// Mouse click handler.
    internal var onMouseClick: ((SKTileObject) -> ())?

    #else

    /// Touch event handler.
    internal var onTouch: ((SKTileObject) -> ())?

    #endif
    
    /// Indicates the current node has received focus or selected.
    public var isFocused: Bool = false {
        didSet {
            guard isFocused != oldValue else {
                return
            }
        }
    }
    
    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = []

    /// Object is visible in camera.
    open var visibleToCamera: Bool = true

    /// Vector object type.
    internal var objectType: TiledObjectType = TiledObjectType.none

    /// Shape type.
    internal var shapeType: TiledObjectShape = TiledObjectShape.rectangle

    /// Points describing the object's shape.
    internal var points: [CGPoint] = []

    /// Shape describing this object.
    @objc var shape: SKShapeNode?

    /// Shape describing this object.
    @objc public lazy var objectPath: CGPath = {
        if (globalID == nil) {
            let vertices = getVertices().map( { $0.invertedY })
            return polygonPath(vertices)
        } else {
            let vertices = translatedVertices()
            return polygonPath(vertices)
        }
    }()

    /// Object keys.
    internal lazy var tileObjectKey: String = {
        return "TILE_OBJECT_ID_\(id)"
    }()
    
    internal lazy var textObjectKey: String = {
        return "TEXT_OBJECT_ID_\(id)"
    }()
    
    internal lazy var boundsKey: String = {
        return "OBJECT_ID_\(id)_BOUNDS"
    }()
    
    internal lazy var anchorKey: String = {
        return "OBJECT_ID_\(id)_ANCHOR"
    }()

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

    /// Object tile (for tile objects).
    public internal(set) var tile: SKTile?

    /// Reference to template file (if any).
    internal var template: String?

    /// Initial object properties. Properties here will not be overritten by template properties.
    internal var initialProperties: [String: String] = [:]

    /// Signifies that the object has been fully initialized.
    open internal(set) var isInitialized: Bool = true

    /// Number of times this object has been redrawn (debug).
    open var drawCount: UInt32 = 0
    
    /// Proxy object.
    weak internal var proxy: TileObjectProxy?

    /// Root node for tile (for tile objects).
    internal var scaler: SKNode?

    /// Tile data (for tile objects).
    open var tileData: SKTilesetData? {
        return tile?.tileData
    }

    /// Object bounds color.
    open var frameColor: SKColor = TiledGlobals.default.debugDisplayOptions.objectHighlightColor

    /// Optional proxy color.
    open var proxyColor: SKColor?

    /// Optional tint color.
    open var tintColor: SKColor? {
        didSet {
            guard let newColor = tintColor else {

                frameColor = TiledGlobals.default.debugDisplayOptions.objectHighlightColor
                blendMode = .alpha
                tile?.tintColor = nil
                return
            }

            tile?.tintColor = newColor
            frameColor = newColor
        }
    }

    /// Layer bounding shape.
    public lazy var boundsShape: SKShapeNode? = {
        let scaledverts = getVertices().map { $0 * renderQuality }
        let objpath = polygonPath(scaledverts)
        let shape = SKShapeNode(path: objpath)

        shape.lineWidth = TiledGlobals.default.renderQuality.object
        shape.setScale(1 / renderQuality)
        addChild(shape)
        shape.zPosition = zPosition + 1
        return shape
    }()

    /// The `CollisionType` enumeration describes tile vector object collision type.
    ///
    /// #### Properties
    ///
    /// - `none`: no physics collisions.
    /// - `dynamic`: object is a dynamic physics body.
    /// - `collision`: object records collisions only.
    ///
    public enum CollisionType {
        case none
        case dynamic
        case collision
    }

    /// Custom object properties.
    open var properties: [String: String] = [:]

    /// Private **Tiled** properties.
    internal var _tiled_properties: [String: String] = [:]
    
    /// Object will ignore custom properties.
    open var ignoreProperties: Bool = false

    /// Physics collision type.
    open var physicsType: CollisionType = CollisionType.none

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
    open override var boundingRect: CGRect {
        switch shapeType {
            case .polyline, .polygon:
                // TODO: this might be inaccurate
                return calculateAccumulatedFrame()
            default:
                return CGRect(x: 0, y: 0, width: size.width, height: -size.height)
        }
    }

    /// Returns the object anchor point (based on the current map's tile size).
    open var anchorPoint: CGPoint {
        guard let layer = layer else {
            return CGPoint.zero
        }

        if (globalID != nil) {
            let tileAlignmentX = layer.tilemap.tileWidthHalf
            let tileAlignmentY = layer.tilemap.tileHeightHalf
            return CGPoint(x: tileAlignmentX, y: tileAlignmentY)
        }

        return boundingRect.center
    }

    /// Signifies that this object is a text or tile object.
    open var isRenderableType: Bool {
        return (globalID != nil) || (textAttributes != nil)
    }

    /// Signifies that this object is a polygonal type.
    open var isPolyType: Bool {
        return (shapeType == .polygon) || (shapeType == .polyline)
    }

    // Speed modifier applied to all actions executed by the object and its descendants.
    open override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.tile?.speed = speed
        }
    }

    // MARK: - Initialization

    /// Initialize the object with width & height attributes.
    ///
    /// - Parameters:
    ///   - width: object size width.
    ///   - height: object size height.
    ///   - type: object shape type.
    required public init(width: CGFloat,
                         height: CGFloat,
                         type: TiledObjectShape = .rectangle) {
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
        isUserInteractionEnabled = true
        draw()
    }

    /// Initialize the object with a dictionary of object attributes.
    ///
    /// - Parameter attributes: object attributes.
    required public init?(attributes: [String: String]) {

        // required attributes
        guard let objId = attributes["id"],
              let objectID = UInt32(objId),
              let xcoord = attributes["x"],
              let ycoord = attributes["y"] else { return nil }

        id = objectID
        super.init()
        isUserInteractionEnabled = true
        let startPosition = CGPoint(x: CGFloat(Double(xcoord)!), y: CGFloat(Double(ycoord)!))
        position = startPosition

        // pass the rest of the values to the setup method
        setObjectAttributesFromTemplateAttributes(attributes: attributes)
    }


    deinit {
        onDestroy?(self)
    }
    
    /// Removes this node from the scene graph.
    open override func destroy() {
        // remove from cache
        NotificationCenter.default.post(
            name: Notification.Name.Object.ObjectDestroyed,
            object: self
        )
        super.destroy()
    }

    /// Override initial object attributes. In the case of a templated object, these attributes are from the parent instance and these attributes should **override** the templated definition.
    ///
    /// - Parameters:
    ///   - attributes: object attributes.
    ///   - overwrite: overwrite current attributes (should be false if template attributes are applied to a scene object).
    func setObjectAttributesFromTemplateAttributes(attributes: [String: String]) {

        // Rectangular and ellipse objects need initial points.
        var initialSize: CGSize = CGSize.zero

        // size properties
        var initialWidth: CGFloat = 0
        var initialHeight: CGFloat = 0


        for (key, value) in attributes {

            // if the initial properties contains this key already, skip it
            if (initialProperties.has(key: key) == true) {
                continue
            }

            if (key == "name") {
                self.name = value
            }

            if (key == "width") {
                if let widthValue = Double(value) {
                    initialWidth = CGFloat(widthValue)
                }
            }

            if (key == "height") {
                if let heightValue = Double(value) {
                    initialHeight = CGFloat(heightValue)
                }
            }

            if (key == "type") {
                type = value
            }

            if (key == "gid") {
                guard let intVal = UInt32(value) else {
                    fatalError("invalid gid '\(value)'")
                }

                globalID = UInt32(intVal)
            }

            if (key == "visible") {
                visible = (Int(value) == 1) ? true : false
            }

            if (key == "rotation") {
                if let doubleVal = Double(value) {
                    let radiansValue = CGFloat(doubleVal).radians()
                    self.zRotation = -radiansValue
                }
            }


            if (key == "template") {
                template = value
            }
        }

        // Rectangular and ellipse objects need initial points.
        if (initialWidth > 0) && (initialHeight > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: initialWidth, y: 0),
                      CGPoint(x: initialWidth, y: initialHeight),
                      CGPoint(x: 0, y: initialHeight)
            ]
            initialSize = CGSize(width: initialWidth, height: initialHeight)
            self.size = initialSize
        }
    }

    /// Initialize the object with an object group reference.
    ///
    /// - Parameter layer: object group.
    required public init(layer: SKObjectGroup) {
        super.init()
        _ = layer.addObject(self)
        isUserInteractionEnabled = true
        draw()
    }

    /// Instantiate the node with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Colors

    /// Set the fill & stroke colors (with optional alpha component for the fill).
    ///
    /// - Parameters:
    ///   - color: fill & stroke color.
    ///   - alpha: alpha component for fill.
    ///   - redraw: force object to redraw.
    open func setColor(color: SKColor,
                       withAlpha alpha: CGFloat = 0.35,
                       redraw: Bool = true) {

        self.strokeColor = color
        if !(self.shapeType == .polyline) && (self.globalID == nil) {
            self.fillColor = color.withAlphaComponent(alpha)
        }
        // update proxy
        proxy?.objectColor = color
        proxy?.fillOpacity = alpha

        if redraw == true { draw() }
    }

    /// Set the fill & stroke colors with a hexadecimal string.
    ///
    /// - Parameters:
    ///   - hexString: hex color string.
    ///   - alpha: alpha component for fill.
    ///   - redraw: force object to redraw.
    open func setColor(hexString: String,
                       withAlpha alpha: CGFloat = 0.35,
                       redraw: Bool = true) {

        self.setColor(color: SKColor(hexString: hexString), withAlpha: alpha, redraw: redraw)
    }

    // MARK: - Tile Data

    /// Set the tile object's tile data.
    ///
    /// - Parameter data: tile data instance.
    open func setTileData(_ data: SKTilesetData) {
        self.globalID = data.globalID
        draw()
    }

    // MARK: - Rendering

    /// Render the object.
    @objc open func draw() {
        let uiScale: CGFloat = TiledGlobals.default.contentScale
        self.strokeColor = SKColor.clear
        self.fillColor = SKColor.clear

        self.lineJoin = .miter
        let vertices = getVertices()

        guard let layer = layer,
              points.count > 1 else {
            return
        }
        
        // DEBUGGING: increment the draw count
        drawCount += 1

        // draw the point object
        if (objectType == .point) {
            let pointSize = layer.tileSize.halfHeight
            self.path = pointObjectPath(size: pointSize)
            self.lineJoin = .bevel
            self.lineCap = .round
            self.lineWidth = pointSize / 8
            self.strokeColor = frameColor
            self.fillColor = frameColor.withAlphaComponent(0.4)
            return
        }

        self.isAntialiased = layer.antialiased

        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 0.5

        // flip the vertex values on the y-value for our coordinate transform.
        // for some odd reason Tiled tile objects are flipped in the y-axis already, so ignore the translated

        // TODO: proxy is drawing from the `SKTileObject.translatedVertices()` method, check the result against this one
        let translated: [CGPoint] = (isPolyType == true) ? (globalID == nil) ? vertices.map { $0.invertedY } : vertices : (globalID == nil) ? vertices.map { $0.invertedY } : vertices

        switch shapeType {

            case .ellipse:
                var bezPoints: [CGPoint] = []

                for (index, point) in translated.enumerated() {
                    let nextIndex = (index < translated.count - 1) ? index + 1 : 0
                    bezPoints.append(lerp(start: point, end: translated[nextIndex], t: 0.5))
                }

                let bezierData = bezierPath(bezPoints, closed: true, alpha: shapeType.curvature)
                self.path = bezierData.path

                //let controlPoints = bezierData.points

                // draw a cage around the curve
                if (layer.orientation == .isometric) {
                    let controlPath = polygonPath(translated)
                    let controlShape = SKShapeNode(path: controlPath, centered: false)
                    addChild(controlShape)
                    controlShape.fillColor = SKColor.clear
                    // controlShape.strokeColor = self.strokeColor.withAlphaComponent(0.2)
                    controlShape.strokeColor = SKColor.clear
                    controlShape.isAntialiased = layer.antialiased
                    controlShape.lineWidth = self.lineWidth / 2
                }

            default:
                let closedPath: Bool = (self.shapeType == .polyline) ? false : true
                self.path = polygonPath(translated, closed: closedPath)
        }

        // draw the first point of poly objects
        if (isPolyType == true) {
            
            let firstPointShapeName = "\(id)_FIRST_POINT"
            childNode(withName: firstPointShapeName)?.removeFromParent()

            // MARK: - Tile object drawing

            if (self.globalID == nil) {

                // the first-point radius should be larger for thinner (>1.0) line widths
                let anchorRadius = self.lineWidth * 1.2
                let anchor = SKShapeNode(circleOfRadius: anchorRadius)
                anchor.name = firstPointShapeName
                addChild(anchor)
                // CONVERTED
                anchor.position = vertices[0].invertedY
                anchor.strokeColor = SKColor.clear
                anchor.fillColor = self.strokeColor
                anchor.isAntialiased = isAntialiased
            }
        }


        // if the object has a gid property, render it as a tile
        if let globalId = globalID {

            guard let tileData = layer.tilemap.getTileData(globalID: globalId) else {
                log("Tile object '\(name ?? "null")' cannot access tile data for global id \(globalId)", level: .error)
                return
            }

            self.objectType = .tile

            // in Tiled, tile data type overrides object type
            self.type = (tileData.type == nil) ? self.type : tileData.type!

            // apply an initial size from texture if initializing with a gid
            if (size == CGSize.zero) {
                size = tileData.texture.size()
            }

            // remove existing tile
            self.tile?.removeFromParent()

            if (tileData.texture != nil) {

                childNode(withName: tileObjectKey)?.removeFromParent()

                // get tile object from delegate
                let Tile = (layer.tilemap.delegate != nil) ? layer.tilemap.delegate!.objectForTileType?(named: tileData.type) ?? SKTile.self : SKTile.self

                if let tileSprite = Tile.init(data: tileData) {

                    tileSprite.isUserInteractionEnabled = false
                    tileSprite.object = self

                    tileSprite.boundsOffset.x = layer.tileSize.halfWidth
                    tileSprite.boundsOffset.y = layer.tileSize.halfHeight

                    // create a node to handle parent scaling.
                    if (scaler == nil) {
                        let scalerNode = SKNode()
                        scalerNode.name = "TILE_OBJECT_\(id)_SCALER"

                        #if SKTILED_DEMO
                        scalerNode.setAttr(key: "tiled-node-icon", value: "scaler-icon")
                        scalerNode.setAttr(key: "tiled-node-listdesc", value: "Tile Object Scaler")
                        scalerNode.setAttr(key: "tiled-node-name", value: "Tile Object Scaler")
                        scalerNode.setAttr(key: "tiled-node-desc", value: "Scaler vector objects with tile attributes.")
                        #endif

                        addChild(scalerNode)
                        scaler = scalerNode
                    }

                    //tileSprite.anchorPoint = CGPoint.zero
                    tileSprite.tintColor = tintColor
                    tileSprite.layer = layer
                    tileSprite.isTileObject = true

                    // important! set the tile id here to the REAL tile id value
                    tileSprite.globalId = _tileId.realValue

                    // tileset texture size (or if the image is in a collection, use source size)
                    let tilesetSize = tileData.sourceSize ?? tileData.tileset.tileSize

                    // set the tile size to the texture size
                    tileSprite.size = tilesetSize

                    // tileset drawing offset
                    let drawingOffset = tileData.tileset.tileOffset

                    // CONVERTED
                    position = position + drawingOffset.invertedY

                    // get the scale factor between the size of the shape bounds, and the tile (texture) size
                    let scaleRatio = tilesetSize.scaleFactor(to: boundingRect.size)

                    // set the scaler size appropriately
                    scaler!.xScale = scaleRatio.width
                    scaler!.yScale = scaleRatio.height

                    // create the object bounding box
                    let boundingBox = polygonPath(translated)
                    let rect = boundingBox.boundingBox

                    // object size is the size of the actual vector object
                    let objectSize = rect.size

                    // set the scaler position to the center of the rect
                    scaler!.position = rect.center

                    // set the sprite object size attribute
                    tileSprite.objectSize = objectSize

                    // set the tile name
                    tileSprite.name = tileObjectKey
                    scaler!.addChild(tileSprite)

                    // position the tile just behind the object
                    tileSprite.zPosition = zPosition - 1

                    isAntialiased = false
                    lineWidth = 0.75

                    // tile objects should have no color
                    strokeColor = SKColor.clear
                    fillColor = SKColor.clear

                    // set tile property
                    self.tile = tileSprite

                    tileSprite.xScale = (tileSprite.isFlippedHorizontally == true) ? -1 : 1
                    tileSprite.yScale = (tileSprite.isFlippedVertically == false) ? -1 : 1     // compensates for tile object y-flip

                    layer.tilemap.delegate?.didAddTile?(tileSprite, in: name)

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
                textSprite.position = self.boundingRect.center
            }
        }
    }

    /// Draw the text object. Scale factor is to allow for text to render clearly at higher zoom levels.
    ///
    /// - Parameter withScale: render quality scaling.
    /// - Returns: rendered text image.
    open func drawTextObject(withScale: CGFloat = 8) -> CGImage? {

        let uiScale: CGFloat = TiledGlobals.default.contentScale

        // the object's bounding rect
        let textRect = self.boundingRect
        let scaledRect = textRect * withScale

        // absolute size of the texture rectangle
        let scaledRectSize: CGSize = fabs(textRect.size) * withScale

        return imageOfSize(scaledRectSize, scale: uiScale) { context, bounds, scale in
            context.saveGState()

            // text block style
            let textStyle = NSMutableParagraphStyle()

            // text block attributes
            let intval = Int(textAttributes.alignment.horizontal.intValue)
            textStyle.alignment = NSTextAlignment(rawValue: intval) ?? NSTextAlignment.left
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
            // center aligned (offset 0.5)
            if (textAttributes.alignment.vertical == .center) {
                let adjustedRect: CGRect = CGRect(x: scaledRect.minX, y: scaledRect.minY + (scaledRect.height - fontHeight) / 2, width: scaledRect.width, height: fontHeight)
                #if os(macOS)
                __NSRectClip(textRect)
                #endif

                let offsetY: CGFloat = (scaledRect.height / 2)   //4 * withScale
                self.text!.draw(in: adjustedRect.offsetBy(dx: 0, dy: offsetY), withAttributes: textFontAttributes)

                // top aligned...
            } else if (textAttributes.alignment.vertical == .top) {
                self.text!.draw(in: bounds, withAttributes: textFontAttributes)
                //self.text!.draw(in: bounds.offsetBy(dx: 0, dy: 1.25 * withScale), withAttributes: textFontAttributes)

                // bottom aligned (offset 0)
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

    /// Add polygons points.
    ///
    /// - Parameters:
    ///   - coordinates:  array of coordinates.
    ///   - closed: close the object path.
    internal func addPoints(_ coordinates: [[CGFloat]], closed: Bool = true) {
        self.shapeType = (closed == true) ? TiledObjectShape.polygon : TiledObjectShape.polyline
        // create an array of points from the given coordinates
        points = coordinates.map { CGPoint(x: $0[0], y: $0[1]) }
    }

    /// Add points from a string.
    ///
    /// - Parameter points: string of coordinates.
    internal func addPointsWithString(_ points: String) {
        var coordinates: [[CGFloat]] = []
        let pointsArray = points.components(separatedBy: " ")
        for point in pointsArray {
            let coords = point.components(separatedBy: ",").compactMap { x in Double(x) }
            coordinates.append(coords.compactMap { CGFloat($0) })
        }
        addPoints(coordinates)
    }

    /// Returns the internal `SKTileObject.points` array, translated into the current map's projection.
    ///
    /// - Returns: array of points.
    @objc public override func getVertices(offset: CGPoint = CGPoint.zero) -> [CGPoint] {
        // we need a layer to do pixel -> conversion
        guard let layer = layer,
              (points.count > 1) else {
            return [CGPoint]()
        }

        return points.map { point in
            var offset = layer.pixelToScreenCoords(point: point)
            // offset the point from the origin (isometric only)
            offset.x -= layer.origin.x
            return offset
        }
    }

    /// Returns the translated points array, correctly orientated.
    ///
    /// - Returns: array of points.
    internal func translatedVertices() -> [CGPoint] {
        let vertices = self.getVertices()
        guard (vertices.count > 1) else {
            return [CGPoint]()
        }

        let translated = (isPolyType == true) ? (globalID == nil) ? vertices.map { $0.invertedY } : vertices : (globalID == nil) ? vertices.map { $0.invertedY } : vertices
        var result: [CGPoint] = []

        // return interpolated points if the shape is an ellipse
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

    /// Returns the internal vertices interpolated.
    ///
    /// - Parameters:
    ///   - value: interpolation amount.
    /// - Returns: array of interpolated vertices.
    internal func interpolatedVertices(_ value: CGFloat = 0.5) -> [CGPoint]? {
        let vertices = translatedVertices()
        var result: [CGPoint] = []
        for (index, point) in vertices.enumerated() {
            let nextIndex = (index < vertices.count - 1) ? index + 1 : 0
            result.append(lerp(start: point, end: vertices[nextIndex], t: value))
        }
        return result
    }

    /// Returns true if the touch event (mouse or touch) hits this node.
    ///
    /// - Parameter touch: touch point in this node.
    /// - Returns: node was touched.
    @objc public override func contains(touch: CGPoint) -> Bool {
        return objectPath.contains(touch)
    }

    // MARK: - Events & Handlers

    #if os(macOS)

    open override func mouseMoved(with event: NSEvent) {
        // guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        if contains(touch: event.location(in: self)) {
            onMouseOver?(self)
        }
    }

    open override func mouseDown(with event: NSEvent) {
        // guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        
        // FIXME: this is failing with tile objects
        if contains(touch: event.location(in: self)) {
            // calls
            onMouseClick?(self)
        }
    }

    
    open override func mouseEntered(with event: NSEvent) {
        print("object entered!")
    }
    
    open override func mouseExited(with event: NSEvent) {
        print("object exited!")
    }
    
    
    #elseif os(iOS)

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if contains(touch: touch.location(in: self)) {
                onTouch?(self)
                return
            }
        }
    }

    #endif

    /// Show/hide the object's boundary shape.
    open var showBounds: Bool {
        get {
            return (childNode(withName: boundsKey) != nil) ? childNode(withName: boundsKey)!.isHidden == false : false
        }
        set {
            childNode(withName: boundsKey)?.removeFromParent()
            childNode(withName: anchorKey)?.removeFromParent()
            if (newValue == true) {
                isHidden = false

                // draw the tile boundary shape
                drawNodeBounds(with: frameColor)

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

    /// Object has begun rendering.
    ///
    /// - Parameter completion: optional completion handler.
    open func didBeginRendering(completion: (() -> Void)? = nil) {
        completion?()
    }

    /// Object has finished rendering.
    ///
    /// - Parameter completion: optional completion handler.
    open func didFinishRendering(completion: (() -> Void)? = nil) {
        completion?()
    }

    // MARK: - Dynamics

    /// Setup physics for the object based on properties set up in Tiled.
    open func setupPhysics() {

        let vertices = getVertices()
        guard let layer = layer,
              (vertices.count > 0) else {
            return
        }

        guard let shapePath = path else {
            log("object path not set: '\(self.name != nil ? self.name! : "null")'", level: .warning)
            return
        }

        var physicsPath: CGPath = shapePath

        // fix for flipped tile objects
        // CONVERTED
        let flippedVertices = (globalID == nil) ? vertices.map { $0.invertedY } : vertices
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

    /// Returns a path representing the physics shape.
    ///
    /// - Returns: path object.
    open func getPhysicsPath() -> CGPath? {
        // TODO: implement this
        return nil
    }

    // MARK: - Updating

    /// Update the object before each frame is rendered.
    ///
    /// - Parameter deltaTime: update interval.
    open func update(_ deltaTime: TimeInterval) {
        tile?.update(deltaTime)
    }

    // MARK: - Reflection

    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {

        var attributes: [(label: String?, value: Any)] = [
            (label: "points", value: points),
            (label: "objectType", value: objectType),
            (label: "shapeType", value: shapeType),
            (label: "frameColor", value: frameColor.hexString()),
            (label: "properties", value: mirrorChildren()),
            (label: "bounds", value: boundingRect),
            (label: "visibleToCamera", value: visibleToCamera),
            (label: "isUserInteractionEnabled", value: isUserInteractionEnabled)
        ]

        if let gid = globalID {
            attributes.insert(("globalID",gid), at: 0)
        }

        if let tname = template {
            attributes.insert(("template",tname), at: 0)
        }

        if let layer = layer {
            attributes.append(("layer", layer.layerDataStruct()))
        }

        if let type = type {
            attributes.insert(("type", type), at: 0)
        }

        if let name = name {
            attributes.insert(("name", name), at: 0)
        }

        /// internal debugging attrs
        attributes.append(("tiled element name", tiledElementName))
        attributes.append(("tiled node nice name", tiledNodeNiceName))
        attributes.append(("tiled list description", #"\#(tiledListDescription)"#))
        attributes.append(("tiled menu item description", #"\#(tiledMenuItemDescription)"#))
        attributes.append(("tiled display description", #"\#(tiledDisplayItemDescription)"#))
        attributes.append(("tiled help description", tiledHelpDescription))

        attributes.append(("tiled description", description))
        attributes.append(("tiled debug description", debugDescription))
        
        return Mirror(self, children: attributes, ancestorRepresentation: .suppressed)

    }
}


// MARK: - Extensions


extension SKTileObject.TiledObjectType {

    /// Returns the name of the object.
    var name: String {
        switch self {
            case .none: return "Object"
            case .text: return "Text"
            case .tile: return "Object"
            case .point: return "Point"
        }
    }

    /// Returns the name of the object.
    var niceName: String {
        switch self {
            case .none: return "Object"
            case .text: return "Text Object"
            case .tile: return "Tile Object"
            case .point: return "Point"
        }
    }

    /// Returns the name of the object.
    var iconName: String {
        switch self {
            case .none: return "object-icon"
            case .text: return "textobject-icon"
            case .tile: return "tileobject-icon"
            case .point: return "pointobject-icon"
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


/// :nodoc:
extension SKTileObject {
    
    /// Returns an integer that can be used as a table address in a hash table structure.
    open override var hash: Int {
        return id.hashValue
    }
    
    /// String representation of tile object.
    open override var description: String {
        let comma = propertiesString.isEmpty == false ? " " : ""
        var objectName = ""
        if let name = name {
            objectName = " '\(name)'"
        }
        let typeString = (type != nil) ? " type: '\(type!)'" : ""
        let templateDescription = (template != nil) ? " Template: '\(template!)'" : ""
        let miscDesc = (objectType == .text) ? " text quality: \(renderQuality)" : (objectType == .tile) ? " gid: \(globalID ?? 0)" : (objectType == .point) ? "point:" : ""
        let layerDescription = (layer != nil) ? " layer: '\(layer.layerName)'" : ""
        
        
        var pointsString = ""
        if (isPolyType == true) {
            pointsString = (points.isEmpty == true) ? " 0 points" : " \(points.count) points"
        }
        
        return #"\#(tiledNodeNiceName) id: \#(id)\#(objectName)\#(typeString)\#(templateDescription)\#(miscDesc)\#(comma)\#(propertiesString)\#(layerDescription)\#(pointsString)"#
    }
    
    /// Returns a string representation for debugging.
    open override var debugDescription: String {
        let comma = propertiesString.isEmpty == false ? " " : ""
        var objectName = ""
        if let name = name {
            objectName = " '\(name)'"
        }
        let typeString = (type != nil) ? " type: '\(type!)'" : ""
        let templateDescription = (template != nil) ? " Template: '\(template!)'" : ""
        let miscDesc = (objectType == .text) ? " text quality: \(renderQuality)" : (objectType == .tile) ? " gid: \(globalID ?? 0)" : (objectType == .point) ? "point:" : ""
        let layerDescription = (layer != nil) ? " layer: '\(layer.layerName)'" : ""
        
        
        var pointsString = ""
        if (isPolyType == true) {
            pointsString = (points.isEmpty == true) ? " 0 points" : " \(points.count) points"
        }
        
        return #"<\#(className) id: \#(id)\#(objectName)\#(typeString)\#(templateDescription)\#(miscDesc)\#(comma)\#(propertiesString)\#(layerDescription)\#(pointsString)>"#
    }
}



/// :nodoc:
extension SKTileObject {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "object"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return objectType.niceName
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        //return (globalID == nil) ? "object-icon" : "tileobject-icon"
        return objectType.iconName
    }

    /// A description of the node used in list or outline views (ie: "Tile Object 'dwarf1' id: 119").
    @objc public override var tiledListDescription: String {
        let objName = (name != nil) ? " '\(name!)'" : ""
        return "\(tiledNodeNiceName)\(objName) id: \(id)"
    }

    /// A description of the node used in dropdown & popu menus (ie: "Tile Object 'dwarf1' id: 119").
    @objc public override var tiledMenuItemDescription: String {
        let objName = (name != nil) ? " '\(name!)'" : ""
        return "\(tiledNodeNiceName)\(objName) id: \(id)"
    }

    /// A description of the node used for debug output text.
    @objc public override var tiledDisplayItemDescription: String {
        let nameString = (name != nil) ? " '\(name!)'" : ""
        let idString = " id: \(id)"
        let layerNameString = (layer != nil) ? " layer: '\(layer.layerName)'" : ""
        return #"<\#(className)\#(nameString)\#(idString)\#(layerNameString)>"#
    }
    
    /// Description of the node type.
    @objc public override var tiledHelpDescription: String {
        return (globalID == nil) ? "Tiled vector object type." : "Tiled tile vector object type."
    }
}



extension SKTileObject {

    /// Object opacity.
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }

    /// Object visibility.
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
        return (globalID != nil)
    }
    
    /// Highlight the tile with a given color & duration.
    ///
    /// - Parameters:
    ///   - color: highlight color.
    ///   - duration: duration of highlight effect.
    @objc public override func highlightNode(with color: SKColor, duration: TimeInterval = 0) {
        let removeHighlight: Bool = (color == SKColor.clear)
        let highlightFillColor = (removeHighlight == false) ? color.withAlphaComponent(0.2) : color
        
        boundsShape?.strokeColor = color
        boundsShape?.fillColor = highlightFillColor
        boundsShape?.isHidden = false
        
        if (duration > 0) {
            let fadeInAction = SKAction.colorize(withColorBlendFactor: 1, duration: duration)
            
            let groupAction = SKAction.group(
                [
                    fadeInAction,
                    SKAction.wait(forDuration: duration),
                    fadeInAction.reversed()
                ]
            )
            
            
            boundsShape?.run(groupAction, completion: {
                self.boundsShape?.strokeColor = SKColor.clear
                self.boundsShape?.fillColor = SKColor.clear
                self.removeAnchor()
            })
        }
    }
}



/// :nodoc:
extension SKTileObject.TiledObjectType: CustomStringConvertible, CustomDebugStringConvertible {

    /// Textual representation of the object type.
    public var description: String {
        switch self {
            case .none:  return "none"
            case .text:  return "text"
            case .tile:  return "tile"
            case .point: return "point"
        }
    }

    /// Textual representation of the object type, used for debugging.
    public var debugDescription: String {
        return description
    }
}


/// :nodoc:
extension SKTileObject.TiledObjectShape: CustomStringConvertible, CustomDebugStringConvertible {

    /// Textual representation of the object type.
    public var description: String {
        switch self {
            case .rectangle: return "rectangle"
            case .ellipse: return "ellipse"
            case .polygon: return "polygon"
            case .polyline: return "polyline"
        }
    }

    /// Textual representation of the object type, used for debugging.
    public var debugDescription: String {
        return description
    }
}



// MARK: - Deprecations


extension SKTileObject {

    /// Tiled global id (for tile objects).
    @available(*, deprecated, renamed: "globalID")
    open var gid: UInt32! {
        get {
            return self.globalID
        } set {
            self.globalID = newValue
        }
    }

    /// Tiled global id (for tile objects).
    @available(*, deprecated, renamed: "maskedTileId")
    public var realTileId: UInt32 {
        return maskedTileId
    }

    /// Runs a tile animation.
    @available(*, deprecated)
    open func runAnimation() {}

    /// Draw the object.
    ///
    /// - Parameter debug: debug draw option.
    @available(*, deprecated, renamed: "draw()")
    open func draw(debug: Bool = false) {
        self.draw()
    }
    
    
    /// Returns a shortened textual representation for debugging.
    @available(*, deprecated, renamed: "tiledListDescription")
    open var shortDescription: String {
        var result = "\(objectType.name) id: \(self.id)"
        result += (self.type != nil) ? ", type: '\(self.type!)'" : ""
        return result
    }
}
