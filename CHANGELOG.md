Change Log
==========

1.14
-----

#### Changes

API Updates:
- add `SKObjectGroup.textObjects` & `SKTilemap.textObjects`
- remove `SKTilemap.indexOf(layerNamed:)`
- rename `SKTilemap.getLayer(named:)` -> `SKTilemap.getLayers(named:,recursive:)`
- rename `SKTilemap.allLayers` -> `SKTilemap.getLayers(recursive:)`
- rename `SKTilemap.tileLayer(named:)` -> `SKTilemap.tileLayers(named:,recursive:)`
- rename `SKTilemap.objectGroups(named:)` -> `SKTilemap.objectGroups(named:,recursive:)`
- rename `SKTilemap.getLayers(ofType:)` -> `SKTilemap.getLayers(ofType:,recursive:)`
- rename `SKTilemap.tileLayers` -> `SKTilemap.tileLayers(recursive:)`
- rename `SKTilemap.objectGroups` -> `SKTilemap.objectGroups(recursive:)`
- rename `SKTilemap.imageLayers` -> `SKTilemap.imageLayers(recursive:)`
- rename `SKTilemap.groupLayers` -> `SKTilemap.groupLayers(recursive:)`
- rename `SKTilemap.getTiles(ofType:)` -> `SKTilemap.getTiles(ofType:,recursive:)`
- rename `SKTilemap.getTiles(withID:)` -> `SKTilemap.getTiles(withID:,recursive:)`
- rename `SKTilemap.getTilesWithProperty(_:, _:)` -> `SKTilemap.getTilesWithProperty(_:,_:,recursive:)`
- rename `SKTilemap.getAnimatedTiles()` -> `SKTilemap.animatedTiles(recursive:)`
- rename `SKTilemap.getObjects()` -> `SKTilemap.getObjects(recursive:)`
- rename `SKTilemap.getObjects(ofType:)` -> `SKTilemap.getObjects(ofType:,recursive:)`
- rename `SKTilemap.getObjects(named:)` -> `SKTilemap.getObjects(named:,recursive:)`
- rename `SKTileLayer.getAnimatedTiles()` -> `SKTileLayer.animatedTiles()`


- rename `SKObjectGroup.getObject(named:)` -> `SKObjectGroup.getObjects(named:)`
- add `SKTilemap.showGrid`
- add `SKTilemap.showBounds`
- add `SKObjectGroup.getObjects(withText:)`
- add `SKTilemap.getObjects(withText:)`
- add `SKTilemap.getObject(withID:)`
- add `SKTileObject.isTileObject`
- add `SKTileObject.isTextObject`
- add `SKTileLayer.showBounds`
- add `SKTile.showBounds`
- add `SKTile.highlightDuration`
- add `TiledLayerObject.highlightDuration`


- better grid drawing quality
- add `SKTiled+Debug.swift`
- add `SKTilemap.getContentLayers` function
- add `SKTilemap.objectColor` property
- add `TiledLayerObject.layerName` property
- add `SKTilemap.renderQuality` property
- add `TiledLayerObject.renderQuality` property


1.13
-----

#### Changes

- better `SKTiledSceneCamera` zooming
- `SKTiledDemoScene` draws debug shapes with coordinate as mouse moves (macOS)
- support for tile objects
- background color for layers
- flag to ignore properties
- SKTilemap.backgroundColor
- add `SKTiledObject.type` property
- fixed `SKTileLayer.getTiles(ofType:)`
- add `SKObjectGroup.tileObjects` & `SKTilemap.tileObjects` methods
- add `SKTileset.load(fromFiles:)` method for pre-loading tilesets
- removed `SKTilemap.positionInMap` method
- fix for hexagonal tiles not having the correct z-position

1.12
-----

#### Changes
- add `SKGroupLayer` layer type (new Tiled feature)
- `SKTilemap.allLayers` method now returns a flattened array of layers
- add `SKTilemap.getLayers(layerType:)` method
- add `SKTilemap.groupLayers` property


1.10
-----

#### Changes
- add `SKTilemap.renderQueue` (was previously a property of the parser)
- `SKTilemap.renderQueue` syncs before pausing
- add `SKTilemap.cropAtBoundary` property
- add `SKTilemap.renderSize` property
- `SKTilemap` now a subclass of `SKCropNode`
- `TiledLayerObject.coordinateForPoint` method inverts y-value before converting
- update references to `M_PI` -> `Double.pi`

1.07
-----

#### Changes
- add `SKTilemapDelegate` methods callbacks:
    - `didBeginParsing`, `didAddTileset`, `didAddLayer`, `didReadMap`
    - add default implementations via extension
- tweaks to GCD rendering
- now `SKTiledScene` conforms to `SKTilemapDelegate` & `SKTiledSceneDelegate` protocols
- documentation update
- add `SKTileset.setDataTexture` method to replace tileset data texture
- add `SKColor.hexString` function
- add `SKTilemap` background color sprite
- change access control of some functions & extensions
- update Xcode project for Carthage support
- update documentation with CocoaPods instructions

1.06
-----

#### Changes
- add SKTilemapDelegate protocol

1.05
-----

#### Changes
- add dynamics properties to layers and objects
- `SKTilemap.baseLayer` is ignored when querying layers
- add Data extension to check for compressed data
- fix coordinate error with negative tile coordinates

1.04
-----

#### Changes
- fixed a bug where object properties were added to the parent object group
- `SKTileLayer.addTileAt` now  tries to resolves `gid` argument
- add support for `SKTileObject` physics:
    - add `SKTiledObject.hasProperties` property
    - add `SKTileObject.physicsType` property
    - add `SKTiledSceneCamera.overlay` property
- add `SKTileObject` texture rendering
- add `flippedTileFlags` function
- add `SKTileset.getTileRealID` method
- `SKTiledScene` automatically resizes maps with the `SKTilemap.autoResize` is set
- add `SKTileLayer.addTileAt(coord:texture)`
- add `SKTilemap.pointForCoordinate` and `SKTilemap.coordinateForPoint` methods
- updated README

1.03
----

#### Changes
- add gzip & zlib decompression
- add callbacks to SKTilemap, SKTiledParser
- add completion handler to tile layer render
- add completion handler to parseProperties
- add override to `SKTilemap.isPaused`
- add `SKTilemap.tileCount` property
- add `SKTilemap.color` property
- add gesture recognizers for iOS (pinched, double-tapped)
- add pause effect to dim layers
- add `GameWindowController` for macOS demo
