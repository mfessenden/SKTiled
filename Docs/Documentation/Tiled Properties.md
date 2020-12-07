# Tiled Properties

- [Querying Properties](#querying-properties)
- [Object Types](#object-types)
- [Querying Properties](#custom-properties)
- [Custom Properties](#custom-properties)

One of the most useful features of **SKTiled** is the ability to exploit Tiled's custom properties for most objects.
Any object that conforms to the `SKTiledObject` protocol will inherit methods for parsing Tiled object properties.

**SKTiled** supports the newer **color** and **file** property types (values are stored as strings internally anyway, which *SKTiled* already supports). The custom color/file types listed above will also be parsed if they are created as string types in Tiled.

Currently all **SKTiled** property values are stored as strings, though this may change in the future.


## Querying Properties

The `SKTiledObject` protocol enables you to easily query attributes in your scenes. The methods work exactly the same for all **SKTiled** classes.


```swift
// access tile data properties
tileData.properties

// query an object to see if it has a named property
floorObject.hasKey("slippery")

// access a named property
let slipperyValue = floorObject.stringForKey("slippery")!

// update a value
floorObject.setValue(forKey: "slippery", "1.2")

// get tile data that have a named property (regardless of value)
let dynamicObjects = tilemap.getTileData(withProperty: "mass")

// get tile data that have a named property (with a specific value)
let heavyDynamicObjects = tilemap.getTileData(withProperty: "mass", "10.0")

// removing a named property returns the value (or nil if it doesn't exist)
if let levelName = tilemap.removeProperty(forKey: "levelName") {
    print("Level name was '\(levelName)'")
}

```

## Object Types

![Type Property](images/type-property.png)

Some object types in [**Tiled**][tiled-url] have a special `type` property (tiles, objects). The base `SKTiledObject` protocol in **SKTiled** contains a `type` property, which means that all **SKTiled** objects inherit it (not just the objects that Tiled supports).

This means that you can set this attribute for tilesets, all layer types, even the map itself. If the object has a `type` property in Tiled, that will be assigned as a value. If the object has custom string property `type`, that will be used instead.


## Custom Properties

**SKTiled** recognizes several custom properties that can be used to change attributes of objects in your Tiled scenes. For instance, adding an `zPosition` float property to a layer or object in Tiled will override the property in SpriteKit.


If you wish to ignore custom properties when your scene is read, you can pass the `ignoreProperties` argument to the `SKTilemap.load` method:

```swift
let tilemap = SKTilemap.load(tmxFile: "myTiledFile", ignoreProperties: true)
```


#### SKTilemap

| Property            |  Type  | Description                                      |  Notes   |
|:------------------- |:------:|:------------------------------------------------ |:--------:|
| name                | String | map name (defaults to tmx filename).             |          |
| hidden              |  Bool  | hide the map.                                    |          |
| worldScale          | Float  | world starting scale.                            |          |
| gridColor           | Color  | color used for visualizing the tile grid.        |  debug   |
| gridOpacity         | Float  | grid overlay opacity.                            |  debug   |
| frameColor          | Color  | color used for visualizing the bounding box.     |  debug   |
| highlightColor      | Color  | color used for highlighting tiles.               |  debug   |
| overlayColor        | Color  | pause overlay color.                             |          |
| objectColor         | Color  | base color for drawing objects.                  |          |
| zDelta              | Float  | default z-distance between layers.               |          |
| zPosition           | Float  | initial zPosition.                               |          |
| allowMovement       |  Bool  | scene camera movement enabled.                   |          |
| allowZoom           |  Bool  | scene camera zoom enabled.                       |          |
| showObjects         |  Bool  | globally show/hide objects in all object groups. |          |
| tileOverlap         | Float  | tile overlap amount.                             |          |
| maxZoom             | Float  | maximum camera zoom.                             |          |
| minZoom             | Float  | minimum camera zoom.                             |          |
| ignoreBackground    |  Bool  | ignore Tiled background color.                   |          |
| antialiasLines      |  Bool  | antialias lines.                                 |          |
| autoResize          |  Bool  | automatically resize the map in view.            |          |
| xGravity            | Float  | gravity in x.                                    | dynamics |
| yGravity            | Float  | gravity in y.                                    | dynamics |
| cropAtBoundary      |  Bool  | crop the map at boundaries.                      |          |
| shouldEnableEffects |  Bool  | toggle effects rendering on the map.             |          |


#### SKTiledLayerObject

| Property            |  Type  | Description                                         | Notes |
|:------------------- |:------:|:--------------------------------------------------- |:-----:|
| antialiasing        |  Bool  | antialias lines.                                    |       |
| hidden              |  Bool  | hide the layer.                                     |       |
| color               | String | hex string to override color.                       |       |
| gridColor           | Color  | color used for visualizing the tile grid.           |       |
| graphName           | String | graph name for identifying pathfinding graph.       |       |
| frameColor          | Color  | color used for visualizing layer bounding box.      | debug |
| backgroundColor     | Color  | color used for visualizing the tile grid.           |       |
| zPosition           | Float  | used to manually override layer zPosition.          |       |
| isDynamic           |  Bool  | creates a collision object from the layer's border. |       |
| navigationKey       | String | navigation key used with navigation graphs.         |       |
| shouldEnableEffects |  Bool  | toggle effects rendering on the layer.              |       |

#### SKObjectGroup

| Property    | Type  | Description                                    | Notes |
|:----------- |:-----:|:---------------------------------------------- |:-----:|
| lineWidth   | Float | object line width.                             |       |
| showNames   | Bool  | display object names.                          |       |
| showObjects | Bool  | globally show/hide objects.                    |       |
| isDynamic   | Bool  | automatically create objects as dynamic bodies |       |


#### SKImageLayer


| Property | Type  | Description                  | Notes |
|:-------- |:-----:|:---------------------------- |:-----:|
| frame    | File  | image layer animation frame. |       |
| duration | Float | frame duration.              |       |


#### SKTilesetData

| Property       |  Type  | Description                         | Notes |
|:-------------- |:------:|:----------------------------------- |:-----:|
| name           | String | used to identify tile data by name. |       |
| collisionSize  | Float  | used to add collision to the tile.  |       |
| collisionShape |  Int   | 0 = rectangle, 1 = circle.          |       |
| renderMode     |  Int   | tile render mode.                   |       |


#### SKTileObject

| Property       |  Type  | Description                          | Notes |
|:-------------- |:------:|:------------------------------------ |:-----:|
| collisionSize  | Float  | used to add collision to the tile.   |       |
| collisionShape |  Int   | 0 = rectangle, 1 = circle.           |       |
| hidden         |  Bool  | hide the object.                     |       |
| color          | String | hex string to override object color. |       |
| lineWidth      | Float  | object line width.                   |       |
| isDynamic      |  Bool  | object is dynamic.                   |       |
| isCollider     |  Bool  | object is passive collision object.  |       |
| mass           | Float  | physics mass.                        |       |
| friction       | Float  | physics friction.                    |       |
| restitution    | Float  | physics 'bounciness'.                |       |
| linearDamping  | Float  | physics linear damping.              |       |
| angularDamping | Float  | physics angular damping.             |       |
| zPosition      | Float  | initial zPosition.                   |       |
| proxyColor     | Color  | object proxy visualization color     |       |



Next: [GameplayKit](gameplaykit.html) - [Index](Table of Contents.html)


[tiled-url]:http://www.mapeditor.org
