Change Log
==========

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
