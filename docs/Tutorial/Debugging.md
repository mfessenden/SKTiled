#Debugging

There are several functions for troubleshooting your tiled scenes. The `SKTilemap` node has a `debugDraw` property that will quickly show the grid and any object layers:

```swift
tilemap.debugDraw = true
```



###Visualizing Objects

By default, object layers are hidden so that you may easily work with them in Tiled, but not see them in your game. To see them, you can either show *all* object layers, or on a layer by layer basis:


```swift
// show all objects in the scene
tilemap.showObjects = true


// show objects in each layer
for layer in tilemap.objectLayers {
    layer.showObjects = true
}
```

###Visualizing the Tile Grid

To visualize the current grid on any layer type, use the layer's `showGrid` property:


![Show Grid](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/showGrid.gif)


```swift
tileLayer.showGrid = true
```

To change the grid color, set layer's `gridColor` property.



###Highlighting Tiles

You can highlight a tile using the `SKTile.drawBounds` method. 

```swift

// highlight the tile for .25 seconds
tile.drawBounds(antialiasing: true, duration: 0.25)
```

The tile highlight color is stored in the `SKTile.highlightColor` property:

```swift
// set the tile highlight color for individual tiles
tile.highlightColor = SKColor.red


// set the highlight color for *all* tiles in the layer 
tileLayer.highlightColor = SKColor.blue
```

###Layer Boundary

All `TiledLayerObject` objects allow you to visualize the layer's boundary: 

```swift
tileLayer.drawBounds()
```


###Debugging Colors

    SKTilemap:

      highlightColor   -> overrides all layers highlighColor -> overrides SKTile highlight color

###Properties


Debugging properties for **SKTiled** classes:

    SKTilemap:
      highlightColor  (SKColor)   - global tile/object highlight color.
      showObjects     (Bool)      - visibility flag for all object layers.  
      
    TiledLayerObject:
      color           (SKColor)   - *not currently used
      highlightColor  (SKColor)   - layer highlight color (tile highlight color). 
      gridColor       (SKColor)   - grid color.
      frameColor      (SKColor)   - bounding box color.
      debugDraw       (Bool)      - show the layer boundary shape.
      showGrid        (Bool)      - show the layer grid.  
      showGraph       (Bool)      - show the pathfinding graph (if one exists).
    
    SKObjectGroup:
      showObjects     (Bool)      - visibility flag for all objects in the layer.
    
    SKTile:
      highlightColor  (SKColor)   - tile highlight color (used in the `SKTile.drawBounds` method).


Next: [Troubleshooting](troubleshooting.html) - [Index](Tutorial.html)
