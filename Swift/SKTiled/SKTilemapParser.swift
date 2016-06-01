//
//  SKTilemapParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Derived from: https://medium.com/@lucascerro/understanding-nsxmlparser-in-swift-xcode-6-3-1-7c96ff6c65bc#.1m4mh6nhy
//  iOS 10 Reference: http://stackoverflow.com/questions/19088231/base64-decoding-in-ios-7/19088341#19088341

import SpriteKit


public enum ParsingError: ErrorType {
    case Attribute(attr: String)
    case AttributeValue(attr: String, value: String)
    case Key(key: String)
    case Index(idx: Int)
    case Compression(value: String)
    case Error
}


// MARK: - TMX Parser
public class SKTilemapParser: NSObject, NSXMLParserDelegate {
    
    public var fileNames: [String] = []                         // list of filenames to read
    public var currentFileName: String!
    
    public var tileMap: SKTilemap!
    private var encoding: TilemapEncoding = .XML                // encoding
    
    // stash current elements
    private var activeElement: String?                          // current object
    private var lastElement: AnyObject?                         // last object created
    
    private var currentID: Int?                                  // last tile ID parsed
    
    private var properties: [String: String] = [:]              // last properties created
    private var tileData: [Int] = []                            // last tile data read
    private var characterData: String = ""                      // current tile data (string)
    private var data: [String: [Int]] = [:]                     // store data for tile layers to render in a second pass
    
    /**
     Load a tmx file and parse it.
     
     - parameter fileNamed: `String` file base name - tmx/tsx not required.
     
     - returns: `SKTilemap?` tiled map node.
     */
    public func loadFromFile(fileNamed: String) -> SKTilemap? {
        
        guard let targetFile = getBundleFilename(fileNamed) else {
            print("[SKTilemapParser]: unable to locate file: \"\(fileNamed)\"")
            return nil
        }
        
        let timer = NSDate()        
        print("[SKTilemapParser]: loading file: \"\(targetFile)\"...")
        fileNames.append(targetFile)
                
        while !(fileNames.isEmpty) {
            if let firstFileName = fileNames.first {
                
                currentFileName = firstFileName
                fileNames.removeAtIndex(0)
                
                guard let path: String = NSBundle.mainBundle().pathForResource(currentFileName , ofType: nil) else {
                    print("[SKTilemapParser]: no path for: \"\(currentFileName)\"")
                    return nil
                }
                
                let data: NSData = NSData(contentsOfFile: path)!
                let parser: NSXMLParser = NSXMLParser(data: data)
                // this should speed up parsing (hopefully)
                parser.shouldResolveExternalEntities = false
                parser.delegate = self
                
                print("[SKTilemapParser]: parsing filename: \"\(currentFileName)\"")
                
                let successs: Bool = parser.parse()
                // report errors
                if (successs == false) {
                    print("error")
                    let parseError = parser.parserError
                    let errorLine = parser.lineNumber
                    let errorCol = parser.columnNumber
                    
                    let errorDescription = parseError?.description ?? "unknown"
                    print("[SKTilemapParser]: \(errorDescription) at line \(errorLine):\(errorCol)")
                }
            }
        }
        
        // render tile layers
        renderTileLayers()
        
        // time results
        let timeInterval = NSDate().timeIntervalSinceDate(timer)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)
        
        print("\n[SKTilemapParser]: tile map loaded in: \(timeStamp)s\n")
        return tileMap
    }
    
    /**
     Return the appropriate filename string for the given file (tmx or tsx) since Tiled stores
     xml files with multiple extensions.
     
     - parameter fileName: `String` file name to search for.
     
     - returns: `String?` name of file in bundle.
     */
    public func getBundleFilename(fileName: String) -> String? {
        // strip off the file extension
        let fileBaseName = fileName.componentsSeparatedByString(".")[0]
        for fileExtension in ["tmx", "tsx"] {
            if let url = NSBundle.mainBundle().URLForResource(fileBaseName, withExtension: fileExtension) {
                let filepath = url.absoluteString
                if let filename = filepath.componentsSeparatedByString("/").last {
                    return filename
                }
            }
        }
        return nil
    }
    
    /**
     Post-process to render each layer.
     */
    private func renderTileLayers() {
        guard let tileMap = tileMap else { return }
        
        for (uuid, tileData) in data {
            guard let tileLayer = tileMap.getLayer(withID: uuid) as? SKTileLayer else { continue }
            
            // add the layer data...
            tileLayer.setLayerData(tileData)
            //print("[SKTilemapParser]: rendering layer \"\(tileLayer.name!)\"...")
        }
        // reset the data
        data = [:]
    }
    
    // MARK: - NSXMLParserDelegate
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        //print("[SKTilemapParser]: starting parsing...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        //print("[SKTilemapParser]: ending parsing...")
    }
    
    
    // didStartElement happens whenever parser starts a key: <key>
    public func parser(parser: NSXMLParser,
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
        //print("\(elementStartString)>")

        if (elementName == "map") {
            guard let tilemap = SKTilemap(attributes: attributeDict) else {
                parser.abortParsing()
                return
            }
            
            self.tileMap = tilemap
            self.tileMap.name = currentFileName
            lastElement = tilemap
        }
        
        
        // external will have a 'source' attribute, otherwise 'image'
        if (elementName == "tileset") {
            
            // external tileset
            if let source = attributeDict["source"] {
                
                if !(fileNames.contains(source)) {
                    //print("adding tileset source: \"\(source)\"")
                    fileNames.append(source)
                    
                    guard let firstGID = attributeDict["firstgid"] else { parser.abortParsing(); return }
                    let firstGIDInt = Int(firstGID)!
                    
                    let tileset = SKTileset(source: source, firstgid: firstGIDInt, tilemap: self.tileMap)
                    self.tileMap.addTileset(tileset)
                    lastElement = tileset
                }
            }
            
            
            // inline tileset
            if let name = attributeDict["name"] {
                
                // update an existing tileset
                if let existingTileset = self.tileMap.getTileset(name) {
                    //<tileset name="msp-spritesheet1-8x8" tilewidth="8" tileheight="8" spacing="1" tilecount="176" columns="22">
                    guard let width = attributeDict["tilewidth"] else { parser.abortParsing(); return }
                    guard let height = attributeDict["tileheight"] else { parser.abortParsing(); return }
                    guard let columns = attributeDict["columns"] else { parser.abortParsing(); return }
                    

                    existingTileset.tileSize = TileSize(width: CGFloat(Int(width)!), height: CGFloat(Int(width)!))
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
                    // create new tileset
                    guard let tileset = SKTileset(attributes: attributeDict) else { parser.abortParsing(); return }
                    self.tileMap.addTileset(tileset)
                    lastElement = tileset
                }
            }
        }
        
        if elementName == "tileoffset" {
            guard let x = attributeDict["x"] else { parser.abortParsing(); return }
            guard let y = attributeDict["y"] else { parser.abortParsing(); return }
            
            if let tileset = lastElement as? SKTileset {
                tileset.offset = CGPoint(x: Int(x)!, y: Int(y)!)
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
            guard let layer = SKTileLayer(tileMap: self.tileMap!, attributes: attributeDict)
                else {
                print("Error creating tile layer: \"\(layerName)\"")
                parser.abortParsing()
                return
            }
            
            self.tileMap!.addLayer(layer)
            lastElement = layer
        }
        
        // 'objectgroup' indicates an Object layer
        if (elementName == "objectgroup") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let objectsGroup = SKObjectGroup(tileMap: self.tileMap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            self.tileMap!.addLayer(objectsGroup)
            objectsGroup.yScale = -1
            lastElement = objectsGroup
        }
        
        // 'imagelayer' indicates an Image layer
        if (elementName == "imagelayer") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let imageLayer = SKImageLayer(tileMap: self.tileMap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            self.tileMap!.addLayer(imageLayer)
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
                tileset.addTextures(fromSpriteSheet: imageSource)
            }
        }
        
        
        if elementName == "tile" {
            // XML data is stored with a `tile` tag
            if let gid = attributeDict["gid"] {
                let gidInt = Int(gid)!
                // just append this to the tileData property
                if (encoding == .XML) {
                    tileData.append(Int(gid)!)
                }
            }
                
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
                    if let currentObject = objectsgroup.getObject(id: currentID!) {
                        currentObject.objectType = .Ellipse
                        currentObject.draw()
                    }
                }
            }
        }
        
        if (elementName == "polygon") {
            // polygon object
            if let pointsString = attributeDict["points"] {
                var coordinates: [[CGFloat]] = []
                let points = pointsString.componentsSeparatedByString(" ")
                for point in points {
                    let coords = point.componentsSeparatedByString(",").flatMap { x in Double(x) }
                    coordinates.append(coords.flatMap { CGFloat($0) })
                }
                
                if let objectsgroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectsgroup.getObject(id: currentID!) {
                            currentObject.addPoints(coordinates)
                            currentObject.draw()
                        }
                    }
                }
            }
        }
        
        // animated tiles
        if (elementName == "frame") {
            guard let currentID = currentID else {
                print("  -> cannot assign frame information without tile id")
                parser.abortParsing()
                return}
            
            guard let id = attributeDict["tileid"] else { parser.abortParsing(); return }
            guard let duration = attributeDict["duration"] else { parser.abortParsing(); return }
            guard let tileset = lastElement as? SKTileset else { parser.abortParsing(); return }
            guard let tileData = tileset.getTileData(currentID + tileset.firstGID) else { parser.abortParsing(); return }

            tileData.addFrame(Int(id)! + tileset.firstGID, duration: Double(duration)!)
        }

        // decode data here, and reset
        if (elementName == "data") {
            // get the encoding...
            if let encoding = attributeDict["encoding"] {
                self.encoding = TilemapEncoding(rawValue: encoding)!
            }
            
            // compression is not yet supported...
            if let compression = attributeDict["compression"] {
                //throw ParsingError.Compression(value: compression)
                fatalError("compression type: \(compression) not supported.")
            }
        }
    }
    
    
    // didEndElement happens whenever parser ends a key: </key>
    public func parser(parser: NSXMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        
        
        //print("</\(elementName)>")

        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            
        }
        
        // look for last element to add properties to
        if elementName == "properties" {
            
            if let tilemap = lastElement as? SKTilemap { tilemap.properties = properties }
            if let tileLayer = lastElement as? TiledLayerObject { tileLayer.properties = properties }
            if let tileset = lastElement as? SKTileset {
                if (currentID == nil){
                    tileset.properties = properties
                    
                } else {
                    
                    let tileID = tileset.firstGID + currentID!
                    if let tileData = tileset.getTileData(tileID) {
                        //print("  -> adding properties to id: \(tileID)")
                        tileData.properties = properties
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
            
            if (encoding == .Base64) {
                foundData = true
                if let dataArray = decode(base64String: characterData) {
                    for id in dataArray {
                        tileData.append(id)
                    }
                }
            }
            
            if (encoding == .CSV) {
                foundData = true
                let dataArray = decode(csvString: characterData)
                for id in dataArray {
                    tileData.append(id)
                }
            }
            
            if (encoding == .XML) {
                foundData = true
            }
            
            
            // write data to buffer
            if (foundData==true) {
                //let success = tileLayer.setLayerData(tileData)
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
                if (currentID == nil){
                    
                    let tileID = tileset.firstGID + currentID!
                    if let tileData = tileset.getTileData(tileID) {
                        tileData.properties = properties
                        properties = [:]
                    }
                }
            }
            
            currentID = nil
        }
        
        // look for last element to be an object group
        if (elementName == "object") {
            if let objectsgroup = lastElement as? SKObjectGroup {                
                if (currentID != nil) {
                    if let lastObject = objectsgroup.getObject(id: currentID!) {
                        lastObject.properties = properties
                        properties = [:]
                    }
                }
            }
            
            currentID = nil
        }
        
        // look for last element to be a tileset
        if (elementName == "tileoffset") {
            
        }
        
        // reset character data
        characterData = ""
    }
 
    
    // foundCharacters happens whenever parser enters a key
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        // append data attribute
        characterData += string
    }
    
    public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        //if parseError.code == NSXMLParserError.InternalError {}
    }
    
    // MARK: Unused
    public func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
    }
    
    public func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String) {

    }
    
    public func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
        print("external entity: \(name)")
    }
    
    // MARK: - Decoding
    /**
     Scrub CSV data.
     
     - parameter data: `String` data to decode
     
     - returns: `[Int]` parsed CSV data.
     */
    private func decode(csvString data: String) -> [Int] {
        return data.scrub().componentsSeparatedByString(",").map {Int($0)!}
    }
    
    /**
     Clean up and convert string Base64-formatted data.
     
     See: stackoverflow.com/questions/28902455/convert-base64-string-to-byte-array-like-c-sharp-method-convert-frombase64string
     
     - parameter data: `String` Base64 formatted data to decode
     
     - returns: `[Int]?` parsed data.
     */
    private func decode(base64String data: String) -> [Int]? {
        if let nsdata = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
            let count = nsdata.length / sizeof(Int32)
            //var bytes = [Int32](count: nsdata.length, repeatedValue: 0)
            var bytes = [Int32](count: count, repeatedValue: 0)
            nsdata.getBytes(&bytes)
            return bytes.flatMap { Int($0) }
        }
        return nil // Invalid input
    }
    
    // MARK: - Decompression
    private func decompress(gzipData data: String) -> String? {
        return nil
    }
    
    private func decompress(zlibData data: String) -> String? {
        return nil
    }
}

// MARK: - Extensions

extension Property: CustomStringConvertible {
    public var description: String { return "Property: \"\(name)\": \"\(value)\"" }
}


public extension String {
    /**
     Initialize with array of bytes.
     
     - parameter bytes: `[UInt8]` byte array.
     */
    public init(_ bytes: [UInt8]) {
        self.init()
        for b in bytes {
            self.append(UnicodeScalar(b))
        }
    }
    
    /**
     Clean up whitespace & carriage returns.
     
     - returns: `String` scrubbed string.
     */
    public func scrub() -> String {
        var scrubbed = self.stringByReplacingOccurrencesOfString("\n", withString: "")
        scrubbed = scrubbed.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return scrubbed.stringByReplacingOccurrencesOfString(" ", withString: "")
    }
}
