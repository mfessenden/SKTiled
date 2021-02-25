# Migration Guide

- [Renamed Objects](#renamed-objects)
    - [Symbols](#symbols)
    - [Properties & Methods](#properties-&-Methods)
- [Type Changes](#type-changes)
- [Tile Flip Flags](#tile-iflip-flags)

Moving from the **v1.2** API should be fairly straightforward. Here are the highlights of what's changed:

## Renamed Objects

### Symbols

| Old                          | New                        |
|:---------------------------- |:-------------------------- |
| `SKTiledObject`              | `TiledObjectType`          |
| `SKTiledSceneDelegate`       | `TiledSceneDelegate`       |
| `SKTiledSceneCameraDelegate` | `TiledSceneCameraDelegate` |
| `SKTilemapDelegate`          | `TilemapDelegate`          |


### Properties & Methods

| Old                                               | New                                                  |
|:------------------------------------------------- |:---------------------------------------------------- |
| `SKTilemap.size`                                  | `SKTilemap.mapSize`                                  |
| `SKTilemap.getTileset(forTile:)`                  | `SKTilemap.getTilesetFor(globalID:)`                 |
| `SKTilemap.coordinateAtMouseEvent(event:)`        | `SKTilemap.coordinateAtMouse(event:)`                |
| `TiledLayerObject.coordinateAtMouseEvent(event:)` | `TiledLayerObject.coordinateAtMouse(event:)`         |
| `SKTiledObject.setValue(forKey:)`                 | `TiledObjectType.setValue(for:)`                     |
| `SKTiledObject.removeProperty(forKey:)`           | `TiledObjectType.removeProperty(for:)`               |
| `SKTileset.setDataTexture(_:imageNamed:)`         | `SKTileset.setDataTexture(tileID:imageNamed:)`       |
| `SKTileset.setDataTexture(_:texture:)`            | `SKTileset.setDataTexture(tileID:texture:)`          |
| `SKTileset.addTilesetTile(_:texture:)`            | `SKTileset.addTilesetTile(tileID:texture:)`          |
| `SKTileset.addTilesetTile(_:source:)`             | `SKTileset.addTilesetTile(tileID:source:)`           |
| `SKTileObject.setObjectAttributes`                | `SKTileObject.overrideObjectAttributes(attributes:)` |
| `TiledGlobals.debug`                              | `TiledGlobals.debugDisplayOptions`                   |


## Type Changes

| Property        | Old Type |  New Type   |
|:--------------- |:--------:|:-----------:|
| Global ID       |  `Int`   |  `UInt32`   |
| Map Coordinates |  `int2`  | `simd_int2` |




## Tile Flip Flags

Prior to **v1.3**, tile flip flags were stored in the `SKTilesetData` structure which actually served no purpose because a masked tile global id would have its orientation parsed when the tile is initially created.

Now, all `SKTile` nodes have a [`globalId`][tileid-url] property that handles id translation. The `TileID` struct wraps the global id & orientation functions and translates values accordingly:


```swift
// This tile has a global id value of '285' and no flip flags
print(tile.globalId, tile.flipFlags)
// 285 [  ]

// A masked(raw) value of 2684354845 translates to 285, flipped horizontally & diagonally
tile.globalId = 2684354845

// The unmasked, "real" global id is unchanged, only the orientation flags have changed:
print(tile.globalId, tile.flipFlags)
// 285 [ hFlip, dFlip ]

// get the masked value:
print(tile.maskedTileId)
// 2684354845
```

Alternately, you can orient the tile by setting the `SKTile.isFlippedHorizontally`, `SKTile.isFlippedVertically` and `SKTile.isFlippedDiagonally` attributes:

```swift
// Reset the flip flags by assigning an empty value
tile.flipFlags = []
print(tile.flipFlags)
// []

// Set the tile flip flags manually
tile.isFlippedHorizontally = true
tile.isFlippedDiagonally = true
print(tile.globalId, tile.flipFlags)
// 285 [ hFlip, dFlip ]

// get the masked value:
print(tile.maskedTileId)
// 2684354845
```

The **v1.3** API  now includes the following attributes for dealing with tile orientation & global id.

| Property                       | Description                       | Notes    |
| ------------------------------ | --------------------------------- | -------- |
| `SKTile.globalId`              | the tile global id value          |          |
| `SKTile.maskedTileId`          | masked tile global id value       | get-only |
| `SKTile.flipFlags`             | current tile transformation flags |          |
| `SKTile.isFlippedHorizontally` | tile is flipped horizontally      |          |
| `SKTile.isFlippedVertically`   | tile is flipped vertically        |          |
| `SKTile.isFlippedDiagonally`   | tile is flipped diagonally        |          |



See the [**Tile Flipping**][tiled-flip-flags-url] section of the [**Tiled documentation**][tiled-docs-url] for more details.

Next: [Scene Setup](scene-setup.html) - [Index](Documentation.html)

<!--- SKTiled --->
[tileid-url]:Structs/TileID.html

<!--- Tiled --->
[tiled-docs-url]:https://doc.mapeditor.org
[tiled-flip-flags-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile-flipping
