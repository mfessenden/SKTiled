//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public enum ObjectType: String {
    case Rectangle
    case Ellipse
    case Polygon
    case Polyline
}


/// simple object class
public class SKTileObject: SKShapeNode, SKTiledObject {

    weak public var layer: SKObjectGroup!            // layer parent, assigned on add
    public var uuid: String = NSUUID().UUIDString    // unique id
    public var id: Int = 0                           // object id
    public var type: String!                         // object type
    public var objectType: ObjectType = .Rectangle   // shape type
    
    public var points: [CGPoint] = []                // points that describe object shape
    
    public var size: CGSize = CGSizeZero
    public var properties: [String: String] = [:]    // custom properties
    
    // blending/visibility
    public var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    public var visible: Bool {
        get { return !self.hidden }
        set { self.hidden = !newValue }
    }
    
    // MARK: - Init
    override public init(){
        super.init()
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
        
        // Rectangular and ellipse objects need initial points.
        if (width > 0) && (height > 0) {
            points = [CGPoint(x: 0, y: 0),
                      CGPoint(x: width, y: 0),
                      CGPoint(x: width, y: height),
                      CGPoint(x: 0, y: height)
            ]
        }
        
        self.size = CGSizeMake(width, height)
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
    public func setColor(color: SKColor, withAlpha alpha: CGFloat=0.35) {
        self.strokeColor = color
        if !(self.objectType == .Polyline)  {
            self.fillColor = color.colorWithAlphaComponent(alpha)
        }
        drawObject()
    }
    
    /**
     Set the fill & stroke colors with a hexadecimal string.
     
     - parameter color: `hexString` hex color string.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    public func setColor(hexString hex: String, withAlpha alpha: CGFloat=0.35) {
        self.strokeColor = SKColor(hexString: hex)
        if !(self.objectType == .Polyline)  {
            self.fillColor = self.strokeColor.colorWithAlphaComponent(alpha)
        }
        drawObject()
    }
    
    /**
     Draw the path.
     */
    public func drawObject() {
        guard let layer = layer else { return }
        guard points.count > 1 else { return }
        
        
        // polyline objects should have no fill
        self.zPosition = layer.tilemap.lastZPosition + layer.tilemap.zDeltaForLayers
        self.fillColor = (self.objectType == .Polyline) ? SKColor.clearColor() : self.fillColor
        self.antialiased = layer.antialiased
        
        // scale linewidth for smaller objects
        let lwidth = (doubleForKey("lineWidth") != nil) ? CGFloat(doubleForKey("lineWidth")!) : layer.lineWidth
        self.lineWidth = (lwidth / layer.tileHeight < 0.075) ? lwidth : 2  // 0.75
        
        if let vertices = getVertices() {
            switch objectType {
            case .Ellipse:
                
                let vertsInverted = vertices.map{$0.invertedY}
                var bezPoints: [CGPoint] = []
                for (index, point) in vertsInverted.enumerate() {
                    let nextIndex = (index < vertsInverted.count - 1) ? index + 1 : 0
                    bezPoints.append(lerp(start: point, end: vertsInverted[nextIndex], t: 0.5))
                }
                
                self.path = bezierPath(bezPoints, closed: true, alpha: 0.75)
                
                // draw a cage around the curve
                if layer.orientation == .Isometric {
                    let controlPath = polygonPath(vertsInverted)
                    let controlShape = SKShapeNode(path: controlPath, centered: false)
                    addChild(controlShape)
                    controlShape.fillColor = SKColor.clearColor()
                    controlShape.strokeColor = self.strokeColor
                    controlShape.antialiased = true
                    controlShape.lineWidth = self.lineWidth / 2
                }
                
            default:
                let closedPath: Bool =  (self.objectType == .Polyline) ? false : true
                self.path = polygonPath(vertices.map{$0.invertedY}, closed: closedPath)
            }
            
            // draw the first point of poly objects
            if (self.objectType == .Polyline) || (self.objectType == .Polygon) {
            
                childNodeWithName("FirstPoint")?.removeFromParent()
                
                var anchorRadius = self.lineWidth * 2.5
                if anchorRadius > layer.tileHeight / 8 {
                    anchorRadius = layer.tileHeight / 9
                }

                let anchor = SKShapeNode(circleOfRadius: anchorRadius)
                anchor.name = "FirstPoint"
                addChild(anchor)
                anchor.position = vertices[0].invertedY
                anchor.strokeColor = SKColor.clearColor()
                anchor.fillColor = self.strokeColor
                anchor.antialiased = false
            }
        }
    }
    
    // MARK: - Polygon Points
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     - parameter closed: `Bool` close the object path.
     */
    public func addPoints(coordinates: [[CGFloat]], closed: Bool=true) {
        self.objectType = (closed == true) ? ObjectType.Polygon : ObjectType.Polyline
        
        // create an array of points from the given coordinates
        points = coordinates.map { CGPoint(x: $0[0], y: $0[1]) }
    }
    
    /**
     Add points from a string.
     
     - parameter points: `String` string of coordinates.
     */
    public func addPointsWithString(points: String) {
        var coordinates: [[CGFloat]] = []
        let pointsArray = points.componentsSeparatedByString(" ")
        for point in pointsArray {
            let coords = point.componentsSeparatedByString(",").flatMap { x in Double(x) }
            coordinates.append(coords.flatMap { CGFloat($0) })
        }
        addPoints(coordinates)
    }
    
    /**
     Return the current points.
     
     - returns: `[CGPoint]?` array of points.
     */
    private func getVertices() -> [CGPoint]? {
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
}



extension SKTileObject {
    
    override public var hashValue: Int {
        return id.hashValue
    }
    
    override public var description: String {
        let objectName: String = name != nil ? "\"\(name!)\"" : "(null)"
        return "\(String(objectType)) Object: \(objectName), id: \(self.id)"
    }
    
    override public var debugDescription: String {
        return description
    }
}
