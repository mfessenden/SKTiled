# Coordinates

- [Coordinate Conversion](#coordinate-conversion)
- [User Interaction](#user-interaction)
- [Coordinate Offsets & Hints](#coordinate-offsets-amp-hints)

## Coordinate Conversion

SpriteKit uses a coordinate system that is different from Tiled's; SpriteKit scenes' origin is at the bottom-left, while Tiled sets the origin at top-left.

To emulate this, the `SKTilemap` node draws its layers starting at the origin and moving *downwards* into the negative y-space. To accommodate this, each layer type has conversion methods for converting points to coordinates and vice-versa. Be sure to convert points to the layer you are querying to return the correct coordinate.

Remember that the layers are centered on the `SKTilemap` origin.

```swift
// convert a position in the current view to a scene position
let positionInScene = view.convert(point, to: scene)

// convert a scene point to the layer's position
let positionInLayer = tileLayer.convert(positionInScene, from: scene).invertedY

// get the coordinate at the specified point
let coord = tileLayer.coordinateForPoint(positionInLayer)
```

If adding objects to a layer, you can easily get a position for a Tiled coordinate:


```swift
// get position in a layer for the given coordinate
let point = tileLayer.pointForCoordinate(3, 4)
```

### Converting Coordinates from Other Nodes

Use the default [`SKNode.convert(_:from:)`](https://developer.apple.com/reference/spritekit/sknode/1483058-convert) method to convert a tile position to another node's coordinate space. If you wanted to add a node to the `SKTiledScene`:

```swift
let positionInLayer = layer.pointForCoordinate(0, 17)
newTile.position = worldNode.convert(positionInLayer, from: layer)
```

## User Interaction

**SKTiled** also has methods for handling touch events (iOS) and mouse events (macOS):


```swift
// iOS with UITouch
let touchPosition = tileLayer.touchLocation(touch)

// OSX with NSEvent mouse event
let eventPosition = tileLayer.mouseLocation(event: mouseEvent)
```

You can also query coordinates at an event directly:

```swift
// get the coordinate of a touch event
let coord = tileLayer.coordinateAtTouchLocation(touch)


// get the coordinate of a mouse event
let coord = tileLayer.coordinateAtMouseEvent(event: event)
```


It's important to remember that each layer has the ability to independently query a coordinate (which can be different depending on each layer's offset). Querying a point in the parent `SKTilemap` node returns values in the **default layer**.


## Coordinate Offsets & Hints


When converting a tile coordinate to screen points, you can also add optional pixel offset values:

```swift
// use CGFloat for offset
let point = tileLayer.pointForCoordinate(3, 4, offsetX: 4, offsetY: 0)

// use TileOffset for offset
let point = tileLayer.pointForCoordinate(3, 4, offset: TileOffset.center)
```


The `SKTiledLayerObject.TileOffset` enum represents a hint for placement within each layer type:

     TileOffset.center        // returns the center of the tile.    
     TileOffset.top           // returns the top of the tile.
     TileOffset.topLeft       // returns the top left of the tile.
     TileOffset.topRight      // returns the top left of the tile.
     TileOffset.bottom        // returns the bottom of the tile.      
     TileOffset.bottomLeft    // returns the bottom left of the tile.
     TileOffset.bottomRight   // returns the bottom right of the tile.
     TileOffset.left          // returns the left side of the tile.
     TileOffset.right         // returns the right side of the tile.



 Next: [Working with Objects](working-with-objects.html) - [Index](Table of Contents.html)
