Change Log
==========


1.30
-----

#### Changes

- add support for infinite maps
- more consistent API naming and value types:
	- `UInt32` type is used consistently for global tile ids.
- tile flip flags are now stored on the individual tiles, not tile data containers
- better managing of object/template attributes
- better handling of image types
- `SKTiledSceneCamera` works properly with any `SKScene` instance conforming to `TiledSceneCameraDelegate` protocol

- Bug Fixes:
    - fix a memory leak where tilemap is retained after parent scene change
    - fix tile object texture sizing bug when animating with SpriteKit actions
    - fix a bug where animated tiles added via `SKTileLayer.addTileAt` are not the correct size
    - fix a bug where objects created in `SKTilemap.load` completion handler do not render correctly
    - fix tile object sprite positioning with tileset offset
    - fix a bug where `SKTilemap.getTileData(ofType:)` didn't return the correct tile data
    - fix a bug where updating the flip flags of a tile object updated the tile anchor point incorrectly
	- fix a bug where mouse scroll wheel events could override the `SKTiledSceneCamera.allowZoom` flag

- API Changes:
	- rename protocol `SKTiledObject` -> `TiledObjectType`
	- rename protocol `SKTiledSceneDelegate` -> `TiledSceneDelegate`
	- rename protocol `SKTiledSceneCameraDelegate` -> `TiledSceneCameraDelegate`
	- rename protocol `SKTilemapDelegate` -> `TilemapDelegate`
		- `TilemapDelegate` protocol is now an `@objc` protocol
		- `TilemapDelegate` properties & methods are now optional

    - `TiledLayerObject.tilemap` property is now `unowned`
    - `TiledLayerObject.graph` property is now optional
    - `SKTiledSceneCamera.world` property is now optional
	- `TiledSceneDelegate.tilemap` property is now optional
    - `TiledSceneDelegate.cameraNode` property is now optional
	- `SKTileObject.tile` property is now public
	- `LoggingLevel` enum type is now `UInt8`
    - `SKTilemap.showObjects(forLayers:)` is deprecated
    - `SKTileObject.getVertices()` now returns an empty set if there are no points

	- rename `SKTilemap.getTileset(forTile:)` -> `SKTilemap.getTilesetFor(globalID:)`
	- rename `SKTilemap.coordinateAtMouseEvent(event:)` -> `SKTilemap.coordinateAtMouse(event:)`
	- rename `TiledLayerObject.coordinateAtMouseEvent(event:)` -> `TiledLayerObject.coordinateAtMouse(event:)`
    - rename `TiledObjectType.setValue(forKey:)` -> `TiledObjectType.setValue(for:)`
    - rename `TiledObjectType.removeProperty(forKey:)` -> `TiledObjectType.removeValue(for:)`
	- rename `SKTileset.setDataTexture(_:imageNamed:)` -> `SKTileset.setDataTexture(tileID:imageNamed:)`
	- rename `SKTileset.setDataTexture(_:texture:)` -> `SKTileset.setDataTexture(tileID:texture:)`
	- rename `SKTileset.addTilesetTile(_:texture:)` -> `SKTileset.addTilesetTile(tileID:texture:)`
	- rename `SKTileset.addTilesetTile(_:source:)` -> `SKTileset.addTilesetTile(tileID:source:)`
    - rename `SKTileObject.setObjectAttributes` -> `SKTileObject.overrideObjectAttributes`
	- rename `TiledGlobals.debug` -> `TiledGlobals.debugDisplayOptions`
	- rename `TiledGlobals.enableRenderCallbacks` -> `TiledGlobals.enableRenderPerformanceCallbacks`
	- rename `TiledLayerObject.path` -> `TiledLayerObject.xPath` property

	- remove the `layerName` requirement for `TiledLayerObject` required init
    - remove tile flip flags from `SKTilesetData` objects
	- remove `TiledGlobals.DebugDisplayOptions.MouseFilters.tilesUnderCursor`
	- remove `TiledGlobals.DebugDisplayOptions.MouseFilters.objectsUnderCursor`
	- remove `SKTileLayer.setLayerData(data:debug)`
	- rename `SKTilemap.isShowingGraphs` -> `SKTilemap.isShowingGridGraph`
	- remove `TiledLayerObject.points` property
	- remove `SKTileObject.showBounds` property
	- remove `SKTilemap.nodesInView` property

    - add `SKTileLayerChunk` class
    - add `TileContainerType` protocol

	- add `TiledObjectType.tiledDescription` property
	- add `TiledObjectType.getValue(for:defaultValue:)` protocol method
    - add `TiledObjectType.setProperties(_:overwrite:)` protocol method
	- add `TiledObjectType.colorForKey(_:)` method

	- add `TilemapDelegate.mouseOverTileHandler` method.
	- add `TilemapDelegate.mouseOverObjectHandler` method.
	- add `TilemapDelegate.mouseClickHandler` method.

	- add `TiledGlobals.zDeltaForLayers` property
	- add `TiledGlobals.trackProcessorUsage` property
	- add `TiledGlobals.enableCameraContainedNodesCallbacks` property

	- add `SKTilemap.getTilesWithPropery(named:recursive:)` method
	- add `SKTileLayer.getTilesWithPropery(named:)` method

	- add `SKTile.globalId` property
	- add `SKTile.spriteCopy` method
	- add `SKTile.replaceWithSpriteCopy()` method
	- add `SKTile.withTileDataClone()` method
	- add `SKTile.tileset` property
	- add `SKTile.tilemap` property
	- add `SKTile.newTile(globalID:in:)` class function
	- add `SKTile.newTile(localID:in:)` class function
	- add `SKTile.mouseOverHandler` handler

	- add `SKTileObject.rotation` property

	- add `SKTiledSceneCamera.allowNegativeZoom`
	- add `SKTiledSceneCamera.sceneRotated` property
	- add `SKTiledSceneCamera.allowRotation` property
	- add `SKTiledSceneCamera.rotationDamping` property
	- add `SKTiledSceneCamera.centerOn(node:)` method

	- add `TiledLayerObject.tintColor` property
	- add `TiledLayerObject.load` method (EXPERIMENTAL)
	- add `TiledLayerObject.mapDelegate` property
	- add `TiledLayerObject.addChunk(_:at:)` method
	- add `TiledLayerObject.parentLayers` property

    - add `SKTileLayer.isInfinite` property
    - add `SKTileLayer.chunkAt(coord:)` method
    - add `SKTileLayer.chunkAt(_:_:)` method

    - add `SKTilemap.absoluteSize` property
	- add `SKTilemap.backgroundOpacity` property
	- add `SKTilemap.backgroundOffset` property
    - add `SKTilemap.chunksAt(coord:)` method
    - add `SKTilemap.chunksAt(_:_:)` method
	- add `SKTilemap.contains(globalID:)` method
	- add `SKTilemap.allTiles(globalID:)` method
	- add `SKTilemap.newTile(globalID:type:)` method

    - add `SKTileset.load(tsxFile:)` class function
	- add `SKTileset.newTile(globalID:)` method
	- add `SKTileset.newTile(localID:)` method

	- add `SKTilesetData.clone()` method



#### Breaking

- the `TiledSceneDelegate.tilemap` property will need to be checked for nil values
- the `TiledSceneDelegate.cameraNode` property will need to be checked for nil values
- the `TiledSceneCamera.world` property will need to be checked for nil values
- the `TileObject.getVertices()` method can no longer return nil
- tile & object id values will need to be converted to `UInt32`
- calls to `LoggingLevel.init(rawValue:)` will need to pass a `UInt8`

---

1.22
-----

#### Changes

- Swift version is now 5.3
- fix a bug where an `SKColor` instantiated with an `#RRGGBBAA` hex string has incorrect alpha value
- fix a crash [#28](https://github.com/mfessenden/SKTiled/issues/28) when a collections tileset image can't be found
- add `SKTileset.localRange` property
- add `SKTileset.globalRange` property
- add `SKTileset.contains(localID:)` method
- `SKTilesetData.localID` is deprecated

#### Breaking

- nothing



1.21
-----

#### Changes

- remove Tiled assets from macOS framework target
- fix delegate errors in parser tests
- `TileUpdateMode` access level is now public
- add `SKTile.enableAnimation` flag
- add `SKTileObject.enableAnimation` flag
- add color test

#### Breaking

- nothing

---

1.20
-----

#### Changes

- optimized tile data storage for faster updates
- support for Tiled templates
- add tvOS demo & framework targets
- Xcode version is 10
- Swift version is now 4.2
- Requirements updated:
    - macOS: 10.12
    - iOS: 11.0
    - tvOS: 12.0
- fix spritesheet height bug if excess space existed at image bottom
- fix tile clamping bug that shifts position slightly over time
- fix a bug where querying tiles with a global id returned an improper result
- fix a bug where tile object's tile type wasn't looking for delegate type
- fix a bug where `SKTiledObject` objects improperly parse double arrays
- add `TileRenderMode` flag
- add `TileUpdateMode` flag
- `SKTilemap` & `SKTiledLayerObject` nodes are now subclassed from `SKEffectNode`
    - add `SKTilemap.setShader` method
    - add `TiledLayerObject.setShader` method    
- add `SKTiledGeometry` protocol
- add `SKTilemap.getTileset(forTile:)` method
- add `SKTilemap.tileObjects(globalID:)` method
- add `SKTilemap.isValid(coord:)` method
- add `SKTilesetDataSource` delegate
- add `SKTiledSceneCamera.ignoreZoomClamping` flag
- add `SKTiledSceneCamera.ignoreZoomConstraints` flag
- add `SKTiledSceneCamera.notifyDelegatesOnContainedNodesChange` flag
- add `SKTiledSceneCameraDelegate.containedNodesChanged` protocol method
- add `SKTileLayer.tileAt(point:offset:)` method
- add `SKTile.renderFlags` property
- add `SKTileset.delegate` property
- add `SKTileset.setDataTexture(_:imageNamed)`
-  `SKTileset.setDataTexture` now returns the previous texture
- add `SKTilesetData.animationAction` property
- add `SKTilesetData.name` property
- rename `AnimationFrame` -> `TileAnimationFrame`
- add `SKTiledSceneCamera.allowGestures` attribute
- add `SKTiledSceneCamera.setupGestures(for:)` method
- `SKTiledScene.setup` completion handler passes tilemap as argument
- add `SKTilemap.vectorCoordinateForPoint` method.
- add `TiledLayerObject.vectorCoordinateForPoint` method.
- `SKTiledObject.boolForKey` ,  `SKTiledObject.intForKey` & `SKTiledObject.doubleForKey` are now public methods.
-  removed `SKTiledSceneCameraDelegate` default methods; protocol methods are now optional
- rename `SKTiledObject.objectType`  ->  `SKTiledObject.shapeType`
- rename `SKObjectGroup.drawObjects`  ->  `SKObjectGroup.draw`

#### Breaking

- nothing

---

1.16
-----

#### Changes

- add functions to alleviate tile seams, or "cracking"
- tile animations no longer driven by `SKAction`
    - changing `SKTilemap` speed will affect child layers
    - tile animations will respond to `SKTilemap` speed changes, and even run backwards
- add `SKTiledSceneCamera.setCameraBounds(bounds:)`
- add `SKTileset.getAnimatedTileData`
- add `SKTileset.setupAnimatedTileData`
- add `SKTileset.getGlobalID(id:)`
- add `SKTilesetData.frameAt(index:)`
- add `SKTilesetData.setTexture(_:forFrame:)`
- add `SKTilesetData.setDuration(interval:forFrame:)`
- add `SKTileObject.tileData` property
- add `SKTiledSceneCamera.clampZoomValue`
- add `SKTiledSceneCamera.zoomClamping` property
- remove `SKTile.pauseAnimation`


#### Breaking

- animated tiles will no longer render independently; `SKTilemap` node must be added to the `SKScene.update` loop

---


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

---

1.14
-----

#### Changes

- hexagonal coordinate conversion updated to match Tiled's
- update API for new layer & object types, more consistent naming, etc.
- improved grid drawing quality
- debug functions moved to `SKTiled+Debug.swift`
- add `SKObjectGroup.textObjects`
- add `SKTilemap.textObjects`
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

---

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

---


1.12
-----

#### Changes
- add `SKGroupLayer` layer type (new Tiled feature)
- `SKTilemap.allLayers` method now returns a flattened array of layers
- add `SKTilemap.getLayers(layerType:)` method
- add `SKTilemap.groupLayers` property


---


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
