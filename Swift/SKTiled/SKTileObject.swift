//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public enum ShapeType {
    case Rectangle
    case Ellipse
    case Polygon
}


/// simple object class
public class SKTileObject: SKShapeNode {
    
    public var id: Int = 0                         // unique id
    public var type: String!                       // object type
    public var shapeType: ShapeType = .Rectangle   // shape type
    
    public var size: CGSize = CGSizeZero
    public var color: SKColor = SKColor.blackColor()
    
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
        
        self.size = CGSizeMake(width, height)
        drawPath()
    }
    
    public func update() {
        drawPath()
    }
    
    /**
     Draw the path.
     */
    private func drawPath() {
        // draw the path
        var objectPath: UIBezierPath?
        
        if shapeType == .Rectangle {
            objectPath = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        } else if shapeType == .Ellipse {
            objectPath = UIBezierPath(rect: CGRect(x: 50, y: 47, width: 149, height: 157))
        }
        
        if let objectPath = objectPath {
            self.path = objectPath.CGPath
            //self.color.setStroke()
        }
    }
    
    /**
     Add polygons points.
     
     - parameter points: `[[CGFloat]]` array of coordinates.
     */
    public func addPoints(points: [[CGFloat]]) {
        self.shapeType = ShapeType.Polygon
        let polygonPath = UIBezierPath()
        for point in points {
            polygonPath.moveToPoint(CGPoint(x: point[0], y: point[1]))
        }
        polygonPath.closePath()
        self.path = polygonPath.CGPath
        //self.color.setStroke()
    }
    
    override public var hidden: Bool {
        didSet {
            guard oldValue != hidden else { return }
            
            var currentColor: SKColor = (hidden == true) ? self.color : SKColor.clearColor()
            //currentColor.setStroke()
            //currentColor.setFill()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



extension SKTileObject {
    
    override public var hashValue: Int {
        return id.hashValue
    }
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
 
    func debugQuickLookObject() -> AnyObject {
        return path!
    }
  */
}
