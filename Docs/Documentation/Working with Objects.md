# Working with Objects

- [Object Types](#object-types)
- [Tile Objects](#tile-objects)
- [Text Objects](#text-objects)
    - [Text Object Attributes](#text-object-attributes)
- [Dynamics](#dynamics)

By default, vector objects are not shown when rendered in **SKTiled**. To enable them, set the `SKTilemap.showObjects` global attribute. This override has the advantage of allowing you to work in your Tiled scene with objects visible, but not see them in your game view. Note that the `SKTilemap.showObjects` property **does not change the visibility of object groups**, but rather affects the objects themselves. Text and tile objects are exempt from this function.

The `SKTileObject` class represents a vector object in a object group layer. **SKTiled** renders all Tiled object types:

- Rectangle
- Ellipse
- Polygon
- Polyline


`SKTileObject` objects are subclasses of [`SKShapeNode`][skshapenode-url]. Each object stores an array of points from which the path is drawn.

## Object Type Property

Objects assigned a type in Tiled will retain that property in **SKTiled**, accessed with the optional `SKTileObject.type` property:

![Tiled object types](images/object_types.png)

Objects assigned a type property can be queried from the parent `SKObjectGroup`, or the `SKTilemap` node:

```swift
// query objects from the layer
let emitterObjects = objectsGroup.getObjects(ofType: "Emitter")

// query objects from the map node
let allEmitterObjects = tilemap.getObjects(ofType: "Emitter", recursive: true)
```

The `recursive` argument is optional in both instances, and enabling it will search all object layers in the map, including nested layers.


## Tile Objects

![Tile Objects](images/tile-objects-selected.gif)

Tile objects are objects with an optional id value. The corresponding tile texture is rendered within the object's bounding shape.


Objects added via the [**Insert Tile**][insert-tile-url] tool in Tiled will render as `SKTileObject` objects. You can also create a tile object manually via the `SKObjectGroup.newTileObject(data:)` method:

```swift
// add a tile object for global id 23
if let tileData = tilemap.getTileData(globalID: 23) {
    if let tileObject = objectGroup.newTileObject(data: tileData) {
        tileObject.position = objectGroup.pointForCoordinate(10, 5)
    }
}
```

If the tile data contains animated frames, the resulting object will also render as animated.


## Text Objects

![Text Objects](images/text-objects.png)

Text objects are objects that render text within the bounding shape. Basic formatting properties are supported via the `TextObjectAttributes` property. To change the text on the fly, all you need to do is change the object's `text` property. The object will redraw automatically.

There are several ways to query text objects:

```swift
if let scoreObject = objectGroup.getObjects(withText: "SCORE").first {
    // update the rendered text
    scoreObject.text = "2000"
}
```

If you intend to update the text object dynamically, be mindful to draw the object in Tiled to the appropriate size to avoid text clipping.


### Text Object Attributes

By default, text object attributes are translated from **Tiled**\*. It is possible to change the text attributes via the `SKTileObject.textAttributes` property.

```swift
textObject.textAttributes.fontName = "Courier"
textObject.textAttributes.fontSize = 16
textObject.textAttributes.fontColor = .white
textObject.textAttributes.alignment.horizontal = .center
```

*\* text wrap attribute not currently supported.*



## Dynamics

You also have the option of enabling physics for each object, allowing them to react as dynamics bodies in your scene. Passing properties from **Tiled** allows you to easily create dynamic objects in your scenes. Here, a simple scene with one object group and five objects is loaded:

- shape objects are assigned a property of `isDynamic = true`
- floor objects are assigned a property of `isCollider = true`
- map properties contain a `yGravity` value of `-9.8`


![Object Dynamics](images/dynamic-objects.gif)


 Next: [Tiled Properties](tiled-properties.html) - [Index](Table of Contents.html)


[sktiled-doc-url]:https://mfessenden.github.io/SKTiled


<!--- Apple --->
[skshapenode-url]:https://developer.apple.com/documentation/spritekit/skshapenode

<!--- Tiled --->
[insert-tile-url]:http://doc.mapeditor.org/de/latest/manual/objects/#insert-tile
