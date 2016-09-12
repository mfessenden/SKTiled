## Custom Properties

All objects that conform to the `TiledObject` protocol have custom methods for parsing tiled object properties.


    SKTilemap:
      name            (String)    - map name.
      hidden          (Bool)      - hide the map.
      worldScale      (Float)     - world starting scale.
      gridColor       (String)    - hex string used for visualizing the tile grid.    (debug)
      frameColor      (String)    - hex string used for visualizing the bounding box. (debug)
      highlightColor  (String)    - hex string used for highlighting tiles.           (debug)
      zPosition       (Float)     - starting zPosition.
      allowMovement   (Bool)      - scene camera movement enabled.
      allowZoom       (Bool)      - scene camera zoom enabled.
      showObjects     (Bool)      - globally show/hide objects in all object groups. 

    SKTileset:
      None

    TiledLayerObject:
      hidden          (Bool)      - hide the object.
      color           (String)    - hex string to override color.
      zPosition       (Float)     - used to manually override layer zPosition.
      gridColor       (String)    - hex string used for visualizing the tile grid.

    SKObjectGroup:
      lineWidth       (Float)     - object line width.
      showNames       (Bool)      - display object names.
      showObjects     (Bool)      - globally show/hide objects. 

    SKTilesetData:
      collisionSize   (Float)     - used to add collision to the tile.
      collisionShape  (Int)       - 0 = rectangle, 1 = circle.

    SKTileObject:
      hidden          (Bool)      - hide the object.
      color           (String)    - hex string to override object color.
      lineWidth       (Float)     - object line width.   


###SKTilemap Colors
    
    // setting one of these in the tiled file will apply it to ALL layers
    gridColor: grid visualization color
    frameColor: bounding box color
    highlightColor: layer highlight color
    
    
###TiledLayerObject Colors

    color:  object group color
    gridColor: grid visualization color
    frameColor: bounding box color
    highlightColor: layer highlight color