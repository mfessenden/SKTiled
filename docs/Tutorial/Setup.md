#Setup

###Important

If your Tiled files include image references that contain directories, you *must* include that directory in your Xcode project as a folder reference (not a group).

##World Setup

The world container node is set to 0,0 in the scene.

By default, the tilemap uses a default tile layer accessible via `SKTilemap.baseLayer`. The base layer is automatically created and can be used to add objects to or visualize the grid (the base layer's z-position is always higher than the other layers).

By default, when you query a point in the `SKTilemap` node, you are getting a location in the default base layer.