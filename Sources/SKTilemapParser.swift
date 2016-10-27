//
//  SKTilemapParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// XML Parser error types.
internal enum ParsingError: Error {
    case attribute(attr: String)
    case attributeValue(attr: String, value: String)
    case key(key: String)
    case index(idx: Int)
    case compression(value: String)
    case error
}


/// File types recognized by the parser
internal enum FileType: String {
    case tmx
    case tsx
    case png
}


/// Document compression type.
internal enum CompressionType: String {
    case uncompressed
    case zlib
    case gzip
}


/**
The `SKTilemapParser` is a custom `XMLParserDelegate` parser for reading Tiled TMX and tileset TSX files.
 
 To read a tile map, used the `SKTilemapParser.load` method:
 
 ```swift
 if let tilemap = SKTilemapParser().load(fromFile: "sample-file") {
    scene.worldNode.addChild(tilemap)
 }
 ```
 */
open class SKTilemapParser: NSObject, XMLParserDelegate {
    
    open var fileNames: [String] = []                               // list of files to read
    open var currentFileName: String!
    
    open var tilemap: SKTilemap!
    fileprivate var encoding: TilemapEncoding = .xml                // encoding
    fileprivate var externalTilesets: [String: SKTileset] = [:]     // hold external tilesets 
    
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
    
    // MARK: - Loading
    
    /**
     Load a TMX file and parse it.
     
     - parameter fileNamed: `String` file base name - TMX/TSX not required.     
     - returns: `SKTilemap?` tiled map node.
     */
    open func load(fromFile filename: String) -> SKTilemap? {
        guard let targetFile = getBundledFile(named: filename) else {
            print("[SKTilemapParser]: unable to locate file: \"\(filename)\"")
            return nil
        }
        
        timer = Date()
        fileNames.append(targetFile)
                
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
        
        // reset tileset data
        externalTilesets = [:]
        
        // render and complete
        didFinishParsing()
        return tilemap
    }
    
    /**
     Return the appropriate filename string for the given file (TMX or TSX) since Tiled stores
     xml files with multiple extensions.
     
     - parameter fileName: `String` file name to search for.
     - returns: `String?` name of file in bundle.
     */
    fileprivate func getBundledFile(named filename: String) -> String? {
        // strip off the file extension
        let fileBaseName = filename.components(separatedBy: ".")[0]
        for fileExtension in ["tmx", "tsx"] {
            if let url = Bundle.main.url(forResource: fileBaseName, withExtension: fileExtension) {
                let filepath = url.absoluteString
                if let filename = filepath.components(separatedBy: "/").last {
                    return filename
                }
            }
        }
        return nil
    }

    // MARK: - Callbacks
    
    /**
     Post-process to render each layer.
     */
    fileprivate func didFinishParsing(duration: TimeInterval=0.05) {
        guard let tilemap = tilemap else { return }
        
        // worker queue
        let queue = DispatchQueue.global(qos: .userInitiated )
        
        // create a group for each tile layer
        let tileGroup = DispatchGroup()
        
        queue.async(group: tileGroup){
            
            for layer in tilemap.allLayers() {
                
                // render object groups
                if let objectGroup = layer as? SKObjectGroup {
                    objectGroup.drawObjects()
                    objectGroup.didFinishRendering()
                    continue
                }
                
                // render image layers
                if let imageLayer = layer as? SKImageLayer {
                    imageLayer.didFinishRendering()
                    continue
                }
                
                // render tile layers
                if let tileLayer = layer as? SKTileLayer {
                    
                    guard let tileData = self.data[tileLayer.uuid] else { continue }

                    // add the layer data and completion handler
                    let _ = tileLayer.setLayerData(tileData, completion: { (_ layer: SKTileLayer) -> Void in
                        // run the tilemap completion handler
                        tileLayer.didFinishRendering(duration: duration)
                    })
                    
                    // callback to signal that a layer is rendered
                    queue.async(group: tileGroup){
                        tilemap.tileLayerDidFinishRendering(layer: tileLayer)
                    }
                
                    // report errors
                    if tileLayer.gidErrors.count > 0 {
                        let gidErrorString : String = tileLayer.gidErrors.reduce("", { "\($0)" == "" ? "\($1)" : "\($0)" + ", " + "\($1)" })
                        print("[SKTilemapParser]: WARNING: layer \"\(tileLayer.name!)\": the following gids could not be found: \(gidErrorString)")
                    }
                    continue
                }
            }
        }
        
        // reset the data property when all layers are rendered & run a callback on the tilemap node
        tileGroup.notify(queue: DispatchQueue.main) {
            self.data = [:]
            self.tilemap.didFinishParsing(timeStarted: self.timer)
        }
    }
    
    // MARK: - XMLParserDelegate
    
    open func parserDidStartDocument(_ parser: XMLParser) {
        //print("[SKTilemapParser]: starting parsing...")
    }
    
    open func parserDidEndDocument(_ parser: XMLParser) {
        //print("[SKTilemapParser]: ending parsing...")
    }
    
    
    // didStartElement happens whenever parser starts a key: <key>
    open func parser(_ parser: XMLParser,
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
            
            let currentBasename = currentFileName.components(separatedBy: ".").first!
            self.tilemap.filename = currentBasename
            self.tilemap.name = currentBasename
            // run setup functions on tilemap
            self.tilemap.didBeginParsing()
            lastElement = tilemap
        }
        
        // external will have a 'source' attribute, otherwise 'image'
        if (elementName == "tileset") {
            
            // external tileset
            if let source = attributeDict["source"] {
                
                // source is a file reference
                if !(fileNames.contains(source)) {
                    fileNames.append(source)
                    
                    guard let firstGID = attributeDict["firstgid"] else { parser.abortParsing(); return }
                    let firstGIDInt = Int(firstGID)!
                    
                    let tileset = SKTileset(source: source, firstgid: firstGIDInt, tilemap: self.tilemap)
                    
                    // add tileset to external file list
                    externalTilesets[source] = tileset
                    self.tilemap.addTileset(tileset)
                    lastElement = tileset

                    // set this to nil, just in case we're looking for a collections tileset.
                    currentID = nil
                }
            }
            
            // inline tileset
            if let name = attributeDict["name"] {
                
                // update an existing tileset
                if let existingTileset = externalTilesets[currentFileName] {
                    
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
                    self.tilemap.addTileset(tileset)
                    lastElement = tileset

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
            //guard let value = attributeDict["type"] else { parser.abortParsing(); return }
            
            var propertyType = "string"
            if let ptype = attributeDict["type"] {
                propertyType = ptype
            }
            
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
            
            self.tilemap!.addLayer(layer)
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
            
            self.tilemap!.addLayer(objectsGroup)
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
            
            self.tilemap!.addLayer(imageLayer)
            lastElement = imageLayer
        }
        
        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            guard let imageWidth = attributeDict["width"] else { parser.abortParsing(); return }
            guard let imageHeight = attributeDict["height"] else { parser.abortParsing(); return }
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
                    tileset.addTilesetTile(currentID + tileset.firstGID, source: imageSource)
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
                
            objectGroup.addObject(tileObject)
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
                currentTileData.addFrame(Int(id)! + tileset.firstGID, interval: durationInSeconds)
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
    open func parser(_ parser: XMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        

        // look for last element to add properties to
        if elementName == "properties" {
            if let tilemap = lastElement as? SKTilemap {
                tilemap.properties = properties
                tilemap.parseProperties(completion: nil)
            }
            
            if let tileLayer = lastElement as? TiledLayerObject {
                tileLayer.properties = properties
                //tileLayer.parseProperties(completion: nil)   // moved this to render
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
                        lastObject.properties = properties
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
 
    
    // foundCharacters happens whenever parser enters a key poop
    open func parser(_ parser: XMLParser, foundCharacters string: String) {
        // append data attribute
        characterData += string
    }
    
    open func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        //if parseError.code == NSXMLParserError.InternalError {}
    }
    
    // MARK: - Decoding
    /**
     Scrub CSV data.
     
     - parameter data: `String` data to decode
     - returns: `[UInt32]` parsed CSV data.
     */
    private func decode(csvString data: String) -> [UInt32] {
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
    private func decode(base64String data: String, compression: CompressionType = .uncompressed) -> [UInt32]? {
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
