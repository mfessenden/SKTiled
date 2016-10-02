#Working with Objects

By default, objects are not shown when rendered in **SKTiled**. To enable 

The [`SKTileObject`](Classes/SKTileObject.html) class represents a vector object in a object group layer. **SKTiled** objects just as they are in Tiled:

- Rectangle
- Ellipse
- Polygon
- Polyline

[`SKTileObject`](Classes/SKTileObject.html) objects are subclasses of `SKShapeNode`. Each object is drawn from the `SKTileObject.points` property.


###Object Types

Objects assigned a type in Tiled will retain that property in **SKTiled**, accessed with the optional `SKTileObject.type` property:

![Tiled obeject types](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/object_types.png)

Objects assigned a type property can be queried from the parent [`SKObjectGroup`](Classes/SKObjectGroup.html):

```swift
let emitterObjects = objectsGroup.getObjects(ofType: "Emitter")
```

They can also be accessed from the [`SKTilemap`](Classes/SKTilemap.html) node:

```swift
let allEmitterObjects = tilemap.getObjects(ofType: "Emitter")
```

Note that this will return objects from multiple object layers.


 Next: [Properties](properties.html) - [Index](Tutorial.html)
