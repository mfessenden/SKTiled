//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public enum ObjectType: String {
    case rectangle
    case ellipse
    case polygon
    case polyline
}


/// simple object class
open class SKTileObject: SKShapeNode, SKTiledObject {

    weak open var layer: SKObjectGroup!            // layer parent, assigned on add
    open var uuid: String = UUID().uuidString      // unique id
    open var id: Int = 0                           // object id
    open var type: String!                         // object type
    open var objectType: ObjectType = .rectangle   // shape type
    
    open var points: [CGPoint] = []                // points that describe object shape
    
    open var size: CGSize = CGSize.zero
    open var properties: [String: String] = [:]    // custom properties
    
    // blending/visibility
    open var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    open var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
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
    
    /**
     Draw the path.
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
                    controlShape.strokeColor = self.strokeColor
                    controlShape.isAntialiased = true
                    controlShape.lineWidth = self.lineWidth / 2
                }
                
            default:
                let closedPath: Bool =  (self.objectType == .polyline) ? false : true
                self.path = polygonPath(vertices.map{$0.invertedY}, closed: closedPath)
            }
            
            // draw the first point of poly objects
            if (self.objectType == .polyline) || (self.objectType == .polygon) {
                
                childNode(withName: "ANCHOR")?.removeFromParent()
                
                var anchorRadius = self.lineWidth * 1.75
                if anchorRadius > layer.tileHeight / 8 {
                    anchorRadius = layer.tileHeight / 9
                }
                
                let anchor = SKShapeNode(circleOfRadius: anchorRadius)
                anchor.name = "ANCHOR"
                addChild(anchor)
                anchor.position = vertices[0].invertedY
                anchor.strokeColor = SKColor.clear
                anchor.fillColor = self.strokeColor
                anchor.isAntialiased = false
            }
        }
    }
    
    // MARK: - Polygon Points
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     - parameter closed: `Bool` close the object path.
     */
    open func addPoints(_ coordinates: [[CGFloat]], closed: Bool=true) {
        self.objectType = (closed == true) ? ObjectType.polygon : ObjectType.polyline

        // create an array of points from the given coordinates
        points = coordinates.map { CGPoint(x: $0[0], y: $0[1]) }
    }
        
    /**
     Add points from a string.
        
     - parameter points: `String` string of coordinates.
     */
    open func addPointsWithString(_ points: String) {
        var coordinates: [[CGFloat]] = []
        let pointsArray = points.components(separatedBy: " ")
        for point in pointsArray {
            let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
            coordinates.append(coords.flatMap { CGFloat($0) })
        }
        addPoints(coordinates)
    }
    
    /**
     Return the current points.
     
     - returns: `[CGPoint]?` array of points.
     */
    fileprivate func getVertices() -> [CGPoint]? {
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
    
    override open var hashValue: Int {
        return id.hashValue
    }
    
    override open var description: String {
        let objectName: String = name != nil ? "\"\(name!)\"" : "(null)"
        return "\(String(describing: objectType).capitalized) Object: \(objectName), id: \(self.id)"
    }
    
    override open var debugDescription: String {
        return description
    }
}
