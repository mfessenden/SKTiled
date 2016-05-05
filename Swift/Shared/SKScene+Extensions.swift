
import Foundation
import SpriteKit


public extension SKScene {
    /**
     Returns the center point of a scene.
     */
    public var center: CGPoint {
        return CGPointMake(self.size.width/2, self.size.height/2)
    }
    
    /**
     Calculate the distance from the scene's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - self.size.width/2)
        let dy = (pos.y - self.size.height/2)
        return CGVectorMake(dx, dy)
    }
}

