# Debugging

- [Debug Draw Options](#debug-draw-options)
- [Visualizing Objects](#visualizing-objects)
- [Highlighting Tiles](#highlighting-tiles)
- [Map Statistics](#map-statistics)


![Debug Options](images/debugDrawOptions.gif)

## Debug Draw Options

Visualizing Tiled content is done via the `DebugDrawOptions` optionset. The options are available on the tile map node and layer nodes.

```swift
// draw the map's bounding shape
tilemap.debugDrawOptions = .drawBounds

// show object boundaries
tilemap.debugDrawOptions = .drawObjectBounds

// draw the grid & bounding shape
tilemap.debugDrawOptions = [.drawGrid, .drawBounds]

// show object bounds for an object layer
objectgroup.debugDrawOptions = .drawObjectBounds

// show tile shapes for a tile layer
tileLayer.debugDrawOptions = .drawTileBounds
```

To customize the grid color, set layer's `SKTiledLayerObject.gridColor` property.


## Visualizing Objects

Tiled vector objects can be globally shown/hidden so that you may easily work with them in **Tiled**, but not see them in your game. To see them, you can set the `showObjects` property on the tilemap node, or individual object layers.


```swift
// show all objects in the scene
tilemap.showObjects = true


// show objects in each object layer
for layer in tilemap.objectLayers {
    layer.showObjects = true
}

// show objects for `one` object layer
collisionsLayer.showObjects = true

```

Note that layer visibility supersedes object visibility; layers hidden in **Tiled** will not show objects unless the layer is unhidden first.



## Highlighting Tiles

You can highlight a tile using the `SKTile.showBounds` property:

```swift
// highlight the tile for .25 seconds
tile.highlightDuration = 0.25
tile.showBounds = true
```

The tile highlight color is stored in the `SKTile.highlightColor` property:

```swift
// set the tile highlight color for individual tiles
tile.highlightColor = SKColor.red


// set the highlight color for *all* tiles in the layer
tileLayer.highlightColor = SKColor.blue
```

## Map Statistics

To see a quick overview of the current tilemap's layers, use the `SKTilemap.mapStatistics(default:)` method:

![Map Statistics](images/mapStatistics.png)

The output represents a visualization of the scene hierarchy; nested layers are indented under their parent. Layer index and position are shown for top-level layers only.

    1.  Layer index (top-level layers)
    2.  Layer type (tile, object, group, image)
    3.  Layer visibility ("x" indicates layer is visible)
    4.  Layer hierarchy  ("▿" indicates layer has children)
    5.  Layer size
    6.  Layer offset
    7.  Layer anchor point
    8.  Layer z-position
    9.  Layer opacity
    10. Navigation graph node count


Next: [Troubleshooting](troubleshooting.html) - [Index](Table of Contents.html)
