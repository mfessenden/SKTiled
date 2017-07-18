# Working with Objects

- [Object Types](#object-types)
- [Dynamics](#dynamics)

By default, objects are not shown when rendered in **SKTiled**. To enable them, set the `SKTilemap.showObjects` global attribute. This override has the advantage of allowing you to work in your Tiled scene with objects visible, but not see them in your game view.

The [`SKTileObject`](Classes/SKTileObject.html) class represents a vector object in a object group layer. **SKTiled** renders all Tiled object types:

- Rectangle
- Ellipse
- Polygon
- Polyline

[`SKTileObject`](Classes/SKTileObject.html) objects are subclasses of `SKShapeNode`. Each object's path is drawn from the `SKTileObject.points` property.


## Object Types

Objects assigned a type in Tiled will retain that property in **SKTiled**, accessed with the optional `SKTileObject.type` property:

![Tiled obeject types](images/object_types.png)

Objects assigned a type property can be queried from the parent [`SKObjectGroup`](Classes/SKObjectGroup.html):

```swift
let emitterObjects = objectsGroup.getObjects(ofType: "Emitter")
```

They can also be accessed from the [`SKTilemap`](Classes/SKTilemap.html) node:

```swift
let allEmitterObjects = tilemap.getObjects(ofType: "Emitter")
```

Note that this will return objects from multiple object layers.


## Dynamics

You also have the option of enabling physics for each object, allowing them to react as dynamics bodies in your scene. Passing properties from **Tiled** allows you to easily create dynamic objects in your scenes. Here, a simple scene with one object group and five objects is loaded:

- shape objects are assigned a property of `isDynamic = true`
- floor objects are assigned a property of `isCollider = true`
- map properties contain a `yGravity` value of `-9.8`


![Object Dynamics](images/dynamic-objects.gif)


 Next: [Properties](properties.html) - [Index](Tutorial.html)
