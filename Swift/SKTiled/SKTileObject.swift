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
}


/// simple object class
public class SKTileObject: SKShapeNode {

    weak public var layer: SKObjectGroup!            // layer parent, assigned on add
    public var id: Int = 0                           // unique id
    public var type: String!                         // object type
    public var objectType: ObjectType = .Rectangle   // shape type
    
    public var size: CGSize = CGSizeZero
    public var properties: [String: String] = [:]    // custom properties
    
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
        case .Ellipse:
            objectPath = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        case .Polygon:
            objectPath = nil
        
        default:
            objectPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        
        if let objectPath = objectPath {
            //objectPath.lineWidth = 1.5
            self.path = objectPath.CGPath
            self.lineWidth = 2.0
        }
    }
    
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     */
    public func addPoints(points: [[CGFloat]]) {
        self.objectType = ObjectType.Polygon

        var cgpoints: [CGPoint] = points.map { CGPointMake($0[0], $0[1]) }
        let firstPoint = cgpoints.removeFirst()
        
        let polygonPath = UIBezierPath()
        polygonPath.moveToPoint(firstPoint)
        
        for point in cgpoints {
            polygonPath.addLineToPoint(point)
        }
        
        polygonPath.closePath()
        self.path = polygonPath.CGPath
        self.lineWidth = 2.0
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
