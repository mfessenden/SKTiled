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
    

/* generic property */
public struct Property {
    public var name: String
    public var value: AnyObject
    
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


// MARK: - Proxy Objects
public struct Tileset {
    public var source: String
    public var firstgid: Int
}


public struct TileLayer {
    public var name: String
    public var mapSize: MapSize
    public var data: AnyObject!
    public var index: Int
    // TODO: add z-depth?
}


/// tile layer tile
public struct TileCoord {
    // row: y, col: x
    public var x: Int32
    public var y: Int32
}


/// tile layer tile
public struct Tile {
    public var id: Int
    public var x: Int
    public var y: Int
}


// MARK: - TMX Parser
public class TMXParser: NSObject, NSXMLParserDelegate {
    
    public var filename: String!
    public var data: [String: AnyObject]!
    public var tilemap: SKTilemap!
    public var currentLayerName: String!
    public var layers: [TileLayer] = []
    
    /**
     Load a tilemap from file.
     
     - parameter fileNamed: `String` tmx file name.
     
     - returns: `SKTilemap?` tilemap.
     */
    public func loadFromFile(fileNamed: String) -> SKTilemap? {
        print("TMXParser: parsing tmx file: \"\(fileNamed).tmx\"")
        let path: String = NSBundle.mainBundle().pathForResource(fileNamed , ofType: "tmx")!
        let data: NSData = NSData(contentsOfFile: path)!
        let parser: NSXMLParser = NSXMLParser(data: data)
        
        self.filename = fileNamed
        parser.delegate = self
        
        // if there are no errors, parser returns true
        let success: Bool = parser.parse()
        if (success==true) {
            return self.tilemap
        }
        
        return nil
    }
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        print("TMXParser: starting parse...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        print("TMXParser: ending parse...")
    }
    
    
    public func parser(parser: NSXMLParser, didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String: String])  {
        
        // create a tilemap node
        if (elementName == "map") {
            print("TMXParser: creating tilemap...")
            guard let tilemap = SKTilemap(attributes: attributeDict) else {
                parser.abortParsing()
                return
            }
            
            self.tilemap = tilemap
            self.tilemap.name = self.filename!
        }
    }
    
    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    }
    
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        print("TMXParser: Parsing characters...")
    }
    
    public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("TMXParser: parse error...")
    }
}


