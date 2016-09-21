#Working with Tiles

**SKTiled** provides several ways to access tiles in a tile map.

##Getting Tiles at a Location

Accessing tiles is simple, simply query a tile layer or the tile map node for tiles at a given coordinate:

```swift
let tiles = tilemap.tilesAt(10, 8)
```

###Getting Tiles with Tile ID

```swift
let tiles = tilemap.getTiles(withID: 10)
```

###Getting Tiles of Type

```swift
let fireTiles = tilemap.getTiles(ofType: "Fire")
```

###Getting Tiles with Property

Returning tiles with a particular property:

```swift
let fireTiles = tilemap.getTilesWithProperty("type", "Fire")
```

##Adding Tiles

To add a tile

```swift
if let tile = tileLayer.addTile(at: 5, 8) {
    // do something with tile
    tile.
}
```

##Removing Tiles

To remove a tile, simply call one of the `SKTileLayer.removeTileAt` methods:

```swift
if let removedTile = tileLayer.removeTileAt(10, 8) {
    // do something with tile
}
```

##Tile Animations

Tiles animated in Tiled are have custom SpriteKit actions applied to animate the tile texture. Animated tiles are accessed with the `SKTileLayer.getAnimatedTiles` method, or globally via the `SKTilemap.getAnimatedTiles` method:

```swift
// return animated tiles in a single layer
let animatedTiles = tileLayer.getAnimatedTiles()

// return all animated tiles
let allAnimatedTiles = tilemap.getAnimatedTiles()
```

Tile objects allow you to pause & remove animations:


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

To add animation to a tile, add GID values to the `SKTilesetData` instance associated with each tile:

```swift
// add frame GIDs
tile.tileData.addFrame(33, interval: 0.25)
tile.tileData.addFrame(34, interval: 0.35)
tile.tileData.addFrame(35, interval: 0.15)

// run the animation
tile.runAnimation()
```

##Tile Overlap

The tile overlap value is used to help alleviate the "cracks" that sometimes appear when the tilemap or worldNode is scaled. The value is clamped with the `SKTile.maxOverlap` value. Usually a value between 1.0 - 3.0 is effective. While you can set the overlap value on individual tiles & tile layers, for best results set it via the `SKTilemap.tileOverlap` property:

```swift
// this will override values for every tile
tilemap.tileOverlap = 1.0

// set the overlap for an entire layer
tileLayer.setTileOverlap(1.0)

// set the overlap on individual tiles
tile.setTileOverlap(1.0)
```