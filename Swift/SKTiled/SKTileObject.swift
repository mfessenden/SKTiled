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
public class SKTileObject: SKShapeNode {

    weak public var layer: SKObjectGroup!            // layer parent, assigned on add
    public var id: Int = 0                           // unique id
    public var type: String!                         // object type
    public var objectType: ObjectType = .Rectangle   // shape type
    
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
    
    override public init(){
        super.init()
    }
    
    // id, name, type, x, y, width, height, rotation, gid, visible
    // ["type": "Tent", "x": "368.124", "id": "7", "y": "79.7574", "name": "tent1"]
    public init?(attributes: [String: String]) {
        // required attributes
        guard let objectID = attributes["id"] else { return nil }        
        guard let xcoord = attributes["x"] else { return nil }        
        guard let ycoord = attributes["y"] else { return nil }        
        
        id = Int(objectID)!
        super.init()
        
        //let ry = ycoord
        position = CGPointMake(CGFloat(Double(xcoord)!), CGFloat(Double(ycoord)!))
        
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
        
        self.size = CGSizeMake(width, height)
        draw()
    }
    
    /**
     Set the fill & stroke colors (with optional alpha component for the fill)
     
     - parameter color: `SKColor` fill & stroke color.
     - parameter alpha: `CGFloat` alpha component for fill.
     */
    public func setColor(color: SKColor, withAlpha alpha: CGFloat=0.2) {
        self.strokeColor = color
        self.fillColor = color.colorWithAlphaComponent(alpha)
    }
    
    /**
     Draw the path.
     */
    public func draw() {
        // draw the path
        var objectPath: UIBezierPath?
        
        switch objectType {            
        case .Rectangle:
            objectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            
        case .Ellipse:
            objectPath = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        case .Polygon:
            objectPath = nil
        
        case .Polyline:
            objectPath = nil
        }
        
        if let objectPath = objectPath {
            //objectPath.lineWidth = 1.5
            self.path = objectPath.CGPath
            self.antialiased = false
            self.lineWidth = 1.0
        }
    }
    
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     - parameter closed: `Bool` close the object path.
     */
    public func addPoints(points: [[CGFloat]], closed: Bool=true) {
        self.objectType = (closed == true) ? ObjectType.Polygon : ObjectType.Polyline
        self.fillColor = (closed == true) ? self.fillColor : SKColor.clearColor()

        var cgpoints: [CGPoint] = points.map { CGPointMake($0[0], $0[1]) }
        let firstPoint = cgpoints.removeFirst()
        
        // draw the starting point
        let firstRadius: CGFloat = 2.0
        let firstPath = UIBezierPath(ovalInRect: CGRect(x: firstPoint.x - (firstRadius / 2), y: firstPoint.y - (firstRadius / 2), width: firstRadius, height: firstRadius))
        let firstStrokeColor = SKColor.clearColor()
        firstPath.stroke()
        firstStrokeColor.setStroke()
        self.strokeColor.setFill()
        firstPath.fill()
        
        // draw the points
        let polygonPath = UIBezierPath()
        polygonPath.lineCapStyle = .Square
        self.strokeColor.setStroke()
        polygonPath.moveToPoint(firstPoint)
        
        for point in cgpoints {
            polygonPath.addLineToPoint(point)
        }
        
        if (closed == true) { polygonPath.closePath() }
        
        // append the first point to the path
        polygonPath.appendPath(firstPath)
        self.path = polygonPath.CGPath
        self.lineWidth = 1.0
        self.antialiased = false
    }
    
    public func addPointsWithString(points: String) {
        // <polygon points="-1,0 -1,-18 14,-32 30,-18 30,0"/>
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
