//
//  SKTiledObject.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit

/**
 
 ## Overview
 
 The `SKTiledObject` protocol defines a basic data structure for mapping custom Tiled
 properties to SpriteKit objects. Objects conforming to this protocol will
 automatically receive properties from the Tiled scene, unless supressed
 by setting the object's `SKTiledObject.ignoreProperties` property.
 
 
 ### Properties 
 
 | Property         | Description                                     |
 |:-----------------|:------------------------------------------------|
 | uuid             | Unique object id.                               |
 | type             | Tiled object type.                              |
 | properties       | Object of custom Tiled properties.              |
 | ignoreProperties | Ignore Tiled properties.                        |
 | renderQuality    | Resolution multiplier value.                    |
 
 
 ### Instance Methods ###
 
 | Method           | Description                                     |
 |:-----------------|:------------------------------------------------|
 | parseProperties  | Parse function (with optional completion block).|
 
 
 ### Usage
 
 ```swift
 // query a Tiled string property
 if let name = tiledObject.stringForKey("name") {
    tiledObject.name = name
 }
 
 // query a boolean property
 let isDynamic = tiledObject.boolForKey("isDynamic") == true
 ```
 
 [sktiledobject-url]:Protocols/SKTiledObject.html
 */
@objc public protocol SKTiledObject: AnyObject {
    /// Unique object id (layer & object names may not be unique).
    var uuid: String { get set }
    
    /// Object type.
    var type: String! { get set }
    
    /// Storage for custom Tiled properties.
    var properties: [String: String] { get set }
    
    /// Ignore custom properties.
    var ignoreProperties: Bool { get set }
    
    /// Parse function (with optional completion block).
    func parseProperties(completion: (() -> Void)?)
    
    /// Render scaling property.
    var renderQuality: CGFloat { get }
}


extension SKTiledObject {
    
    /// Hash id.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    // MARK: - Properties Parsing
    
    /**
     Return a string value for the given key, if it exists.
     
     ### Usage
     
     ```swift
     if let name = tileData["name"] {
     print("tile data is named \"\(name)\"")
     }
     ```
     
     - parameter key: `String` key to query.
     - returns: `String?` value for the given key.
     */
    public subscript(key: String) -> String? {
        return (ignoreProperties == false) ? properties[key] : nil
    }
    
    /**
     Returns true if the node has stored properties.
     
     - returns: `Bool` properties are not empty.
     */
    public var hasProperties: Bool {
        return !properties.isEmpty
    }
    
    /**
     Returns true if the node has the given SKTiled property (case insensitive).
     
     - parameter key: `String` key to query.
     - returns: `Bool` properties has a value for the key.
     */
    public func hasKey(_ key: String) -> Bool {
        let pnames = properties.keys.map { $0.lowercased() }
        //return pnames.contains(key.lowercased())
        return !pnames.filter { $0 == key.lowercased()}.isEmpty
    }
    
    /**
     Returns a boolean value for the given key.
     
     - parameter key: `String` properties key.
     - returns: `Bool` value for properties key.
     */
    public func boolForKey(_ key: String) -> Bool {
        if let existingPair = keyValuePair(key: key) {
            return Bool(existingPair.value) ?? false || Int(existingPair.value) == 1
        }
        return false
    }
    
    /**
     Returns a string for the given SKTiled key.
     
     - parameter key: `String` properties key.
     - returns: `String` value for properties key.
     */
    public func stringForKey(_ key: String) -> String? {
        for k in properties.keys {
            if k.lowercased() == key.lowercased() {
                return properties[k]
            }
        }
        return properties[key]
    }
    
    /**
     Returns a integer value for the given key.
     
     - parameter key: `String` properties key.
     - returns: `Int?` value for properties key.
     */
    public func intForKey(_ key: String) -> Int? {
        if let existingPair = keyValuePair(key: key) {
            return Int(existingPair.value)
        }
        return nil
    }
    
    /**
     Returns a float value for the given key.
     
     - parameter key: `String` properties key.
     - returns: `Double?` value for properties key.
     */
    public func doubleForKey(_ key: String) -> Double? {
        if let existingPair = keyValuePair(key: key) {
            return Double(existingPair.value)
        }
        return nil
    }
    
    /**
     Sets a named SKTiled property. Returns the value, or nil if it does not exist.
     
     - parameter key:   `String` property key.
     - parameter value: `String` property value.
     */
    public func setValue(forKey key: String, _ value: String) {
        if let existingPair = keyValuePair(key: key) {
            properties[existingPair.key] = value
            return
        }
        properties[key] = value
    }
    
    /**
     Remove a named SKTiled property, returns the value as a string (if property exists).
     
     - parameter key: `String` property key.
     - returns:       `String?` property value (if it exists).
     */
    public func removeProperty(forKey key: String) -> String? {
        if let existingPair = keyValuePair(key: key) {
            return properties.removeValue(forKey: existingPair.key)!
        }
        return nil
    }
    
    /// Returns a string representation of the node's properties.
    public var propertiesString: String {
        return properties.reduce("", { (aggregate: String, pair) -> String in
            let comma: String = (pair.key == Array(properties.keys).last) ? "" : ","
            return "\(aggregate)\(pair.key): \(pair.value)\(comma) "
            
        })
    }
    
    
    // MARK: - Helpers
    
    /**
     Returns a case-insensitive value for the given key.
     
     - parameter key: `String` key to query.
     - returns: `(key: String, value: String)?` tuple of key/value pair.
     */
    internal func keyValuePair(key: String) -> (key: String, value: String)? {
        for k in properties.keys {
            if (k.lowercased() == key.lowercased()) {
                return (key: k, value: properties[k]!)
            }
        }
        return nil
    }
    
    /**
     Returns true if the property is a numeric type.
     
     - parameter key: `String` key to query.
     - returns: `Bool` value is a numeric type.
     */
    internal func hasNumericKey(_ key: String) -> Bool {
        if let existingPair = keyValuePair(key: key) {
            return Int(existingPair.value) != nil || Double(existingPair.value) != nil
        }
        return false
    }
    
    /**
     Returns a string array for the given key.
     
     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     - returns: `[String]` value for properties key.
     */
    internal func stringArrayForKey(_ key: String, separatedBy: String=",") -> [String] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: separatedBy).map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
        return [String]()
    }
    
    /**
     Returns a integer array for the given key.
     
     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     - returns: `[Int]` array of integers for properties key.
     */
    internal func integerArrayForKey(_ key: String, separatedBy: String=",") -> [Int] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)}.compactMap {
                    Int($0)
                }
        }
        return [Int]()
    }
    
    /**
     Returns a double array for the given key.
     
     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     - returns: `[Double]` array of doubles for properties key.
     */
    internal func doubleArrayForKey(_ key: String, separatedBy: String=",") -> [Double] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)}.compactMap {
                    Double($0)
                }
        }
        return [Double]()
    }
}
