#Coordinates

- [Coordinate Conversion](#coordinate-conversion)
- [User Interaction](#user-interaction)
- [Coordinate Offsets & Hints](#coordinate-offsets-amp-hints)

##Coordinate Conversion

SpriteKit uses a coordinate system that is different from Tiled's. In SpriteKit, scenes have an origin at the bottom-left, while Tiled sets the origin at top-left. 

To emulate this, the [`SKTilemap`](Classes/SKTilemap.html) node draws its layers starting at the origin and moving *downwards* into the negative y-space. To accommodate this, each layer type has conversion methods for converting points to coordinates and vice-versa:

```swift
// covert coordinate position to CGPoint
let point = tileLayer.pointForCoordinate(3, 4)

// covert CGPoint to coordinate position
let coord = objectGroup.coordinateForPoint(point)
```


When converting a tile coordinate to screen points, you can also add optional offset values:

```swift
// use CGFloats as offsets
let point = tileLayer.pointForCoordinate(3, 4, offsetX: 4, offsetY: 0)

// use TileOffset 
let point = tileLayer.pointForCoordinate(3, 4, offset: TileOffset.center)
```

###Converting Coordinates from Other Nodes

Use the default `SKNode.convert` method to convert a tile position to another node's coordinate space:

```swift
let playerPosition = worldNode.convert(tilemap.baseLayer.pointForCoordinate(0, 17), from: tilemap.baseLayer)
```

##User Interaction

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


It's important to remember that each layer has the ability to independently query a coordinate (which can be different depending on each layer's offset). Querying a point in the parent [`SKTilemap`](Classes/SKTilemap.html) node returns values in the **default base layer**.



##Coordinate Offsets & Hints


The [`TileOffset`](Enums/TileOffset.html) enum represents a hint for placement within each layer type:
    
     TileOffset.center        // returns the center of the tile.    
     TileOffset.top           // returns the top of the tile.
     TileOffset.topLeft       // returns the top left of the tile.
     TileOffset.topRight      // returns the top left of the tile.
     TileOffset.bottom        // returns the bottom of the tile.      
     TileOffset.bottomLeft    // returns the bottom left of the tile.
     TileOffset.bottomRight   // returns the bottom right of the tile.
     TileOffset.left          // returns the left side of the tile.
     TileOffset.right         // returns the right side of the tile.
    


 Next: [Working with Objects](objects.html) - [Index](Tutorial.html)
