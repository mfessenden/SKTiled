//
//  SKTiledObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 5/16/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/* generic Tiled object */
public protocol SKTiledObject: Hashable {
    var uuid: String { get set }                    // unique id (layer & object names may not be unique).
    var properties: [String: String] { get set }    // properties shared by most objects.
    func parseProperties()                          // parse the properties
    //func parseProperties(withBlock: ()->())         // parse properties with closure.
}



public extension SKTiledObject {
    
    public var hashValue: Int { return uuid.hashValue }
    
    /**
     Returns true if the node has the given property.
     
     - parameter key: `String` key to query.
     
     - returns: `Bool` properties has a value for the key.
     */
    public func hasKey(_ key: String) -> Bool {
        if let _ = properties[key] { return true }
        return false
    }
    
    /**
     Returns a string for the given key.
     
     - parameter key: `String` properties key.
     
     - returns: `String` value for properties key.
     */
    public func stringForKey(_ key: String) -> String? {
        return properties[key]
    }
    
    /**
     Returns a string array for the given key.
     
     - parameter key:         `String` properties key.
     - parameter separatedBy: `String` separator.
     
     - returns: `[String]` value for properties key.
     */
    public func stringArrayForKey(_ key: String, separatedBy: String=",") -> [String] {
        if let value = properties[key] {
            return value.components(separatedBy: separatedBy)
        }
        return [String]()
    }
    
    /**
     Returns a integer value for the given key.
     
     - parameter key: `String` properties key.
     
     - returns: `Int?` value for properties key.
     */
    public func intForKey(_ key: String) -> Int? {
        guard (hasKey(key) == true) else { return nil }
        return Int(properties[key]!)
    }
    
    /**
     Returns a float value for the given key.
     
     - parameter key: `String` properties key.
     
     - returns: `Double?` value for properties key.
     */
    public func doubleForKey(_ key: String) -> Double? {
        guard (hasKey(key) == true) else { return nil }
        return Double(properties[key]!)
    }
    
    /**
     Returns a boolean value for the given key.
     
     - parameter key: `String` properties key.
     
     - returns: `Bool` value for properties key.
     */
    public func boolForKey(_ key: String) -> Bool {
        guard let value = properties[key]?.lowercased() else { return false }
        return ["true", "false", "yes", "no"].contains(value) ? (["true", "yes"].contains(value)) ? true : false : false
    }
    
    /// Returns a string representation of the node's properties.
    public var propertiesString: String {
        var pstring = ""
        for value in properties.enumerated() {
            let indexIsLast = value.0 < (properties.count - 1)
            pstring += (indexIsLast==true) ? "\"\(value.1.0)\": \(value.1.1), " : "\"\(value.1.0)\": \(value.1.1)"
        }
        return pstring
    }
}
