##Tutorial

Using tiled maps in your own projects is very easy. The included `SKTiledScene` class conforms to the `SKTiledSceneDelegate` protocol and could serve as a template for your scenes though it is possible to implement your own scene type.

If you choose to create your own scene type, a simple scene setup could be as simple as:


```swift
import SpriteKit

public class GameScene: SKScene {
    override public func didMoveToView(view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: "myTiledFile") {
            addChild(tilemap)
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
        }
    }
}
```


####Setup

The world container node is set to 0,0 in the scene.

By default, the tilemap uses a default tile layer accessible via `SKTilemap.baseLayer`.      


####Coordinate Space

SpriteKit uses a coordinate system that is different from Tiled's; in SpriteKit, a SpriteKit node's origin is on the bottom-left, while Tiled's origin is top-left. To emulate this, the `SKTilemap` object draws its layers starting at the origin and moving downwards into the negative y-space. To account for this, use the `TiledLayerObject.convertPoint` method to return a point in the layer's coordinate space. Each layer has the ability to independently query a coordinate ( which can be different depending on the layer's offset). 


The following helper functions will take & return points in SpriteKit space:

`TiledLayerObject.pointForCoordinate`

`TiledLayerObject.coordinateForPoint`




####Hints

`TileOffset` - Offset hint for placement within 


`LayerPosition` -  Alignment hint used to position the layers within the `SKTilemap` node.


    TileOffset.BottomLeft  tile aligns at the bottom left corner.
    TileOffset.TopLeft     tile aligns at the top left corner.
    TileOffset.TopRight    tile aligns at the top right corner.
    TileOffset.BottomRight tile aligns at the bottom right corner.
    TileOffset.Center      tile aligns at the center.
    
    LayerPosition.BottomLeft  // 0   - node bottom left rests at parent zeropoint
    LayerPosition.Center      // 0.5 - node center rests at parent zeropoint
    LayerPosition.TopRight    // 1   - node top right rests at parent zeropoint
    

####Important

If your Tiled files include image references that contain directories, you *must* include that directory in your Xcode project as a folder reference (not a group).