Change Log
==========

1.16
-----

#### Changes

- add functions to alleviate tile seams, or "cracking"
- tile animations no longer driven by `SKAction`
    - changing `SKTilemap` speed will affect child layers
    - tile animations will respond to `SKTilemap` speed changes, and even run backwards
- add `SKTiledSceneCamera.setCameraBounds(bounds:)`
- add `SKTileset.getAnimatedTileData`
- add `SKTileset.renderTileData`
- add `SKTilesetData.frameAt(index:)`
- add `SKTilesetData.setTexture(_:forFrame:)`
- add `SKTilesetData.setDuration(interval:forFrame:)`
- add `SKTileObject.tileData` property
- add `SKTiledSceneCamera.clampZoomValue`
- add `SKTiledSceneCamera.zoomClamping` property
- remove `SKTile.pauseAnimation`


1.15
-----

#### Changes

- invert layer y-offsets properly
- add `DemoController` to manage scenes in iOS/macOS demo targets
- add `SKTilemap.getLayer(atPath:)`
- add `SKTilemapDelegate.didAddNavigationGraph(_:)`
- add `SKTilemap.newTileLayer(named:group:)`
- add `SKTilemap.newObjectGroup(named:group:)`
- add `SKTilemap.newImageLayer(named:group:)`
- add `SKTilemap.newGroupLayer(named:group:)`
- add `SKTilemap.getTileData(ofType:)`
- add `SKTileset.getTileData(ofType:)`
- add `SKTilemap.getVertices()`
- add `SKTilemap.heightOffset`
- add `SKTilemap.showObjects(forLayers:)`
- add `SKTilemap.gridGraphForLayers(_:walkable:obstacle:diagonalsAllowed:nodeClass)`
- add `SKTileLayer.gatherWalkable()`
- add `SKTileLayer.gatherObstacles()`
- add `SKTilemap.coordinateAtMouseEvent(event:)`
- add `SKTilemap.coordinateAtTouchLocation(_:)`
- add `SKTileCollisionShape`
- add `SKObjectGroup.newTileObject(data:)`
- add `SKObjectGroup.tileObject(withID:)`
- add `SKTile.frameColor`
- add `SKTileObject.frameColor`
- add `SKTilemap.getLayers(withPrefix:recursive:)`
- add `SKTilemap.tileLayers(withPrefix:recursive)`
- add `SKTilemap.objectGroups(withPrefix:recursive:)`
- add `SKTilemap.imageLayers(withPrefix:recursive:)`
- add `SKTilemap.groupLayers(withPrefix:recursive:)`
- rename `TiledLayerObject` -> `SKTiledLayerObject`
- rename `TiledLayerObject.boundingRect` -> `SKTiledLayerObject.bounds`
- rename `SKTiledSceneCamera.boundingRect` -> `SKTiledSceneCamera.bounds`
- rename `SKTilemap.addLayer(_:base:)` -> `SKTilemap.addLayer(_:group:clamped:)->(success:layer:)`
- remove `SKTileLayer.validTiles()`


1.14
-----

#### Changes

- hexagonal coordinate conversion updated to match Tiled's
- update API for new layer & object types, more consistent naming, etc.
- improved grid drawing quality
- debug functions moved to `SKTiled+Debug.swift`
- add `SKObjectGroup.textObjects`
- add `SKTilemap.textObjects`
- add `SKTilemap.showGrid`
- add `SKTilemap.showBounds`
- add `SKObjectGroup.getObjects(withText:)`
- add `SKTilemap.getContentLayers()`
- add `SKTilemap.objectColor`
- add `SKTilemap.mapName`
- add `SKTilemap.renderQuality`
- add `SKTilemap.getObjects(withText:)`
- add `SKTilemap.getObject(withID:)`
- add `SKTilemap.getTiles(recursive:)`
- add `SKTileObject.isTileObject`
- add `SKTileObject.isTextObject`
- add `SKTileLayer.showBounds`
- add `SKTile.showBounds`
- add `SKTileObject.showBounds`
- add `SKTile.highlightDuration`
- add `TiledLayerObject.highlightDuration`
- add `SKTiled+Debug.swift`
- add `SKTilemap.getContentLayers`
- add `SKTilemap.objectColor`
- add `SKTileObject.isPolyType`
- add `TiledLayerObject.layerName`
- add `SKTilemap.mapName`
- add `SKTilemap.renderQuality`
- add `TiledLayerObject.renderQuality`
- add `SKTileObject.renderQuality`
- add `SKTilemap.tilesAt(point:)`
- add `SKTilemap.objectsAt(point:)`
- add `alignment` to geometry types
- add `TiledLayerObject.renderableObjects`
- add `SKTilemap.renderableObjects`
- add `SKTilesetData.globalID`
- add `SKTileObject.showBounds`
- add `BackgroundLayer` layer type
- add `SKTilemapDelegate.zDeltaForLayers`
- add `SKTilemap.bounds`
- add `SKTilemap.url`
- add `SKTilemap.update(_:)`
- add `TiledLayerObject.update(_:)`
- add `SKTiledScene.graphs`
- remove `SKTilemap.indexOf(layerNamed:)`
- rename `SKTilemap.getLayer(named:)` -> `SKTilemap.getLayers(named:recursive:)`
- rename `SKTilemap.allLayers` -> `SKTilemap.getLayers(recursive:)`
- rename `SKTilemap.tileLayer(named:)` -> `SKTilemap.tileLayers(named:recursive:)`
- rename `SKTilemap.objectGroups(named:)` -> `SKTilemap.objectGroups(named:recursive:)`
- rename `SKTilemap.getLayers(ofType:)` -> `SKTilemap.getLayers(ofType:recursive:)`
- rename `SKTilemap.tileLayers` -> `SKTilemap.tileLayers(recursive:)`
- rename `SKTilemap.objectGroups` -> `SKTilemap.objectGroups(recursive:)`
- rename `SKTilemap.imageLayers` -> `SKTilemap.imageLayers(recursive:)`
- rename `SKTilemap.groupLayers` -> `SKTilemap.groupLayers(recursive:)`
- rename `SKTilemap.getTiles(ofType:)` -> `SKTilemap.getTiles(ofType:recursive:)`
- rename `SKTilemap.getTiles(withID:)` -> `SKTilemap.getTiles(globalID:recursive:)`
- rename `SKTilemap.getTilesWithProperty(_: _:)` -> `SKTilemap.getTilesWithProperty(_:_:recursive:)`
- rename `SKTilemap.getAnimatedTiles()` -> `SKTilemap.animatedTiles(recursive:)`
- rename `SKTilemap.getObjects()` -> `SKTilemap.getObjects(recursive:)`
- rename `SKTilemap.getObjects(ofType:)` -> `SKTilemap.getObjects(ofType:recursive:)`
- rename `SKTilemap.getObjects(named:)` -> `SKTilemap.getObjects(named:recursive:)`
- rename `SKTileLayer.getAnimatedTiles()` -> `SKTileLayer.animatedTiles()`
- rename `SKObjectGroup.getObject(named:)` -> `SKObjectGroup.getObjects(named:)`
- rename `SKTile.getVertices()` -> `SKTile.getVertices(offset:)`
- rename `TiledLayerGrid` -> `SKTiledDebugDrawNode`


1.13
-----

#### Changes

- support for tile objects
- background color for layers
- flag to ignore properties
- fix hexagonal tiles not having the correct z-position
- better `SKTiledSceneCamera` zooming
- `SKTiledDemoScene` draws debug shapes with coordinate as mouse moves (macOS)
- fix `SKTileLayer.getTiles(ofType:)`
- add `SKTiledObject.type` property
- add `SKObjectGroup.tileObjects` & `SKTilemap.tileObjects` methods
- add `SKTileset.load(fromFiles:)` method for pre-loading tilesets
- removed `SKTilemap.positionInMap` method


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
