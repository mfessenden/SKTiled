//
//  SKTMXParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Derived from: https://medium.com/@lucascerro/understanding-nsxmlparser-in-swift-xcode-6-3-1-7c96ff6c65bc#.1m4mh6nhy

import SpriteKit
import GameplayKit


// MARK: - Protocols

/* generic SKTilemap object */
protocol TiledObject {
    var uuid: String { get set }
    var properties: [String: String] { get set }
}


// MARK: - Tiled File Properties
public enum TilemapOrientation: String {
    case Orthogonal   = "orthogonal"
    case Isometric    = "isometric"
    case Hexagonal    = "hexagonal"
    case Staggered    = "staggered"
}


public enum RenderOrder: String {
    case RightDown  = "right-down"
    case RightUp    = "right-up"
    case LeftDown   = "left-down"
    case LeftUp     = "left-up"
}


public enum TilemapEncoding: String {
    case Base64  = "base64"
    case CSV     = "csv"
    case XML     = "xml"
}

/* valid property types */
public enum PropertyType: String {
    case bool
    case int
    case float
    case string
}


/* generic property */
public struct Property {
    public var name: String
    public var value: AnyObject
    public var type: PropertyType = .string
}



// MARK: - Sizing
public struct TileSize {
    public var width: CGFloat
    public var height: CGFloat
}


public var TileSizeZero = TileSize(width: 0, height: 0)
public var TileSize8x8  = TileSize(width: 8, height: 8)
public var TileSize16x16 = TileSize(width: 16, height: 16)



public struct MapSize {
    public var width: CGFloat
    public var height: CGFloat
}



// MARK: - TMX Parser
public class SKTiledmapParser: NSObject, NSXMLParserDelegate {
    
    public var fileNames: [String] = []                         // list of filenames to read
    public var currentFileName: String!
    
    public var tileMap: SKTilemap!
    
    private var encoding: TilemapEncoding = .XML
    
    // stash current elements
    private var currentLayerIndex: Int = 0                      // index of last layer added
    private var activeElement: String?                          // current object
    private var lastElement: AnyObject?                         // last object created
    private var lastID: Int?                                    // last ID referenced
    private var properties: [String: String] = [:]              // last properties created
    private var tileData: [Int] = []                            // last tile data read
    private var characterData: String = ""                      // current tile data (string)
    
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        print("[SKTiledmapParser]: starting parsing...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        print("[SKTiledmapParser]: ending parsing...")
    }
    
    /**
     Load a tmx file and parse it.
     
     - parameter fileNamed: `String` file base name - tmx/tsx not required.
     
     - returns: `SKTilemap?` tiled map node.
     */
    public func loadFromFile(fileNamed: String) -> SKTilemap? {
        
        guard let targetFile = checkBundleForFile(fileNamed) else {
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
                
                if (successs == true) {
                    print("[SKTiledmapParser]: parsing succeeded.")
                } else {
                    let errorDescription = parser.parserError?.description ?? "unknown"
                    print("[SKTiledmapParser]: \(errorDescription)")
                }
            }
        }
        
        // time results
        let timeInterval = NSDate().timeIntervalSinceDate(timer)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)
        print("[SKTiledmapParser]: tile map loaded in: \(timeStamp)s\n")
        
        return tileMap
    }
    
    /**
     Return the appropriate filename string for the given file (tmx or tsx) since Tiled stores
     xml files with multiple extensions.
     
     - parameter fileName: `String` file name to search for.
     
     - returns: `String?` name of file in bundle.
     */
    public func checkBundleForFile(fileName: String) -> String? {
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
    
    // didStartElement happens whenever parser starts a key: <key>
    public func parser(parser: NSXMLParser,
                       didStartElement elementName: String,
                                       namespaceURI: String?,
                                       qualifiedName qName: String?,
                                                     attributes attributeDict: [String: String])  {
        
        activeElement = elementName
        
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
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let layer = SKTileLayer(tileMap: self.tileMap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }
            
            layer.index = currentLayerIndex
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
            
            objectsGroup.index = currentLayerIndex
            self.tileMap!.addLayer(objectsGroup)
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
            
            imageLayer.index = currentLayerIndex
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
                //offsetx="232" offsety="400">
                
                // position the layer
                var offsetx: CGFloat = 0
                var offsety: CGFloat = 0
                
                if let offsetX = attributeDict["offsetx"] {
                    offsetx = CGFloat(Double(offsetX)!)
                }
                
                if let offsetY = attributeDict["offsety"] {
                    offsety = CGFloat(Double(offsetY)!)
                }
                
                imageLayer.position = CGPointMake(offsetx, offsety)
            }
            
            // update a tileset
            // TODO: need to pass trans color?
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
            
            if let objectGroup = lastElement as? SKObjectGroup {
                guard let newObject = objectGroup.addObject(tileObject) else {
                    print("[SKTilemapParer]: Error adding object to group.")
                    parser.abortParsing()
                    return
                }
            }
            
            lastElement = tileObject
        }
        
        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            if let tileObject = lastElement as? SKTileObject {
                tileObject.shapeType = .Ellipse
                tileObject.update()
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
                
                if let tileObject = lastElement as? SKTileObject {
                    tileObject.addPoints(coordinates)
                    //tileObject.update()
                }
            }
        }
        
        
        // decode data here, and reset
        if (elementName == "data") {
            // get the encoding...
            if let encoding = attributeDict["encoding"] {
                self.encoding = TilemapEncoding(rawValue: encoding)!
            }
            
            // check if there's compression, need to uncompress
            // if this has a value
            if let compression = attributeDict["compression"] {
                print("[SKTiledmapParser]: compression type: \(compression)")
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
                if let dataArray = decodeBase64Data(characterData) {
                    for id in dataArray {
                        tileData.append(id)
                    }
                }
            }
            
            if (encoding == .CSV) {
                foundData = true
                let dataArray = decodeCSVData(characterData)
                for id in dataArray {
                    tileData.append(id)
                }
            }
            
            if (encoding == .XML) {
                foundData = true
            }
            
            if (foundData==true) {
                let success = tileLayer.setLayerData(tileData)
                if (success == false) {
                    // scream bloody murder here
                    print("[SkTiledmapParser]: Error adding layer data.")
                }
                
            } else {
                parser.abortParsing()
                return
            }
            
            // reset s=csv data
            tileData = []
        }
        
        // look for last element to be a data
        if (elementName == "tile") {
            
            // parse properties
            if let tileset = lastElement as? SKTileset {
                if lastID == nil {
                    
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
        }
        
        // look for last element to be a tileset
        if (elementName == "tileoffset") {
            
        }
        
        // advance the current index
        if (elementName == "layer") {
            currentLayerIndex += 1
        }
        
        if (elementName == "objectgroup") {
            currentLayerIndex += 1
        }
        
        if (elementName == "imagelayer") {
            currentLayerIndex += 1
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
        print("[SKTiledmapParser]: parse error...")
    }
    
    // MARK: - Decoding
    /**
     Clean up and convert string CSV data.
     
     - parameter data: `String` data to decode
     
     - returns: `[Int]` parsed CSV data.
     */
    private func decodeCSVData(data: String) -> [Int] {
        var result: [Int] = []
        var tempData = ""
        tempData = data.stringByReplacingOccurrencesOfString("\n", withString: "")
        tempData = tempData.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        tempData = tempData.stringByReplacingOccurrencesOfString(" ", withString: "")
        let dataArray = tempData.componentsSeparatedByString(",")
        for id in dataArray {
            if let idValue = Int(id) {
                result.append(idValue)
            } else {
                print("invalid: \(id)")
            }
        }
        
        return result
    }
    
    /**
     Clean up and convert string Base64-formatted data.
     
     See: stackoverflow.com/questions/28902455/convert-base64-string-to-byte-array-like-c-sharp-method-convert-frombase64string
     
     - parameter data: `String` Base64 formatted data to decode
     
     - returns: `[Int]?` parsed data.
     */
    private func decodeBase64Data(base64String: String) -> [Int]? {
        if let nsdata = NSData(base64EncodedString: base64String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
            let count = nsdata.length / sizeof(Int32)
            //var bytes = [Int32](count: nsdata.length, repeatedValue: 0)
            var bytes = [Int32](count: count, repeatedValue: 0)
            nsdata.getBytes(&bytes)
            return bytes.flatMap { Int($0) }
        }
        return nil // Invalid input
    }
}




extension MapSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var cgSize: CGSize {
        return CGSizeMake(width, height)
    }
    
    /// returns total tile count
    public var count: Int {
        return Int(width) * Int(height)
    }
    
    public var description: String {
        return "\(Int(width)) x \(Int(height))"
    }
    
    public var debugDescription: String {
        return description
    }
}


extension TileSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var cgSize: CGSize {
        return CGSizeMake(width, height)
    }
    
    public var description: String {
        return "\(Int(width)) x \(Int(height))"
    }
    
    public var debugDescription: String {
        return description
    }
}


extension Property: CustomStringConvertible {
    public var description: String {
        return "Property: \"\(name)\": \"\(value)\""
    }
}