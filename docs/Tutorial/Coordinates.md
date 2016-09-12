
###Coordinates

SpriteKit uses a coordinate system that is different from Tiled's; in SpriteKit, a SpriteKit node's origin is on the bottom-left, while Tiled's origin is top-left. To emulate this, the `SKTilemap` object draws its layers starting at the origin and moving downwards into the negative y-space. To account for this, use the `TiledLayerObject.convertPoint` method to return a point in the layer's coordinate space. Each layer has the ability to independently query a coordinate ( which can be different depending on the layer's offset).



By default, the tilemap uses a default tile layer accessible via `SKTilemap.baseLayer`.  