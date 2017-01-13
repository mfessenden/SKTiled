#Custom Properties

One of the most powerful features of **SKTiled** is the ability to exploit Tiled's custom properties for most objects. 
All objects that conform to the [`SKTiledObject`](Protocols/SKTiledObject.html) protocol have methods for parsing Tiled object properties. Tiled property values are all encoded as strings. **SKTiled** will attempt to parse the intended type, but be sure to check the type of property you are querying.

If you are using the v0.17 of Tiled or newer, **SKTiled** supports the new **color** and **file** property types (values are stored as strings internally anyway, which *SKTiled* already supports). The custom color/file types listed above will also be parsed if they are created as string types in Tiled.


    SKTilemap:
      name                (String)    - map name.
      hidden              (Bool)      - hide the map.
      worldScale          (Float)     - world starting scale.
      debug               (Bool)      - debug mode.                                       (debug)      
      gridColor           (Color)     - hex string used for visualizing the tile grid.    (debug)
      gridOpacity         (Float)     - grid overlay opactity.                            (debug)    
      frameColor          (Color)     - hex string used for visualizing the bounding box. (debug)
      highlightColor      (Color)     - hex string used for highlighting tiles.           (debug)
      zPosition           (Float)     - initial zPosition.
      allowMovement       (Bool)      - scene camera movement enabled.
      allowZoom           (Bool)      - scene camera zoom enabled.
      showObjects         (Bool)      - globally show/hide objects in all object groups.
      tileOverlap         (Float)     - tile overlap amount.
      maxZoom             (Float)     - maximum camera zoom.
      minZoom             (Float)     - minimum camera zoom.
      ignoreBackground    (Bool)      - ignore Tiled background color.
      antialiasLines      (Bool)      - antialias lines.
      autoResize          (Bool)      - automatically resize the map to best fit the view.
      xGravity            (Float)     - gravity in x.
      yGravity            (Float)     - gravity in y.
      cropAtBoundary      (Bool)      - crop the map at boundaries.**

    TiledLayerObject:
      antialiasing        (Bool)      - antialias lines.
      hidden              (Bool)      - hide the layer.
      color               (String)    - hex string to override color.
      gridColor           (Color)     - hex string used for visualizing the tile grid.
      backgroundColor     (Color)     - hex string used for visualizing the tile grid.
      zPosition           (Float)     - used to manually override layer zPosition.
      isDynamic           (Bool)      - creates a collision object from the layer's border. 

    SKObjectGroup:
      lineWidth           (Float)     - object line width.
      showNames           (Bool)      - display object names.
      showObjects         (Bool)      - globally show/hide objects.
      isDynamic           (Bool)      - automatically create objects as dynamic bodies

    SKImageLayer:
      frame               (File)      - image layer animation frame.
      duration            (Float)     - frame duration.

    SKTilesetData:
      collisionSize       (Float)     - used to add collision to the tile.
      collisionShape      (Int)       - 0 = rectangle, 1 = circle.
      nodeClass           (String)    - tile node class.**

    SKTileObject:
      hidden              (Bool)      - hide the object.
      color               (String)    - hex string to override object color.
      lineWidth           (Float)     - object line width.
      nodeClass           (String)    - object node class**
      isDynamic           (Bool)      - object is dynamic.
      isCollider          (Bool)      - object is passive collision object.
      mass                (Float)     - physics mass.
      friction            (Float)     - physics friction.
      restitution         (Float)     - physics 'bounciness'.
      linearDamping       (Float)     - physics linear damping.
      angularDamping      (Float)     - physics angular damping.

    ** not yet implemented


<!--- Next: [GameplayKit](gameplaykit.html) - [Index](Tutorial.html) --->

 Next: [Debugging](debugging.html) - [Index](Tutorial.html)
