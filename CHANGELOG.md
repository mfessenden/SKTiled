Change Log
==========================
1.0.7
--------------------------

#### Changes
- add `SKTilemapDelegate` methods callbacks:
    - `didBeginParsing`, `didAddTileset`, `didAddLayer`, `didReadMap`
    - add default implementations via extension
- tweaks to GCD parsing & rendering
- now `SKTiledScene` conforms to `SKTilemapDelegate` & `SKTiledSceneDelegate` protocols
- documentation update
- add `SKTileset.setDataTexture` method to replace tilset data texture

1.0.6
--------------------------

#### Changes
- add SKTilemapDelegate protocol

1.0.5
--------------------------

#### Changes
- add dynamics properties to layers and objects
- `SKTilemap.baseLayer` is ignored when querying layers
- add Data extension to check for compressed data
- fix coordinate error with negative tile coordinates

1.0.4
--------------------------

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

1.0.3
--------------------------

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
