//
//  SKTilemapParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// XML Parser error types.
internal enum ParsingError: Error {
    case attribute(attr: String)
    case attributeValue(attr: String, value: String)
    case key(key: String)
    case index(idx: Int)
    case compression(value: String)
    case error
}


// File types recognized by the parser
internal enum FileType: String {
    case tmx
    case tsx
    case png
}


// Document compression type.
internal enum CompressionType: String {
    case uncompressed
    case zlib
    case gzip
}


/**
 The `SKTilemapParser` is a custom [`XMLParserDelegate`](https://developer.apple.com/reference/foundation/xmlparserdelegate) parser for reading Tiled TMX and tileset TSX files.
 To read a tile map, used the `SKTilemapParser.load` method:
 
 ```swift
 if let tilemap = SKTilemapParser().load(fromFile: "sample-file") {
    scene.worldNode.addChild(tilemap)
 }
 ```
 */
open class SKTilemapParser: NSObject, XMLParserDelegate {
    
    open var fileNames: [String] = []                               // list of resource files
    open var currentFileName: String!
    weak var mapDelegate: SKTilemapDelegate?
    open var tilemap: SKTilemap!
    
    fileprivate var encoding: TilemapEncoding = .xml                // encoding
    fileprivate var tilesets: [String: SKTileset] = [:]             // stash external tilesets
    
    // stash current elements
    fileprivate var activeElement: String?                          // current object
    fileprivate var lastElement: AnyObject?                         // last object created
    fileprivate var currentID: Int?                                 // current tile/object ID
    
    fileprivate var properties: [String: String] = [:]              // last properties created
    fileprivate var data: [String: [UInt32]] = [:]                  // store data for tile layers to render in a second pass
    fileprivate var tileData: [UInt32] = []                         // last tile data read
    fileprivate var characterData: String = ""                      // current tile data (string)
    
    fileprivate var compression: CompressionType = .uncompressed    // compression type
    fileprivate var timer: Date = Date()                            // timer
    fileprivate var finishedParsing: Bool = false
    
    // dispatch queues & groups
    internal let parsingQueue = DispatchQueue(label: "com.sktiled.parsequeue", qos: .userInitiated, attributes: .concurrent)  // serial queue
    internal let parsingGroup = DispatchGroup()
    
    // MARK: - Loading
    
    /**
     Return the appropriate filename string for the given file (TMX or TSX) since Tiled stores
     xml files with multiple extensions.
     
     - parameter fileName: `String` file name to search for.
     - returns: `String?` name of file in bundle.
     */
    fileprivate func getBundledFile(named filename: String, extensions: [String] = ["tmx", "tsx"]) -> String? {
        // strip off the file extension
        let fileBaseName = filename.components(separatedBy: ".")[0]
        for fileExtension in extensions {
            if let url = Bundle.main.url(forResource: fileBaseName, withExtension: fileExtension) {
                let filepath = url.absoluteString
                if let filename = filepath.components(separatedBy: "/").last {
                    return filename
                }
            }
        }
        return nil
    }
    
    /**
     Load a TMX file and parse it.
     
     - parameter filename:     `String` Tiled file name (does not need TMX extension).
     - parameter delegate:     `SKTilemapDelegate?` optional tilemap delegate instance.
     - parameter withTilesets: `[SKTileset]?` use existing tilesets to create the tile map.
     - returns: `SKTilemap?` tiled map node.
     */
    open func load(fromFile filename: String,
                   delegate: SKTilemapDelegate? = nil,
                   withTilesets: [SKTileset]? = nil) -> SKTilemap? {
        
        guard let targetFile = getBundledFile(named: filename) else {
            print("[SKTilemapParser]: unable to locate file: \"\(filename)\"")
            return nil
        }
        
        // set the delegate property
        mapDelegate = delegate
        timer = Date()
        fileNames.append(targetFile)
        
        // add existing tilesets
        if let withTilesets = withTilesets {
            for tileset in withTilesets {
                tilesets[tileset.name] = tileset
            }
        }
        
        while !(fileNames.isEmpty) {
            if let firstFileName = fileNames.first {
                
                currentFileName = firstFileName
                defer { fileNames.remove(at: 0) }
                
                guard let path: String = Bundle.main.path(forResource: currentFileName! , ofType: nil) else {
                    print("[SKTilemapParser]: no path for: \"\(currentFileName!)\"")
                    return nil
                }
                
                let data: Data = try! Data(contentsOf: URL(fileURLWithPath: path))
                let parser: XMLParser = XMLParser(data: data)

                parser.shouldResolveExternalEntities = false
                parser.delegate = self
                
                // check file type
                let fileExt = currentFileName.components(separatedBy: ".").last!
                var filetype = "filename"
                if let ftype = FileType(rawValue: fileExt) {
                    filetype = ftype.description
                }
                
                print("[SKTilemapParser]: reading \(filetype): \"\(currentFileName!)\"")
                
                // parse the file
                let successs: Bool = parser.parse()
                // report errors
                if (successs == false) {
                    let parseError = parser.parserError
                    let errorLine = parser.lineNumber
                    let errorCol = parser.columnNumber
                    
                    let errorDescription = parseError!.localizedDescription
                    print("[SKTilemapParser]: \(errorDescription) at line:\(errorLine), column: \(errorCol)")
                }
            }
        }
    
        guard let currentMap = self.tilemap else { return nil }
        
        // reset tileset data
        tilesets = [:]
        
        // pre-processing callback
        DispatchQueue.main.async(group: self.parsingGroup) {
            if self.mapDelegate != nil { self.mapDelegate!.didReadMap(currentMap) }
        }
        
        // start rendering layers when queue is complete.
        self.parsingGroup.notify(queue: DispatchQueue.main) {
            self.didBeginRendering(currentMap)
        }

        return currentMap
    }

    
    // MARK: - Post-Processing
    
    /**
     Post-process to render each layer.
     
     - parameter tilemap:  `SKTilemap`    tile map node.
     - parameter duration: `TimeInterval` fade-in time for each layer.
     */
    fileprivate func didBeginRendering(_ tilemap: SKTilemap, duration: TimeInterval=0.025)  {
        // assign each layer a work item
        for layer in tilemap.allLayers() {
            let renderItem = DispatchWorkItem() {
                // render object groups
                if let objectGroup = layer as? SKObjectGroup {
                    objectGroup.drawObjects()
                }
                
                // render image layers
                if let _ = layer as? SKImageLayer {}
                
                // render tile layers
                if let tileLayer = layer as? SKTileLayer {
                    if let tileData = self.data[tileLayer.uuid] {
                        // add the layer data
                        let _ = tileLayer.setLayerData(tileData)
                    }
                
                    // report errors
                    if tileLayer.gidErrors.count > 0 {
                        let gidErrorString : String = tileLayer.gidErrors.reduce("", { "\($0)" == "" ? "\($1)" : "\($0)" + ", " + "\($1)" })
                        print("[SKTilemapParser]: WARNING: layer \"\(tileLayer.name!)\": the following gids could not be found: \(gidErrorString)")
                    }
                }
            }
        
            tilemap.renderQueue.async(group: tilemap.renderGroup, execute: renderItem)
        }

        
        // run callbacks when the group is finished
        tilemap.renderGroup.notify(queue: DispatchQueue.main) {
            self.data = [:]
            self.tilesets = [:]
            self.tilemap.didFinishRendering(timeStarted: self.timer)
            
            for layer in self.tilemap.allLayers() {
                layer.didFinishRendering(duration: duration)
            }
        }
    }
    
    // MARK: - XMLParserDelegate
    public func parser(_ parser: XMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String: String])  {
        
        activeElement = elementName
        
        let isCompoundElement = (attributeDict.count > 0)
        var elementStartString = "<\(elementName)"
        if (isCompoundElement == true) {
            for (attr, val) in attributeDict {
                elementStartString += " \(attr)=\"\(val)\""
            }
        }
        

        if (elementName == "map") {
            guard let tilemap = SKTilemap(attributes: attributeDict) else {
                parser.abortParsing()
                return
            }
            
            self.tilemap = tilemap
            self.tilemap.delegate = self.mapDelegate
            
            let currentBasename = currentFileName.components(separatedBy: ".").first!
            self.tilemap.filename = currentBasename
            self.tilemap.name = currentBasename
            
            // run setup functions on tilemap
            self.mapDelegate?.didBeginParsing(tilemap)
            lastElement = tilemap
        }
        
        // external will have a 'source' attribute, otherwise 'image'
        if (elementName == "tileset") {
            
            // external tileset
            if let source = attributeDict["source"] {
                    
                // check to see if tileset already exists
                if let existingTileset = tilesets[source] {
                    
                    if self.tilemap != nil {
                        self.tilemap.addTileset(existingTileset)
                    }
                    lastElement = existingTileset

                    // set this to nil, just in case we're looking for a collections tileset.
                    currentID = nil
                    
                } else {
                    // source is a file reference
                    if !(fileNames.contains(source)) {
                        fileNames.append(source)
                        
                        guard let firstGID = attributeDict["firstgid"] else { parser.abortParsing(); return }
                        let firstGIDInt = Int(firstGID)!
                        
                        let tileset = SKTileset(source: source, firstgid: firstGIDInt, tilemap: self.tilemap)

                        // add tileset to external file list
                        tilesets[source] = tileset
                        
                        // add the tileset to the tilemap
                        self.tilemap?.addTileset(tileset)
                        lastElement = tileset
                        
                        // delegate callback
                        if mapDelegate != nil { mapDelegate!.didAddTileset(tileset) }
                        // set this to nil, just in case we're looking for a collections tileset.
                        currentID = nil
                    }
                }
            }
            
            // inline tileset
            if let name = attributeDict["name"] {
                
                // update an existing tileset
                if let existingTileset = tilesets[currentFileName] {
                    
                    guard let width = attributeDict["tilewidth"] else { parser.abortParsing(); return }
                    guard let height = attributeDict["tileheight"] else { parser.abortParsing(); return }
                    guard let columns = attributeDict["columns"] else { parser.abortParsing(); return }

                    existingTileset.name = name
                    existingTileset.tileSize = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
                    existingTileset.columns = Int(columns)!
                    
                    // optionals
                    if let spacing = attributeDict["spacing"] {
                        existingTileset.spacing = Int(spacing)!
                    }
                    
                    if let margin = attributeDict["margin"] {
                        existingTileset.margin = Int(margin)!
                    }
                    
                    lastElement = existingTileset
                    
                } else {
                    // create inline tileset
                    guard let tileset = SKTileset(attributes: attributeDict) else { parser.abortParsing(); return }
                    
                    // add the tileset to the tilemap
                    if let tilemap = self.tilemap {
                        tilemap.addTileset(tileset)
                    }
                    
                    lastElement = tileset

                    // delegate callback
                    if mapDelegate != nil { mapDelegate!.didAddTileset(tileset) }

                    // set this to nil, just in case we're looking for a collections tileset.
                    currentID = nil
                }
            }
        }
        
        // draw offset for tilesets
        if elementName == "tileoffset" {
            guard let offsetx = attributeDict["x"] else { parser.abortParsing(); return }
            guard let offsety = attributeDict["y"] else { parser.abortParsing(); return }
            
            if let tileset = lastElement as? SKTileset {
                tileset.tileOffset = CGPoint(x: Int(offsetx)!, y: Int(offsety)!)
            }
        }        
        
        if elementName == "property" {
            guard let name = attributeDict["name"] else { parser.abortParsing(); return }
            guard let value = attributeDict["value"] else { parser.abortParsing(); return }
            //guard let propertyType = attributeDict["type"] else { parser.abortParsing(); return }
            
            // stash properties
            properties[name] = value            
        }
        
        
        // 'layer' indicates a Tile layer
        if (elementName == "layer") {
            guard let layerName = attributeDict["name"] else { parser.abortParsing(); return }
            guard let layer = SKTileLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                print("Error creating tile layer: \"\(layerName)\"")
                parser.abortParsing()
                return
            }
            
            if let group = lastElement as? SKGroupLayer {
                group.addLayer(layer)
            } else {
                self.tilemap?.addLayer(layer)
            }
            
            // delegate callback
            if mapDelegate != nil { mapDelegate!.didAddLayer(layer) }
            
            lastElement = layer
        }
        
        // 'objectgroup' indicates an Object layer
        if (elementName == "objectgroup") {
            
            // TODO: need exception for tile collision objects
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let objectsGroup = SKObjectGroup(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            if let group = lastElement as? SKGroupLayer {
                group.addLayer(objectsGroup)
            } else {
                self.tilemap?.addLayer(objectsGroup)
            }

            // delegate callback
            if mapDelegate != nil { mapDelegate!.didAddLayer(objectsGroup) }
            
            lastElement = objectsGroup
        }
        
        // 'imagelayer' indicates an Image layer
        if (elementName == "imagelayer") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let imageLayer = SKImageLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            if let group = lastElement as? SKGroupLayer {
                group.addLayer(imageLayer)
            } else {
                self.tilemap?.addLayer(imageLayer)
            }
            
            // delegate callback
            if mapDelegate != nil { mapDelegate!.didAddLayer(imageLayer) }
            
            lastElement = imageLayer
        }
        
        // 'group' indicates a Group layer
        if (elementName == "group") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let groupLayer = SKGroupLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            if let group = lastElement as? SKGroupLayer {
                group.addLayer(groupLayer)
            } else {
                self.tilemap?.addLayer(groupLayer)
            }
            
            
            // delegate callback
            if mapDelegate != nil { mapDelegate!.didAddLayer(groupLayer) }
            
            lastElement = groupLayer
        }
        
        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            guard attributeDict["width"] != nil else { parser.abortParsing(); return }
            guard attributeDict["height"] != nil else { parser.abortParsing(); return }
            guard let imageSource = attributeDict["source"] else { parser.abortParsing(); return }
            
            // update an image layer
            if let imageLayer = lastElement as? SKImageLayer {
                // set the image property
                imageLayer.setLayerImage(imageSource)
            }
            
            // update a tileset
            if let tileset = lastElement as? SKTileset {
                // If `currentID` == nil, look for lastElement to be a tileset, otherwise, the image is part of a collections tileset.
                if let currentID = currentID {
                    // add an image property to the tileset collection
                    let tileData = tileset.addTilesetTile(currentID + tileset.firstGID, source: imageSource)
                    if (tileData == nil) {
                        print("[SKTilemapParser]: Warning: tile id \(currentID) is invalid.")
                    }
                } else {
                    // add the tileset spritesheet image
                    tileset.addTextures(fromSpriteSheet: imageSource)
                }
            }
        }
        
        // `tile` is used to flag properties in a tileset, as well as store tile layer data in an XML-formatted map.
        if elementName == "tile" {

            // XML data is stored with a `tile` tag and `gid` atribute.
            if let gid = attributeDict["gid"] {
                let gidInt = Int(gid)!
                // just append this to the tileData property
                if (encoding == .xml) {
                    tileData.append(UInt32(gidInt))
                }
            }
                
            // we're adding data to a tileset
            else if let id = attributeDict["id"] {
                let idInt = Int(id)!
                currentID = idInt
            } else {
                parser.abortParsing()
                return
            }
        }

        // look for last element to be an object group
        // id, x, y required
        if (elementName == "object") {
            guard let tileObject = SKTileObject(attributes: attributeDict) else {
                print("[SKTilemapParser]: Error creating object.")
                parser.abortParsing()
                return
            }
            
            guard let objectGroup = lastElement as? SKObjectGroup else {
                parser.abortParsing()
                return
            }
                
            let _ = objectGroup.addObject(tileObject)
            currentID = tileObject.id
        }
        
        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            if let objectsgroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectsgroup.getObject(withID: currentID!) {
                        currentObject.objectType = .ellipse
                    }
                }
            }
        }
        
        if (elementName == "polygon") {
            // polygon object
            if let pointsString = attributeDict["points"] {
                var coordinates: [[CGFloat]] = []
                let points = pointsString.components(separatedBy: " ")
                for point in points {
                    let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
                    coordinates.append(coords.flatMap { CGFloat($0) })
                }
                
                if let objectsgroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectsgroup.getObject(withID: currentID!) {
                            currentObject.addPoints(coordinates)
                            //currentObject.drawObject()
                        }
                    }
                }
            }
        }
        
        if (elementName == "polyline") {
            // polygon object
            if let pointsString = attributeDict["points"] {
                var coordinates: [[CGFloat]] = []
                let points = pointsString.components(separatedBy: " ")
                for point in points {
                    let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
                    coordinates.append(coords.flatMap { CGFloat($0) })
                }
                
                if let objectsgroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectsgroup.getObject(withID: currentID!) {
                            currentObject.addPoints(coordinates, closed: false)
                            //currentObject.drawObject()
                        }
                    }
                }
            }
        }
        
        // animated tiles
        if (elementName == "frame") {
            guard let currentID = currentID else {
                print("[SKTilemapParser]: cannot assign frame animation information without tile id")
                parser.abortParsing()
                return}
            
            guard let id = attributeDict["tileid"] else { parser.abortParsing(); return }
            guard let duration = attributeDict["duration"] else { parser.abortParsing(); return }
            guard let tileset = lastElement as? SKTileset else { parser.abortParsing(); return }
            
            // get duration in seconds
            let durationInSeconds: TimeInterval = Double(duration)! / 1000.0
            if let currentTileData = tileset.getTileData(currentID + tileset.firstGID) {
                // add the frame id to the frames property
                currentTileData.addFrame(withID: Int(id)! + tileset.firstGID, interval: durationInSeconds)
            }
        }

        // decode data here, and reset
        if (elementName == "data") {
            // get the encoding...
            if let encoding = attributeDict["encoding"] {
                self.encoding = TilemapEncoding(rawValue: encoding)!
            }
            
            // compression algorithms
            if let ctype = attributeDict["compression"] {
                //throw ParsingError.Compression(value: compression)
                guard let compression = CompressionType(rawValue: ctype) else {
                    fatalError("compression type: \(ctype) not supported.")
                }
                self.compression = compression
            }
        }
    }
    
    
    // didEndElement happens when parser ends a key: </key>
    public func parser(_ parser: XMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        
        // look for last element to add properties to
        if elementName == "properties" {
                        
            /* TILEMAP */
            if let tilemap = lastElement as? SKTilemap {
                for (key, value) in properties {
                    tilemap.properties[key] = value
                }
                tilemap.parseProperties(completion: nil)
            }
            
            if let layer = lastElement as? TiledLayerObject {
                if (currentID == nil){
                    for (key, value) in properties {
                        layer.properties[key] = value
                    }
                }
                
                //tileLayer.parseProperties(completion: nil)   // moved to render
            }
            
            if let tileset = lastElement as? SKTileset {
                if (currentID == nil){
                    tileset.properties = properties
                    tileset.parseProperties(completion: nil)
                } else {
                    
                    let tileID = tileset.firstGID + currentID!
                    if let tileData = tileset.getTileData(tileID) {
                        for (key, value) in properties {
                            tileData.properties[key] = value
                        }
                        tileData.parseProperties(completion: nil)
                        properties = [:]
                    }
                }
            }

            // clear if no last ID
            if currentID == nil {
                properties = [:]
            }
        }
        
        // look for last element to be a layer
        if (elementName == "data") {
            guard let tileLayer = lastElement as? SKTileLayer else {
                print("[SKTilemapParser]: cannot find layer to add data.")
                parser.abortParsing()
                return
            }
            
            var foundData = false
            
            if (encoding == .base64) {
                foundData = true
                if let dataArray = decode(base64String: characterData, compression: self.compression) {
                    for id in dataArray {
                        tileData.append(id)
                    }
                }
            }
            
            if (encoding == .csv) {
                foundData = true
                let dataArray = decode(csvString: characterData)
                for id in dataArray {
                    tileData.append(id)
                }
            }
            
            if (encoding == .xml) {
                foundData = true
            }
            
            // write data to buffer
            if (foundData == true) {
                data[tileLayer.uuid] = tileData
                
            } else {
                parser.abortParsing()
                return
            }
            
            // reset csv data
            tileData = []
        }
        
        if (elementName == "tile") {
            // parse properties
            if let tileset = lastElement as? SKTileset {
                if (currentID != nil){
                    let tileID = tileset.firstGID + currentID!
                    if let currentTileData = tileset.getTileData(tileID) {
                        for (key, value) in properties {
                            currentTileData.properties[key] = value
                        }
                        properties = [:]
                    }
                }
            }
            
            // we're no longer adding attributes to a tile, so unset the currentID
            currentID = nil
        }
        
        // look for last element to be an object group
        if (elementName == "object") {
            if let objectsgroup = lastElement as? SKObjectGroup {                
                if (currentID != nil) {
                    if let lastObject = objectsgroup.getObject(withID: currentID!) {
                        //lastObject.properties = properties
                        for (key, value) in properties {
                            lastObject.properties[key] = value
                        }
                        
                        
                        lastObject.parseProperties(completion: nil)
                        properties = [:]
                    }
                }
            }
            
            currentID = nil
        }

        // reset character data
        characterData = ""
    }
 
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        // append data attribute
        characterData += string
    }
    
    // MARK: - Decoding
    /**
     Scrub CSV data.
     
     - parameter data: `String` data to decode
     - returns: `[UInt32]` parsed CSV data.
     */
    fileprivate func decode(csvString data: String) -> [UInt32] {
        return data.scrub().components(separatedBy: ",").map {UInt32($0)!}
    }
    
    /**
     Decode Base64-formatted data.
     
     Data is saved in tiled:
        - data array is compressed (zlib, gzip)
        - compressed data is encoded in base64
        - data is saved

     - parameter data:        `String` Base64 formatted data to decode
     - parameter compression: `CompressionType` compression type.
     - returns: `[UInt32]?` parsed data.
     */
    fileprivate func decode(base64String data: String, compression: CompressionType = .uncompressed) -> [UInt32]? {
        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            print("Error: data is not base64 encoded.")
            return nil
        }
        
        switch compression {
        case .zlib, .gzip:
            if let decompressed = try? decodedData.gunzipped() {
                return decompressed.toArray(type: UInt32.self)
            }

        default:
            return decodedData.toArray(type: UInt32.self)
        }
        
        return nil
    }
}



extension FileType {
    var description: String {
        switch self {
        case .tmx:
            return "tile map"
        case .tsx:
            return "tileset"
        case .png:
            return "image"
        }
    }
}
