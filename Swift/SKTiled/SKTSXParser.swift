//
//  SKTSXParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// MARK: - TMX Parser
public class TSXParser: NSObject, NSXMLParserDelegate {
    
    public var filename: String!
    public var data: [Int] = []
    public var tileSet: SKTileset!
    public var currentLayerName: String!
    
    private var characterData: String = ""
    
    public func loadFromFile(fileNamed: String) -> SKTileset? {
        print("TSXParser: parsing tsx file: \"\(fileNamed).tsx\"")
        let path: String = NSBundle.mainBundle().pathForResource(fileNamed , ofType: "tsx")!
        let data: NSData = NSData(contentsOfFile: path)!
        let parser: NSXMLParser = NSXMLParser(data: data)
        
        self.filename = fileNamed
        parser.delegate = self
        if parser.parse() {
            return self.tileSet
        }
        
        return nil
    }
    
    public func parserDidStartDocument(parser: NSXMLParser) {
        print("TSXParser: starting parse...")
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        print("TSXParser: ending parse...")
    }
    
    
    public func parser(parser: NSXMLParser, didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                                     attributes attributeDict: [String: String])  {
        
        //["name": "msp-spritesheet1-8x8", "spacing": "1", "tilewidth": "8", "columns": "22", "tileheight": "8", "tilecount": "176"]
        if (elementName == "tileset") {
            print(attributeDict)
        }
        
        if (elementName == "image") {
            print(attributeDict)
        }
        
        if (elementName == "tile") {
            print(attributeDict)
        }
        
        // look for lastElement to be tileset, tile
        if (elementName == "properties") {
            print(attributeDict)
        }

    }
    
    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        characterData = ""
    }
    
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        characterData += string
    }
    
    public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("TSXParser: parse error...")
    }
}

