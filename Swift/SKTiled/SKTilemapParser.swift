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
public class SKTiledmapParser: NSObject, NSXMLParserDelegate {
    
    public var fileNames: [String] = []                         // list of filenames to read
    public var currentFileName: String!
    
    public var tileMap: SKTilemap!
    private var encoding: TilemapEncoding = .XML
    
    // stash current elements
    private var activeElement: String?                          // current object
    private var lastElement: AnyObject?                         // last object created
    private var lastID: Int?                                    // last ID referenced
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
            print("[SKTiledmapParser]: unable to locate file: \"\(fileNamed)\"")
            return nil
        }
        
        let timer = NSDate()
        
        print("[SKTiledmapParser]: loading file: \"\(targetFile)\"...")
        fileNames.append(targetFile)
                
        while !(fileNames.isEmpty) {
            if let firstFileName = fileNames.first {
                
                currentFileName = firstFileName
                fileNames.removeAtIndex(0)
                
                guard let path: String = NSBundle.mainBundle().pathForResource(currentFileName , ofType: nil) else {
                    print("[SKTiledmapParser]: no path for: \"\(currentFileName)\"")
                    return nil
                }
                
                let data: NSData = NSData(contentsOfFile: path)!
                let parser: NSXMLParser = NSXMLParser(data: data)
                parser.delegate = self
                
                print("[SKTiledmapParser]: parsing filename: \"\(currentFileName)\"")
                
                let successs: Bool = parser.parse()
                // report errors
                if (successs == false) {
                    print("error")
                    let parseError = parser.parserError
                    let errorLine = parser.lineNumber
                    let errorCol = parser.columnNumber
                    
                    let errorDescription = parseError?.description ?? "unknown"
                    print("[SKTiledmapParser]: \(errorDescription) at line \(errorLine):\(errorCol)")
                }
            }
        }
        
        // render tile layers
        renderTileLayers()
        
        // time results
        let timeInterval = NSDate().timeIntervalSinceDate(timer)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)
        
        print("\n[SKTiledmapParser]: tile map loaded in: \(timeStamp)s\n")
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
            print("[SKTilemapParser]: rendering layer \"\(tileLayer.name!)\"...")
        }
        // reset the data
        data = [:]
    }
    
    // MARK: - NSXMLParserDelegate
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        //print("[SKTiledmapParser]: starting parsing...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        //print("[SKTiledmapParser]: ending parsing...")
    }
    
    
    // didStartElement happens whenever parser starts a key: <key>
    public func parser(parser: NSXMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String: String])  {
        
        activeElement = elementName
        //print("<\(elementName)>")
        
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
            // XML data is stored with `tile` tags
            if let gid = attributeDict["gid"] {
                let gidInt = Int(gid)!
                
                if (encoding == .XML) {
                    tileData.append(Int(gid)!)
                }
            }
                
            else if let id = attributeDict["id"] {
                let idInt = Int(id)!
                lastID = idInt
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
            lastID = tileObject.id
        }
        
        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            if let objectsgroup = lastElement as? SKObjectGroup {
                if (lastID != nil) {
                    if let lastObject = objectsgroup.getObject(id: lastID!) {
                        lastObject.objectType = .Ellipse
                        lastObject.draw()
                        lastID = nil
                    }
                //lastID = nil
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
                    if (lastID != nil) {
                        if let lastObject = objectsgroup.getObject(id: lastID!) {
                            lastObject.addPoints(coordinates)
                            lastObject.draw()
                            lastID = nil
                        }
                     //lastID = nil
                    }
                }
            }
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
        
        
        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            
        }
        
        // look for last element to add properties to
        if elementName == "properties" {
            
            if let tilemap = lastElement as? SKTilemap {
                tilemap.properties = properties
            }
            
            if let tileset = lastElement as? SKTileset {
                if (lastID == nil){
                    tileset.properties = properties
                    
                } else {
                    
                    let tileID = tileset.firstGID + lastID!
                    if let tileData = tileset.getTileData(tileID) {
                        tileData.properties = properties
                    }
                }
            }
            
            if let tileLayer = lastElement as? TiledLayerObject {
                tileLayer.properties = properties
            }
            
            // clear if no last ID
            if lastID == nil {
                properties = [:]
            }
        }
        
        // look for last element to be a layer
        if (elementName == "data") {
            guard let tileLayer = lastElement as? SKTileLayer else {
                print("[SKTiledmapParser]: cannot find layer to add data.")
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
                if (lastID == nil){
                    
                    let tileID = tileset.firstGID + lastID!
                    if let tileData = tileset.getTileData(tileID) {
                        tileData.properties = properties
                        properties = [:]
                    }
                }
            }
            
            lastID = nil
        }
        
        // look for last element to be an object group
        if (elementName == "object") {
            if let objectsgroup = lastElement as? SKObjectGroup {                
                if (lastID != nil) {
                    if let lastObject = objectsgroup.getObject(id: lastID!) {
                        lastObject.properties = properties
                        properties = [:]
                        lastID = nil
                    }
                }
            }
            
            //lastID = nil
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

extension MapSize: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns the map size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    
    /// Returns total tile `Int` count
    public var count: Int { return Int(width) * Int(height) }
    
    /// Returns the rendered `CGSize` of the map
    public var renderSize: CGSize { return CGSizeMake(width * tileSize.width, height * tileSize.height) }
    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height)) @ \(tileSize)" }
    public var debugDescription: String { return description }
    
    
    /**
     Returns a representative grid texture to be used as an overlay.
     
     - parameter scale: image scale (2 seems to work best for fine detail).
     
     - returns: `SKTexture` grid texture.
     */
    public func generateGridTexture(scale: CGFloat=2.0, gridColor: UIColor=UIColor.greenColor()) -> SKTexture {
        let image: UIImage = imageOfSize(self.renderSize, scale: scale) {
            
            for col in 0 ..< Int(self.width) {
                for row in (0 ..< Int(self.height)) {
                    
                    let tileWidth = self.tileSize.width
                    let tileHeight = self.tileSize.height
                    
                    let boxRect = CGRect(x: tileWidth * CGFloat(col), y: tileHeight * CGFloat(row), width: tileWidth, height: tileHeight)
                    let boxPath = UIBezierPath(rect: boxRect)
                    
                    // stroke the grid path
                    gridColor.setStroke()
                    boxPath.stroke()
                }
            }
        }
        
        let result = SKTexture(CGImage: image.CGImage!)
        //result.filteringMode = .Nearest
        return result
    }
}


extension TileSize: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns the tile size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height))" }
    public var debugDescription: String { return description }
}


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
