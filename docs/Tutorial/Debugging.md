#Debugging

There are several functions for troubleshooting your tile map nodes.

Debugging properties for SKTiled classes:

    SKTilemap:
      highlightColor  (SKColor)   - global highlight color.
      
    TiledLayerObject:
      highlightColor  (SKColor)   - layer highlight color. 
      debugDraw       (Bool)      - show the layer boundary shape.
      showGrid        (Bool)      - show the layer grid.  
      showGraph       (Bool)      - show the pathfinding graph (if one exists).
     
    SKTile:
      highlightColor  (SKColor)   - tile highlight color (used in the `SKTile.drawBounds` method).

###Visualizing the Tile Grid


###Highlighting Tiles

You can highlight a tile using the `SKTile.drawBounds` method. 

```swift
tile.drawBounds(antialias: false, duration: 0.25)
```

###Colors

    SKTilemap:

      highlightColor   -> overrides all layers highlighColor -> overrides SKTile highlight color
      
Next: [Getting Started](getting-started.html) - [Index](Tutorial.html)
