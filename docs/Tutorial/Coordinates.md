#Coordinates

SpriteKit uses a coordinate system that is different from Tiled's; in SpriteKit, a SpriteKit node's origin is on the bottom-left, while Tiled's origin is top-left. 

To emulate this, the `SKTilemap` node draws its layers starting at the origin and moving *downwards* into the negative y-space. To accomodate this, each layer type has methods for converting points into negative-y space:

```swift
// iOS with UITouch
let touchPosition = tileLayer.touchLocation(touch)

// OSX with NSEvent mouse event
let eventPosition = tileLayer.mouseLocation(event: mouseEvent)
```

Each layer type also have convenience methods for querying screen points or tile coordinates:

```swift
// covert coordinate position to CGPoint
let point = tileLayer.pointForCoordinate(3, 4)

// covert CGPoint to coordinate position
let coord = objectGroup.coordinateForPoint(point)
```

Each layer has the ability to independently query a coordinate (which can be different depending on each layer's offset). Querying a point in the parent `SKTilemap` node returns values in the default base layer.


###Layer Offsets & Hints

`TileOffset` - Offset hint for placement within each layer type.


`LayerPosition` -  Alignment hint used to position the layers within the `SKTilemap` node.

    TileOffset.BottomLeft  tile aligns at the bottom left corner.
    TileOffset.TopLeft     tile aligns at the top left corner.
    TileOffset.TopRight    tile aligns at the top right corner.
    TileOffset.BottomRight tile aligns at the bottom right corner.
    TileOffset.Center      tile aligns at the center.
    
    LayerPosition.BottomLeft  // 0   - node bottom left rests at parent zeropoint
    LayerPosition.Center      // 0.5 - node center rests at parent zeropoint
    LayerPosition.TopRight    // 1   - node top right rests at parent zeropoint
    

 Next: [Objects](objects.html)