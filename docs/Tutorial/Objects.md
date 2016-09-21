#Objects

The [`SKTileObject`](#SKTileObject) class represents a vector object in a object group layer. **SKTiled** objects just as they are in Tiled:

- Rectangle
- Ellipse
- Polygon
- Polyline

[`SKTileObject`](#SKTileObject) objects are subclasses of `SKShapeNode`. Each object is drawn from the `SKTileObject.points` property.


###Object Types

Objects assigned a type in Tiled will retain that property in **SKTiled**, accessed with the optional `SKTileObject.type` property:

![Tiled obeject types](../img/object_types.png)

Objects assigned a type property can be queried from the parent [`SKObjectGroup`](#SKObjectGroup):

```swift
let emitterObjects = objectsGroup.getObjects(ofType: "Emitter")
```

They can also be accessed from the [`SKTilemap`](#SKTilemap) node:

```swift
let allEmitterObjects = tilemap.getObjects(ofType: "Emitter")
```

Note that this will return objects from multiple object layers.


### Dynamics

Dynamics can be turned on for objects with the `SKTileObject.setupDynamics()` method.

### GameplayKit

The `SKTileObject.obstacleType` property will flag the object as an `GKObstacle`.


 Next: [Properties](properties.html)
