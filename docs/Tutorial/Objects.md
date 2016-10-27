#Working with Objects

By default, objects are not shown when rendered in **SKTiled**. To enable them, set the `SKTilemap.showObjects` global attribute. This override has the advantage of allowing you to work in your Tiled scene with objects visible, but not see them in your game view.

The [`SKTileObject`](Classes/SKTileObject.html) class represents a vector object in a object group layer. **SKTiled** renders all Tiled object types:

- Rectangle
- Ellipse
- Polygon
- Polyline

[`SKTileObject`](Classes/SKTileObject.html) objects are subclasses of `SKShapeNode`. Each object's path is drawn from the `SKTileObject.points` property.


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


###Dynamics

![Object Dynamics](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/dynamics-start.png)

You also have the option of enabling physics for each object, allowing them to react as dynamics bodies in your scene. Enabling the `SKTileObject.isDynamic` property allows you to easily create dynamic objects in your scenes.



 Next: [Properties](properties.html) - [Index](Tutorial.html)
