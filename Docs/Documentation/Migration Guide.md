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

| Old                                               | New                                            |
|:------------------------------------------------- |:---------------------------------------------- |
| `SKTilemap.size`                                  | `SKTilemap.mapSize`                            |
| `SKTilemap.getTileset(forTile:)`                  | `SKTilemap.getTilesetFor(globalID:)`           |
| `SKTilemap.coordinateAtMouseEvent(event:)`        | `SKTilemap.coordinateAtMouse(event:)`          |
| `TiledLayerObject.coordinateAtMouseEvent(event:)` | `TiledLayerObject.coordinateAtMouse(event:)`   |
| `SKTiledObject.setValue(forKey:)`                 | `TiledObjectType.setValue(for:)`               |
| `SKTiledObject.removeProperty(forKey:)`           | `TiledObjectType.removeProperty(for:)`         |
| `SKTileset.setDataTexture(_:imageNamed:)`         | `SKTileset.setDataTexture(tileID:imageNamed:)` |
| `SKTileset.setDataTexture(_:texture:)`            | `SKTileset.setDataTexture(tileID:texture:)`    |
| `SKTileset.addTilesetTile(_:texture:)`            | `SKTileset.addTilesetTile(tileID:texture:)`    |
| `SKTileset.addTilesetTile(_:source:)`             | `SKTileset.addTilesetTile(tileID:source:)`     |
| `SKTileObject.setObjectAttributes`                | `SKTileObject.overrideObjectAttributes`        |
| `TiledGlobals.debug`                              | `TiledGlobals.debugDisplayOptions`             |


## Type Changes

| Property        | Old Type |  New Type   |
|:--------------- |:--------:|:-----------:|
| Global ID       |  `Int`   |  `UInt32`   |
| Map Coordinates |  `int2`  | `simd_int2` |


## Tile Flip Flags

Prior to v1.3, tile flip flags were stored in the `SKTilesetData` structure which actually served no purpose because a masked tile global id would have its orientation parsed when the tile is initially created.


```swift
// A raw value of 2147483659 translates to 11, flipped horizontally.
let gid: UInt32 = 2147483659
var tileId = TileID(wrappedValue: 2147483659)
print(tileId)
// Tile ID: 11, flags: [ hFlip ]

// Alternately, we can set the flags directly:
tileId.flags = [.all]
print(tileId)
// Tile ID: 11, flags: [ hFlip, vFlip, dFlip ]
```




Next: [Scene Setup](scene-setup.html) - [Index](Documentation.html)


<!--- Tiled --->

[tiled-flip-flags-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile-flipping
