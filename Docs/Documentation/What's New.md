# What's New

- [Infinite Maps](#infinite-maps)
- [Bug Fixes](#bug-fixes)
- [API Changes](#api-changes)
	- [Tilemap Delegate](#tilemap-delegate)
    - [ID & Coordinate Types](#id-and-coordinate-types)
    	- [Tile Global IDs](#tile-global-ids)
 		- [Tile Coordinates](#tile-coordinates)
    - [Tile Flip Flags](#tile-flip-flags)
    - [Template Object Handling](#template-object-handling)
- [Swift 5 Support](#swift-5-support)
- [tvOS Support](#tvos-support)
- [Performance Increases](#performance-increases)
- [Effects Rendering](#effects-rendering)
- [Support for Tiled Templates](#support-for-tiled-templates)
- [General Improvements](#general-improvements)
- [GameplayKit](#gameplaykit)
- [New Object Types](#new-object-types)
    - [Tile Objects](#tile-objects)
    - [Text Objects](#text-objects)
- [Custom Classes](#custom-classes)


## Infinite Maps

SKTiled v1.3 supports inifinite maps. See the [**infinite maps**][infinite-maps-url] section for more information.

## Bug Fixes

A pesky, long-standing strong reference cycle memory leak is fixed, which will result in some code needing to be refactored in your projects if you use the `TiledSceneDelegate` protocol:

- `TiledSceneDelegate.tilemap` property is now optional
- `TiledSceneDelegate.cameraNode` property is now optional
- `SKTiledSceneCamera.world` property is now optional

As a result, references to `SKTilemap` & `SKTiledSceneCamera` nodes will need to be unwrapped:


```swift
// API version 1.2
if let tiledScene = (self.view as? SKView)?.scene as? TiledSceneDelegate {
    let renderSize = tiledScene.tilemap.sizeInPoints
    let world = tiledScene.cameraNode.world
}

// API version 1.3
if let tiledScene = (self.view as? SKView)?.scene as? TiledSceneDelegate {
    let renderSize = tiledScene.tilemap?.sizeInPoints
    let world = tiledScene.cameraNode?.world
}
```


## API Changes

There have been a number of important API changes, some of which will require refactoring in your projects. The new API is more efficient and features straightforward protocol design.

### Tilemap Delegate

The [`TilemapDelegate`][tilemapdelegate-url] (formerly `SKTilemapDelegate`) protocol is now an Objective-C protocol with **optional** methods. This was changed because of confusion when subclassing objects conforming protcols with default methods.

This might result in errors in Xcode:

![Delegate Error](images/xcode-delegate-error.svg)

To work around this, you'll need to indicate that the delegate method is optional by marking it with a `?`, and provide a default value:

```swift
// API version 1.2
if let delegate = tilemap.delegate {
    let GraphNode = delegate.objectForGraphType(named: "floor-tiles")
    let nodeAtCoordinate = GraphNode.init(gridPosition: simd_int2(coordinate.x - offset.x, coordinate.y))
}

// API version 1.3
if let delegate = tilemap.delegate {
    let GraphNode = delegate.objectForGraphType?(named: "floor-tiles") ?? GKGridGraphNode.self
    let nodeAtCoordinate = GraphNode.init(gridPosition: simd_int2(coordinate.x - offset.x, coordinate.y))
}
```

### ID & Coordinate Types

In an effort to standardize inconsistent & inefficient naming and value types throughout the API, several functions & properties have been renamed and/or have argument types changed. Tiled ID values values are represented now as **unsigned 32-bit integers** throughout the API, and tile coordinates are now represented by the `simd_int2` type.

In general, queries returning coordinates will now return vector `simd_int2` values, and queries returning scene (or screen) positions will return `CGPoint` values.

#### Tile Global IDs

ID values (tile global id, tile object id) are now represented as unsigned, 32-bit integers:

```swift
// API version 1.2
let gid: Int = 104
if let tileset = tilemap.getTileset(forTile: gid) {
	// do something with tileset
}

// API version 1.3
let gid: UInt32 = 104
if let tileset = tilemap.getTilesetFor(globalID: gid) {
	// do something with tileset
}
```

Passing a integer value will still work in most instances, but you will see a deprecation warning. In cases where the method signature is the same but the result type is different, declaring the type should quash errors & warnings in Xcode.


#### Tile Coordinates

The [`simd_int2`][simd-int2-url] type is now used everywhere 2D tile coordinates are referenced in the API. Previous versions of **SKTiled** used the [`int2`][int2-url] type, but that type has been deprecated in Swift 5.

```swift
// API version 1.2
let coord = int2(10, 15)
let pointInMap = tilemap.pointForCoordinate(vec2: coord)

// API version 1.3
let coord = simd_int2(10, 15)
let pointInMap = tilemap.pointForCoordinate(coord: coord)

```

Additionally, in several places the 1.2 API allowed for coordinate queries using `CGPoint` coordinates:

```swift
// API version 1.2
let pointCoord = CGPoint(x: 5, y: 12)
if let myTile = tilemap.tileAt(coord: pointCoord, inLayer: "Walls") {
	myTile.isHidden = true
}

// API version 1.3
let vec2Coord = simd_int2(5, 12)
if let myTile = tilemap.tileAt(coord: vec2Coord, inLayer: "Walls") {
	myTile.isHidden = true
}

// also valid
let pointCoord = CGPoint(x: 5, y: 12)
if let myTile = tilemap.tileAt(coord: pointCoord.toVec2, inLayer: "Walls") {
	myTile.isHidden = true
}
```

As before, using a `CGPoint` coordinate will still work, but you will receive a deprecation warning in Xcode. To help update your code, there are helper extensions included for converting between `CGPoint` and `simd_int2`:


```swift
// convert a `simd_int2` coordinate to a `CGPoint` point
let coord1 = simd_int2(1, 10)
let point1 = coord1.cgPoint

// convert a `CGPoint` point into a `simd_int2` coordinate
let point2 = CGPoint(x: 1, y: 10)
let coord2 = point2.toVec2
```


### Tile Flip Flags

In API 1.3, [**tile flip flags**][flip-flags-url] are now stored with the tile object itself. Previously, the flip flags were stored in the [`SKTilesetData`][sktiledsetdata-url] and could be overwritten by calling a previously created tile data instance during parsing, resulting in the occasional orientation error.

See the [**CHANGELOG**][sktiled-changelog-url] for a complete list of changes. If you find something breaking your code not mentioned here, please [open an issue on Github][sktiled-github-issues-url].


### Template Object Handling

Template object support in API 1.3 is considerably better. Prior versions of the API could occasionally clobber template object user overrides in Tiled, in v1.3 these issues have been fixed.


For more information, see the [**Migration Guide**][migration-guide-url].


## Swift 5 Support

![Swift 5][swift-5-img]

With v1.22, **SKTiled** now supports **Swift 5.3**.


## tvOS Support

![Apple TV][appletv-img]

As of v1.17, **SKTiled** supports tvOS. For more information, see the [**tvOS Programming Guide**][tvos-programming-url] for more information.


## Performance Increases

![Speed Boost][speed-boost-img]

Tile map rendering is faster and less taxing on your CPU. Tile maps now store a tile data cache for faster rendering. For more information, see the [**Tile Rendering Methods**][tile-rendering-methods-url] section.

## Effects Rendering

Both the `SKTilemap` & `TiledLayerObject` nodes are now subclassed from the [`SKEffectNode`][skeffectnode-url] node. Enabling the [`SKEffectNode.shouldEnableEffects`][skeffectnode-shouldenableeffects-url] flag will render the node's children into a private buffer. This allows for shader effects to be applied to individual layers or even the tilemap globally. Enabling the option on the `SKTilemap` node is a good way to eliminate [cracks][troubleshooting-tile-cracking-url] that sometimes appear between tiles.


## Support for Tiled Templates

Template objects are now supported and will be loaded automatically. For more information, see [**Using Templates**][templates-url] in the **Tiled** manual.


## General Improvements

- [tile update mode][tileupdatemode-url] flag allows you to customize how your tile maps are updated each frame
- [tile render mode][tilerendermode-url] flag allows you to customize how tiles are rendered
- the `TilesetDataSource` protocol allows you to easily modify tileset images as they're created
- better group layer support
    - child layer offsets render correctly
    - hierarchical layer search
- text object support
- tile object support
- better asynchronous map rendering
    - tilemap is now fully rendered when returned ([issue #3][sktiled-github-issues-3-url])
- better hexagonal coordinate conversion ([issue #9][sktiled-github-issues-9-url])
- better debugging visualizations
- support for custom user objects
    - users can implement custom tile, vector & [`GKGridGraphNode`][gkgridgraphnode-url] classes
- new protocol for interacting with the camera: `TiledSceneCameraDelegate`
- animated tiles are now updated via the `SKTilemap.update(_:)` method
    - changing the tilemap's `speed` attribute affects tile animation speed
    - tile animations can even play *backwards* if speed is < 0
- functions to help alleviate tile seams (or "cracking")
- tile object tile data can be accessed via `SKTileObject.tileData` ([issue #15][sktiled-github-issues-15-url])




## GameplayKit

**SKTiled** now has support for Apple's [**GameplayKit**][gameplaykit-url]. Navigation graphs can easily be built for tile layers based on tile attributes:

```swift
let walkable  = tileLayer.getTiles().filter { $0.tileData.walkable == true }
let obstacles = tileLayer.getTiles().filter { $0.tileData.obstacle == true }
let graph = tileLayer.initializeGraph(walkable: walkable, obstacles: obstacles, diagonalsAllowed: false)!
```

See the [**GameplayKit**](gameplaykit.html) section for more details.


## New Object Types

**SKTiled** now supports [**tile**][tile-objects-url] and [**text**][text-objects-url] text object types.

### Tile Objects

![Tile Objects][tile-objects-gif]

Tiled [**tile objects**][tile-objects-url] are now supported. Objects assigned a tile id will render the associated tile within the object bounds, including animated textures.


### Text Objects


![Text Objects][text-objects-gif]

Tiled [**text objects**][text-objects-url] are now supported. Objects assigned text properties will automatically render text within the shape's bounds. Changing the `SKTileObject.text` attribute (or any of the font attributes) will automatically redraw the object, allowing for easy creation of dynamic labels.


See the [**objects page**](objects.html#tile-objects) for more info.

## Custom Classes

The `TilemapDelegate` protocol has new methods for users to easily use their own classes for tile and vector objects, as well as custom [`GKGridGraphNode`][gkgridgraphnode-url] objects.


See the [**extending**][extending-url] section for more info.

Next: [Getting Started](getting-started.html) - [Index](Documentation.html)

<!--- Tiled --->

[tiled-doc-url]:http://doc.mapeditor.org
[group-layers-url]:http://doc.mapeditor.org/manual/layers/#group-layers
[tile-objects-url]:http://doc.mapeditor.org/manual/objects/#insert-tile
[text-objects-url]:http://doc.mapeditor.org/manual/objects/#insert-text
[templates-url]: https://doc.mapeditor.org/en/stable/manual/using-templates/
[flip-flags-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile-flipping


<!--- Documentation --->

[sktiled-doc-url]:https://mfessenden.github.io/SKTiled
[sktiled-changelog-url]:https://github.com/mfessenden/SKTiled/blob/master/CHANGELOG.md
[troubleshooting-tile-cracking-url]:troubleshooting.html#tile-cracking
[appletv-img]:images/appletv.svg
[speed-boost-img]:images/speed-boost.png
[swift-5-img]:images/swift5-logo.svg

[migration-guide-url]:migration-guide.html
[sktiled-github-issues-url]:https://github.com/mfessenden/SKTiled/issues
[sktiled-github-issues-3-url]:https://github.com/mfessenden/SKTiled/issues/3
[sktiled-github-issues-9-url]:https://github.com/mfessenden/SKTiled/issues/9
[sktiled-github-issues-15-url]:https://github.com/mfessenden/SKTiled/issues/15
[extending-url]:extending.html
[tile-objects-gif]:images/tile-objects.gif
[text-objects-gif]:images/text-objects.gif
[tilerendermode-url]:working-with-tiles.html#tile-render-mode
[tileupdatemode-url]:working-with-maps.html#rendering-tiles
[tile-rendering-methods-url]:working-with-maps.html#tile-rendering-methods
[infinite-maps-url]:working-with-maps.html#infinite-maps
[sktiledscenecamera-world-url]:Classes/SKTiledSceneCamera.html#world
[sktiledsetdata-url]:Classes/SKTilesetData.html
[tilemapdelegate-url]:Protocols/TilemapDelegate.html

<!--- Apple --->

[spritekit-url]:https://developer.apple.com/documentation/spritekit
[sknode-url]:https://developer.apple.com/documentation/spritekit/sknode
[skspritenode-url]:https://developer.apple.com/documentation/spritekit/skspritenode
[skscene-url]:https://developer.apple.com/documentation/spritekit/skscene
[gameplaykit-url]:https://developer.apple.com/documentation/gameplaykit
[gkgridgraph-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraph
[gkgridgraphnode-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraphnode
[skeffectnode-url]:https://developer.apple.com/documentation/spritekit/skeffectnode
[skeffectnode-shouldenableeffects-url]:https://developer.apple.com/documentation/spritekit/skeffectnode/1459385-shouldenableeffects
[tvos-programming-url]:https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/index.html
[simd-swift5-url]:https://developer.apple.com/documentation/xcode_release_notes/xcode_10_2_release_notes/swift_5_release_notes_for_xcode_10_2
[simd-int2-url]:https://developer.apple.com/documentation/simd/simd_int2
[int2-url]:https://developer.apple.com/documentation/simd/int2
