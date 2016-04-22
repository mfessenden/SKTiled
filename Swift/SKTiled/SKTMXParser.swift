//
//  SKTMXParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Derived from: https://medium.com/@lucascerro/understanding-nsxmlparser-in-swift-xcode-6-3-1-7c96ff6c65bc#.1m4mh6nhy

import SpriteKit


protocol TilemapObject {
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


public struct MapSize {
    public var width: CGFloat
    public var height: CGFloat
}


public struct TileLayer {
    public var name: String
    public var tileSize: TileSize
    public var mapSize: MapSize
    public var data: AnyObject!
}


// MARK: - TMX Parser
public class TMXParser: NSObject, NSXMLParserDelegate {
    
    public var fileNames: [String] = []
    public var currentFileName: String!
    public var data: [Int] = []
    public var characterData: String = ""
    public var tileMap: SKTilemap!
    
    private var encoding: TilemapEncoding = .XML
    
    // stash current elements
    private var activeElement: String?
    private var lastElement: AnyObject?
    private var lastID: Int?
    private var properties: [String: String] = [:]
    
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        print("TMXParser: starting parsing...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        print("TMXParser: ending parsing...")
    }
    
    /**
     Load a tmx file and parse it.
     
     - parameter fileNamed: `String` file base name - tmx/tsx not required.
     
     - returns: `SKTilemap?` tiled map node.
     */
    public func loadFromFile(fileNamed: String) -> SKTilemap? {
        guard let bundleFile = checkBundleForFile(fileNamed) else {
            print("TMXParser: unable to locate file: \"\(fileNamed)\"")
            return nil
        }
        
        print("TMXParser: loading file: \"\(bundleFile)\"...")
        fileNames.append(bundleFile)
                
        while !(fileNames.isEmpty) {
            if let firstFileName = fileNames.first {
                
                currentFileName = firstFileName
                fileNames.removeAtIndex(0)
                
                guard let path: String = NSBundle.mainBundle().pathForResource(currentFileName , ofType: nil) else {
                    print("TMXParser: no path for: \"\(currentFileName)\"")
                    return nil
                }
                
                let data: NSData = NSData(contentsOfFile: path)!
                let parser: NSXMLParser = NSXMLParser(data: data)
                parser.delegate = self
                
                print("TMXParser: parsing filename: \"\(currentFileName)\"")
                
                var successs: Bool = parser.parse()
                
                if (successs == true) {
                    print("TMXParser: parsing succeeded.")
                } else {
                    let errorDescription = parser.parserError?.description ?? "unknown"
                    print("TMXParser: \(errorDescription)")
                }
            }
        }
        
        if let tileMap = tileMap {
            return tileMap            
        }
        return nil
    }
    
    /**
     Return the appropriate filename string for the given file (tmx or tsx) since Tiled stores
     xml files with multiple extensions.
     
     - parameter fileName: `String` file name to search for.
     
     - returns: `String?` name of file in bundle.
     */
    public func checkBundleForFile(fileName: String) -> String? {
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
        
        //print("TMXParser: element name: \"\(elementName)\"")
        
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
            if let source = attributeDict["source"] {
                if !(fileNames.contains(source)) {
                    print("TMXParser: found external tileset: \"\(source)\"")
                    fileNames.append(source)
                    
                    guard let firstGID = attributeDict["firstgid"] else { parser.abortParsing(); return }
                    let firstGIDInt = Int(firstGID)!
                    
                    let tileset = SKTileset(source: source, firstgid: firstGIDInt, tilemap: self.tileMap)
                    self.tileMap.addTileset(tileset)
                    lastElement = tileset
                }
                
                /*
                 guard let tileset = TSXParser().loadFromFile(source) else {
                 print("TMXParser: error reading tileset file: \"\(source)\"")
                 parser.abortParsing()
                 return
                 }
                 */
            }
            /*
             guard let tileset = SKTileset(attributes: attributeDict) else {
             parser.abortParsing()
             return
             }
             
             tileMap!.addTileset(tileset)
             lastElement = tileset
             */
        }
        
        
        if elementName == "property" {
            guard let name = attributeDict["name"] else { parser.abortParsing(); return }
            guard let value = attributeDict["value"] else { parser.abortParsing(); return }
            //guard let value = attributeDict["type"] else { parser.abortParsing(); return }
            
            var propertyType = "string"
            if let ptype = attributeDict["type"] {
                propertyType = ptype
            }
            
            
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
            
            self.tileMap!.addTileLayer(layer)
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
            
            self.tileMap!.addTileLayer(objectsGroup)
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
            
            self.tileMap!.addTileLayer(imageLayer)
            lastElement = imageLayer
        }
        
        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            guard let imageWidth = attributeDict["width"] else { parser.abortParsing(); return }
            guard let imageHeight = attributeDict["height"] else { parser.abortParsing(); return }
            guard let imageSource = attributeDict["source"] else { parser.abortParsing(); return }
            if let imageLayer = lastElement as? SKImageLayer {
                // TODO: add this as a function
                let texture = SKTexture(imageNamed: imageSource)
                texture.filteringMode = .Nearest
                imageLayer.sprite = SKSpriteNode(texture: texture)
                imageLayer.addChild(imageLayer.sprite!)
            }
        }

        if elementName == "tile" {
            
            if let gid = attributeDict["gid"] where (Int(gid) != nil) && encoding == .XML {
                data.append(Int(gid)!)
            }
            else if let id = attributeDict["id"] where (Int(id) != nil) {
                lastID = Int(id)!
            } else {
                parser.abortParsing()
                return
            }
        }

        // look for last element to be an object group
        if (elementName == "object") {
 
        }
        
        // decode data here, and reset
        if (elementName == "data") {
            // get the encoding...
            if let encoding = attributeDict["encoding"] {
                self.encoding = TilemapEncoding(rawValue: encoding)!
            }
            
            // check if there's compression, need to uncompress
            // if this has  a value
            if let compression = attributeDict["compression"] {
                print(" -> found \(encoding) data (\(compression))")
            } else {
                print(" -> found \(encoding) data")
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
        
        // look for last element to be a property
        if (elementName == "properties") {
            
        }
        
        // look for last element to be a layer
        if (elementName == "data") {
            
        }
        
        // look for last element to be a data
        if (elementName == "tile") {
        }
        
        // look for last element to be an object group
        if (elementName == "object") {
        }
        
        
        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            
        }
        
        // look for last element to be a tileset
        if (elementName == "tileoffset") {
            
        }
        
        // look for last element to be an object group
        if (elementName == "data") {
            
            // reset data
            data = []
        }
        
        // reset character data
        characterData = ""
    }
 
    
    // foundCharacters happens whenever parser enters a key
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        characterData += string
    }
    
    public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("TMXParser: parse error...")
    }
    
}


extension MapSize: CustomStringConvertible, CustomDebugStringConvertible {
    
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


extension TileLayer: CustomStringConvertible {
    public var description: String {
        return "Layer: \"\(name)\": \"\(mapSize.description)\""
    }
}