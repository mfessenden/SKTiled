# What's New
- [Swift 5 Support](#swift5-support)
- [tvOS Support](#tvos-support)
- [Performance Increases](#performance-increases)
- [Effects Rendering](#effects-rendering)
- [Support for Tiled Templates](#support-for-tiled-templates)
- [General Improvements](#general-improvements)
- [OS Compatibility](#os-compatibility)
- [API Changes](#api-changes)
- [GameplayKit](#gameplaykit)
- [New Object Types](#new-object-types)
    - [Tile Objects](#tile-objects)
    - [Text Objects](#text-objects)
- [Custom Classes](#custom-classes)



## Swift 5 Support

![Swift 5][swift-5-img]

With v1.23, **SKTiled** now supports **Swift 5.3**.

## tvOS Support

![Apple TV][appletv-img]

As of v1.17, **SKTiled** supports tvOS. For more information, see the [**tvOS Programming Guide**][tvos-programming-url].


## Performance Increases

![Speed Boost][speed-boost-img]

Tile map rendering is faster and less taxing on your CPU. Tile maps now store a tile data cache for faster rendering. For more information, see the [**Tile Rendering Methods**][tile-rendering-methods-url] section.

## Effects Rendering

Both the `SKTilemap` & `SKTiledLayerObject` nodes are now subclassed from the [`SKEffectNode`][skeffectnode-url] node. Enabling the [`SKEffectNode.shouldEnableEffects`][skeffectnode-shouldenableeffects-url] flag will render the node's children into a private buffer. This allows for shader effects to be applied to individual layers or even the tilemap globally. Enabling the option on the `SKTilemap` node is a good way to eliminate [cracks][troubleshooting-tile-cracking-url] that sometimes appear between tiles.


## Support for Tiled Templates

Template objects are now supported and will be loaded automatically. For more information, see [**Using Templates**][templates-url] in the **Tiled** manual.


## General Improvements
- [tile update mode][tileupdatemode-url] flag allows you to customize how your tile maps are updated each frame
- [tile render mode][tilerendermode-url] flag allows you to customize how tiles are rendered
- the `SKTilesetDataSource` protocol allows you to easily modify tileset images as they're created
- better group layer support
    - child layer offsets render correctly
    - hierarchical layer search
- text object support
- tile object support
- better asynchronous map rendering
    - tilemap is now fully rendered when returned ([issue #3][issue3-url])
- better hexagonal coordinate conversion ([issue #9][issue9-url])
- better debugging visualizations
- support for custom user objects
    - users can implement custom tile, vector & [`GKGridGraphNode`][gkgridgraphnode-url] classes
- new protocol for interacting with the camera: `SKTiledSceneCameraDelegate`
- animated tiles are now updated via the `SKTilemap.update(_:)` method
    - changing the tilemap's `speed` attribute affects tile animation speed
    - tile animations can even play *backwards* if speed is < 0
- functions to help alleviate tile seams (or "cracking")
- tile object tile data can be accessed via `SKTileObject.tileData` ([issue #15][issue15-url])


## OS Compatibility

macOS target now requires 10.12, iOS target requires 12.


## API Changes

The API has gotten a significant overhaul, mainly to support [group layers][group-layers-url] in **Tiled 1.0**.

As layers & groups can share names and index values, `SKTilemap` and `SKTiledLayerObject` methods that search based on name or index will now return an array:

```swift
// old way
if let groundLayer = tilemap.getLayer(named: "Ground") as? SKTileLayer {
    groundLayer.offset.x = 4.0
}

// new way
if let groundLayer = tilemap.getLayers(named: "Ground").first as? SKTileLayer {
    groundLayer.offset.x = 4.0
}
```

New methods take an optional `recursive` argument that will search the entire layer tree. When `false`, only top-level layers will be returned:

![Group Layers](images/group-recursive.png)

```swift
// query top-level layers
let topLevelLayers = tilemap.getLayers(recursive: false)
print(topLevelLayers.map { $0.layerName })
// ["Skyway", "Buildings", "Terrain"]

// query all layers
let allLayers = tilemap.getLayers(recursive: true)
print(allLayers.map { $0.layerName })
// ["Skyway", "Paths", "Trees", "Buildings", "Roof", "Walls", "Foundation", "Terrain", "Ground", "Water"]
```


See the [**CHANGELOG**][sktiled-changelog-url] for a complete list of changes.



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

The `SKTilemapDelegate` protocol has new methods for users to easily use their own classes for tile and vector objects, as well as custom [`GKGridGraphNode`][gkgridgraphnode-url] objects.


See the [**extending**][extending-url] section for more info.

Next: [Getting Started](getting-started.html) - [Index](Table of Contents.html)

<!--- Tiled --->

[tiled-doc-url]:http://doc.mapeditor.org
[group-layers-url]:http://doc.mapeditor.org/manual/layers/#group-layers
[tile-objects-url]:http://doc.mapeditor.org/manual/objects/#insert-tile
[text-objects-url]:http://doc.mapeditor.org/manual/objects/#insert-text
[templates-url]: https://doc.mapeditor.org/en/stable/manual/using-templates/

<!--- Documentation --->

[sktiled-doc-url]:https://mfessenden.github.io/SKTiled
[sktiled-changelog-url]:https://github.com/mfessenden/SKTiled/blob/master/CHANGELOG.md
[troubleshooting-tile-cracking-url]:troubleshooting.html#tile-cracking
[appletv-img]:images/appletv.png
[speed-boost-img]:images/speed-boost.png
[swift-5-img]:images/swift5-logo.svg

[issue3-url]:https://github.com/mfessenden/SKTiled/issues/3
[issue9-url]:https://github.com/mfessenden/SKTiled/issues/9
[issue15-url]:https://github.com/mfessenden/SKTiled/issues/15
[extending-url]:extending.html
[tile-objects-gif]:images/tile-objects.gif
[text-objects-gif]:images/text-objects.gif
[tilerendermode-url]:working-with-tiles.html#tile-render-mode
[tileupdatemode-url]:working-with-maps.html#rendering-tiles
[tile-rendering-methods-url]:working-with-maps.html#tile-rendering-methods

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
