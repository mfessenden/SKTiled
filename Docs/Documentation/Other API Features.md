# Other API Features

- [TiledGlobals](#tiledglobals)

There are more API features not discussed here.


## TiledGlobals

The `[TiledGlobals]`[tiledglobals-url] structure holds the default values used by the **SKTiled** API.


```swift
// set the debug frame color
TiledGlobals.default.debug.frameColor = SKColor(hexString: "#FA6400")

// get the framework version
let version = TiledGlobals.default.version

// set the debug callbacks for mouse events
TiledGlobals.default.debug.mouseFilters = [.tileCoordinates, .tileDataUnderCursor, .tilesUnderCursor]
```



Next: [Debugging](debugging.html) - [Index](Documentation.html#other-api-features)



[tiledglobals-url]:Classes/TiledGlobals.html
