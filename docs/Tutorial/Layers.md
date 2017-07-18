#Working with Layers

- [Default Layer](#default-layer)
- [Group Layers](#group-layers)
- [Isolating Layers](#isolating-layers)

Once the map is loaded, you can begin working with the layers. There are several ways to access layers from the [`SKTilemap`](Classes/SKTilemap.html) object:

```swift
// returns a tile layer with a given name
let backgoundLayer = tilemap.getLayer(named: "Background") as! SKTileLayer
```

Once you have a layer, you can add child nodes to it (any `SKNode` type is allowed):

```swift
// add a child node
playerLayer.addChild(player)

// set the player position based on coordinate x & y values
player.position = playerLayer.pointForCoordinate(4, 12)
```

It is also possible to provide an offset value in x/y for more precise positioning:

```swift
player.position = playerLayer.pointForCoordinate(4, 12, offsetX: 8.0, offsetY: 4.0)
```

All [`TiledLayerObject`](Classes/TiledLayerObject.html) objects have convenience methods for adding children with coordinate values & optional offset and zPosition values:

```swift
playerLayer.addChild(player, 4, 12, zpos: 25.0)
```

See the [Coordinates](coordinates.html) page for more information.

##Default Layer

By default, the [`SKTilemap`](Classes/SKTilemap.html) class uses a default tile layer accessible via the `SKTilemap.baseLayer` property. The base layer is automatically created is used for coordinate transforms and for visualizing the grid (the base layer's z-position is always higher than the other layers).

##Group Layers

![Group Layers](images/group-layers.png)

Group layers are a new feature in Tiled v0.18.2. Group layers are treated as any other layer type; adding or changing properties on a parent group will affect layers in the group.


```swift
// query all of the group layers in the map
let groupLayers = tilemap.groupLayers
```

##Isolating Layers

You can isolate a layer (as you can in Tiled):

```swift
// isolate the layer named 'Background'
tilemap.isolateLayer("Background")

// pass nil to the method to show all layers
tilemap.isolateLayer(nil)
```

Next: [Working with Tiles](tiles.html) - [Index](Tutorial.html)
