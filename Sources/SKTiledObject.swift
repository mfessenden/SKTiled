//
//  SKTiledObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 5/16/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit

/**

 ## Overview ##

 The `SKTiledObject` protocol defines a basic data structure for mapping custom Tiled 
 properties to SpriteKit objects. Objects conforming to this protocol will 
 automatically receive properties from the Tiled scene, unless supressed 
 by setting the object's `ignoreProperties` property.

 ## Usage ##

 ```swift
 // query a Tiled string property
 if let name = tiledObject.stringForKey("name") {
    tiledObject.name = name
 }

 // query a boolean property
 let isDynamic = tiledObject.boolForKey("isDynamic") == true
 ```

 ### Properties ###

 ```swift
  SKTiledObject.uuid              // unique object id.
  SKTiledObject.type              // object type.
  SKTiledObject.properties        // dictionary of object properties.
  SKTiledObject.ignoreProperties  // ignore custom properties.
  SKTiledObject.renderQuality     // resolution multiplier value.
 ```
 */
public protocol SKTiledObject: class, Loggable {
    /// Unique object id (layer & object names may not be unique).
    var uuid: String { get set }
    /// Object type.
    var type: String! { get set }
    /// Storage for custom Tiled properties.
    var properties: [String: String] { get set }
    /// Ignore custom properties.
    var ignoreProperties: Bool { get set }
    /// Parse function (with optional completion block).
    func parseProperties(completion: (() -> ())?)
    /// Render scaling property.
    var renderQuality: CGFloat { get }
}


public extension SKTiledObject {


    public var hashValue: Int { return uuid.hashValue }

    // MARK: - Properties Parsing
    /**
     Returns true if the node has stored properties.

     - returns: `Bool` properties are not empty.
     */
    public var hasProperties: Bool {
        return properties.isEmpty
    }

    /**
     Returns true if the node has the given property (not case sensitive).

     - parameter key: `String` key to query.
     - returns: `Bool` properties has a value for the key.
     */
    public func hasKey(_ key: String) -> Bool {
        let pnames = properties.keys.map { $0.lowercased() }
        return pnames.contains(key.lowercased())
    }

    /**
     Returns a string for the given key.

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
     Sets a named property. Returns the value, or nil if it does not exist.

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
     Remove a named property, returns the value as a string (if property exists).

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
            if k.lowercased() == key.lowercased() {
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
            return existingPair.value.components(separatedBy: separatedBy)
        }
        return [String]()
    }

    /**
     Returns a integer value for the given key.

     - parameter key: `String` properties key.
     - returns: `Int?` value for properties key.
     */
    internal func intForKey(_ key: String) -> Int? {
        if let existingPair = keyValuePair(key: key) {
            return Int(existingPair.value)
        }
        return nil
    }

    /**
     Returns a integer array for the given key.

     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     - returns: `[Int]` array of integers for properties key.
     */
    internal func integerArrayForKey(_ key: String, separatedBy: String=",") -> [Int] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: separatedBy).flatMap { Int($0) }
        }
        return [Int]()
    }

    /**
     Returns a float value for the given key.

     - parameter key: `String` properties key.
     - returns: `Double?` value for properties key.
     */
    internal func doubleForKey(_ key: String) -> Double? {
        if let existingPair = keyValuePair(key: key) {
            return Double(existingPair.value)
        }
        return nil
    }

    /**
     Returns a double array for the given key.

     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     - returns: `[Double]` array of doubles for properties key.
     */
    internal func doubleArrayForKey(_ key: String, separatedBy: String=",") -> [Double] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: separatedBy).flatMap { Double($0) }
        }
        return [Double]()
    }

    /**
     Returns a boolean value for the given key.

     - parameter key: `String` properties key.
     - returns: `Bool` value for properties key.
     */
    internal func boolForKey(_ key: String) -> Bool {
        if let existingPair = keyValuePair(key: key) {
            return Bool(existingPair.value) ?? false || Int(existingPair.value) == 1
        }
        return false
    }
}
