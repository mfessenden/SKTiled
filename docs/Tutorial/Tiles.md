# Working with Tiles

- [Getting Tiles with Tile ID](#getting-tiles-with-tile-id)
- [Getting Tiles of Type](#getting-tiles-of-type)
- [Getting Tiles with Property](#getting-tiles-with-property)
- [Adding Tiles](#adding-tiles)
- [Removing Tiles](#removing-tiles)
- [Animated Tiles](#animated-tiles)
- [Physics](#physics)
- [Tile Overlap](#tile-overlap)

**SKTiled** provides several ways to work with tiles in your tilemap. Most of the methods for querying tiles from tile layer instances have corresponding methods in the parent `SKTilemap` node which will aggregate the results from *all* tile layers.

Accessing tiles is simple: simply query a tile layer or the tile map node for tiles at a given coordinate:

```swift
// return tile(s) at a given location
let coord = CGPoint(x: 10, y: 8)
let tilesForCoord = tileLayer.tileAt(coord: coord)
let allTilesForCoord = tilemap.tilesAt(coord: coord)
```

### Getting Tiles with Tile ID

To query tiles with a global ID, pass the value to either the `SKTilemap` node, or an individual `SKTileLayer` node:

```swift
// query tiles from the tile map node
let tiles = tilemap.getTiles(withID: 10)

// query tiles from the parent layer
let tiles = tileLayer.getTiles(withID: 10)
```

### Getting Tiles of Type

The property "type" can be used to label or group tiles in **SKTiled**. Simply adding a string property to a tile ID will allow it to be accessed from SpriteKit:

![Tile Types](images/tile-types.png)

Querying any tile with that property is simple:

```swift
let allFireTiles = tilemap.getTiles(ofType: "Fire")
let waterTiles = tileLayer.getTiles(ofType: "Water")
```

### Getting Tiles with Property

You are not restricted to using **type** as a property name, any property name can be queried:

```swift
let fireTiles = tilemap.getTilesWithProperty("type", "Fire" as AnyObject)
```

## Adding Tiles

To add a new tile using a GID, use the [`SKTileLayer.addTileAt`](Classes/SKTileLayer.html#/s:FC7SKTiled11SKTileLayer9addTileAtFTSiSi3gidGSqSi__GSqCS_6SKTile_) method to add it to the current layer:

```swift
if let tile = tileLayer.addTile(at: 5, 8, gid: 32) {
    // success!
}
```

You are not limited to using tile objects; any `SKNode` type can be added to a layer and positioned. All [`TiledLayerObject`](Classes/TiledLayerObject.html) objects have expanded `addChild` convenience methods for positioning nodes:

```swift
// add a child with a coordinate and offset and zPosition values
tileLayer.addChild(tile, 5, 8, offset: CGPoint(x: 4.0, y: 8.0), zpos: 50)

// add a child with a coordinate and offset-x value
tileLayer.addChild(tile, 5, 8, dx: 4)
```

## Removing Tiles

To remove a tile, simply call one of the `SKTileLayer.removeTileAt` methods:

```swift
if let removedTile = tileLayer.removeTileAt(10, 8) {
    // do something with tile
}
```

## Animated Tiles

![Animated Tiles](images/animated-tiles.gif)

Tiles animated in Tiled are have custom SpriteKit actions automatically created to animate the tile texture. Animated tiles are accessed with the `SKTileLayer.getAnimatedTiles` method, or globally via the `SKTilemap.getAnimatedTiles` method:

```swift
// return animated tiles in a single layer
let animatedTiles = tileLayer.getAnimatedTiles()

// return all animated tiles
let allAnimatedTiles = tilemap.getAnimatedTiles()
```

All [`SKTile`](Classes/SKTile.html) instances allow you to pause & remove animations:

```swift

// pause or unpause tile animation 
for animatedTile in animatedTiles {
    animatedTile.pauseAnimation = true
}

// remove the animation (optionally restore the original texture)
for animatedTile in animatedTiles {
    animatedTile.removeAnimation(restore: true)
}
```

Since animation data is stored in the `SKTilesetData` node, to restart removed animation, simply run the `SKTile.runAnimation` method again.

To add animation to a tile, add GID values to the `SKTilesetData` instance associated with each tile:

```swift
// add frame GIDs
let tileData = tile.tileData
tileData.addFrame(withID: 33, interval: 0.25)
tileData.addFrame(withID: 34, interval: 0.35)
tileData.addFrame(withID: 35, interval: 0.15)

// run the animation
tile.runAnimation()
```

## Physics

Physics can be turned on for tile objects with the `SKTileObject.setupPhysics` methods. Passing the argument `isDynamic` determines whether the physics body is active or passive. 

```swift
// create a physics body with a rectangle of size 8
tile.setupPhysics(shapeOf: .rectangle, isDynamic: true)

// create a physics body with a rectangle of size 8
tile.setupPhysics(rectSize: CGSize(width: 8, height: 8), isDynamic: true)

// setup dynamics on an array of tiles with a radius of 4
let dots = dotsLayer.getTilesWithProperty("type", "dot" as AnyObject)
dots.forEach {$0.setupDynamics(radius: 4)}
```

## Tile Overlap

The tile overlap value is used to help alleviate the "cracks" that sometimes appear when the tilemap or worldNode is scaled. The value is clamped with the `SKTile.maxOverlap` value. Usually a value between 1.0 - 3.0 is effective. While you can set the overlap value on individual tiles & tile layers, for best results set it via the `SKTilemap.tileOverlap` property:

```swift
// this will override values for every tile
tilemap.tileOverlap = 1.0

// set the overlap for an entire layer
tileLayer.setTileOverlap(1.0)

// set the overlap on individual tiles
tile.setTileOverlap(1.0)
```


Next: [Coordinates](coordinates.html) - [Index](Tutorial.html)
