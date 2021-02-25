//
//  TiledObjectType.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


/// The `TiledObjectType` protocol defines a basic node type with a data structure for mapping custom **Tiled**
/// properties to **SpriteKit** nodes. The `TiledObjectType.parseProperties` method translates Tiled node custom properties to SpriteKit/SKTiled properties.
///
/// Objects conforming to this protocol will automatically receive properties from the source **Tiled** scene, unless supressed by setting the nodes's `TiledObjectType.ignoreProperties` property.
///
/// ### Properties
///
/// - `uuid`:  unique object id.
/// - `type`: Tiled object type.
/// - `properties`: object of custom Tiled properties.
/// - `ignoreProperties`: ignore Tiled properties.
/// - `parseProperties`:  parse Tiled attributes (with optional completion handler).
///

/// ### Usage
///
/// Querying a property is simple. Simply use the `hasKey` function:
///
/// ```swift
/// tiledObject.hasKey("floorColor")
///
/// // or use a subscript to query a property...
/// let floorColor = tiledObject["floorColor"]
/// ```
///
/// ```swift
/// // query a Tiled string property
/// if let nodeType = tiledObject.stringForKey("nodeType") {
///     tiledObject.type = nodeType
/// }
/// ```
///
/// ```swift
/// // query a boolean property
/// let isDynamic = tiledObject.boolForKey("isDynamic") == true
/// ```
///
/// For more information, see the **[TiledObjectType][sktiled-custom-properties-url]** page in the **[official documentation][sktiled-docroot-url]**. Also see the **[Tiled Properties][tiled-custom-properties-url]** page in the **[Tiled Documentation][tiled-docroot-url]**.
///
/// [sktiled-custom-properties-url]:tiled-properties.html
/// [sktiled-docroot-url]:https://mfessenden.github.io/SKTiled/1.3/index.html
/// [tiled-custom-properties-url]:https://doc.mapeditor.org/en/stable/manual/custom-properties/
/// [tiled-docroot-url]:https://doc.mapeditor.org/en/stable
@objc public protocol TiledObjectType: TiledCustomReflectableType {

    /// Unique object id (layer & object names may not be unique).
    @objc var uuid: String { get }

    /// ## Overview
    ///
    /// Object type property as parsed from **Tiled**.
    @objc var type: String! { get set }
    
    /// Storage for custom Tiled properties.
    @objc var properties: [String: String] { get set }
    
    /// :nodoc: Storage for custom Tiled properties.
    @objc optional var _tiled_properties: [String: String] { get set }
    
    /// :nodoc: Storage for properties from a template or tile data.
    @objc optional var secondaryProperties: [String: String] { get set }
    
    /// Ignore custom node properties.
    @objc var ignoreProperties: Bool { get set }
    
    /// Parse function (with optional completion block).
    @objc optional func parseProperties(completion: (() -> Void)?)
}



// MARK: - Extensions

/// :nodoc:
extension TiledObjectType {

    /// Shortened unique id string.
    public var shortId: String {
        return uuid.components(separatedBy: "-").first ?? "NULL"
    }

    /// Allows the type to be used in a hashable data structure.
    ///
    /// - Parameter hasher: hasher instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    /// A descriptive string parsed from the original **Tiled** scene.
    public var tiledNodeDescription: String? {
        get {
            return stringForKey("description")
        } set {
            guard let newdesc = newValue else {
                return
            }
            properties["description"] = newdesc
        }
    }
}


/// :nodoc
extension TiledObjectType {
    
    public func mirrorChildren() -> [(label: String, value: Any)] {
        var attributes: [(label: String, value: Any)] = []
        for (key, value) in properties {
            attributes.append((key, value as Any))
        }
        return attributes
    }
}


extension TiledObjectType {
    
    /// Query and return a custom property. Optionally setting a default value.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - default: default value, if the property doesn't already exist.
    /// - Returns: custom property value.
    public func getValue(for key: String, defaultValue: String? = nil) -> String? {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value
        }
        properties[key] = defaultValue
        return defaultValue
    }
    
    /// Sets a named `SKTiled` property.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - value: property value.
    public func setValue(for key: String, _ value: String) {
        if let existingPair = keyValuePair(key: key) {
            properties[existingPair.key] = value
            return
        }
        properties[key] = value
    }
    
    // MARK: - Properties Parsing
    
    /// Return a string value for the given key, if it exists.
    ///
    /// ### Usage
    ///
    ///  ```swift
    ///  if let name = tileData["name"] {
    ///     print("tile data is named '\(name)'")
    ///  }
    ///  ```
    ///
    /// - parameter key: `String` key to query.
    public subscript(key: String) -> String? {
        get {
            return (ignoreProperties == false) ? properties[key] : nil
        } set(newValue) {
            properties[key] = newValue
        }
    }
    
    /// Returns true if the node has stored properties.
    public var hasProperties: Bool {
        return properties.isEmpty
    }
    
    /// Returns a string representation of the node's properties.
    public var propertiesString: String {
        return properties.reduce("", { (aggregate: String, pair) -> String in
            let comma: String = (pair.key == Array(properties.keys).last) ? "" : ","
            return "\(aggregate)\(pair.key): \(pair.value)\(comma) "
        })
    }
    
    /// Returns an attributed string representation of the node's properties.
    ///
    /// - Parameter delineator: param string delineator.
    /// - Returns: attributed string.
    public func propertiesAttributedString(delineator: String?) -> NSAttributedString {
        let outputString = NSMutableAttributedString()
        // let paragraphStyle = NSMutableParagraphStyle()
        
        for (idx, property)  in properties.enumerated() {
            let thisPropertyString = NSMutableAttributedString()
            let keyString = "\(property.key): "
            thisPropertyString.append(NSAttributedString(string: keyString))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineHeightMultiple = 1.0
            
            let value = property.value
            
            // check for hex color strings...
            if value.hasPrefix("#") {
                if (value.count >= 7) {
                    
                    let colorString = "●"
                    
                    #if os(macOS)
                    let valueColor = NSColor(hexString: value)
                    let colorAttributes = [
                        .foregroundColor: valueColor,
                        .paragraphStyle: paragraphStyle,
                        .font: NSFont.systemFont(ofSize: 12)
                    ] as [NSAttributedString.Key: Any]
                    
                    
                    #else
                    let valueColor = UIColor(hexString: value)
                    let colorAttributes = [
                        .foregroundColor: valueColor,
                        .paragraphStyle: labelStyle
                    ] as [NSAttributedString.Key: Any]
                    #endif
                    
                    
                    let valueColorString = NSMutableAttributedString(string: colorString, attributes: colorAttributes)
                    thisPropertyString.append(valueColorString)
                    
                }
            } else {
                thisPropertyString.append(NSAttributedString(string: value))
            }
            
            let delineatorString = (idx == 0) ? "" : ", "
            let thisDelineatorString = delineator ?? delineatorString
            let delineatorAttributedString = NSAttributedString(string: thisDelineatorString)
            outputString.append(delineatorAttributedString)
            outputString.append(thisPropertyString)
            
        }
        
        return outputString
    }
    
    /// Returns true if the node has the given custom `SKTiled` property (case insensitive).
    ///
    /// - Parameter key: custom property key.
    public func hasKey(_ key: String) -> Bool {
        let pnames = properties.keys.map { $0.lowercased() }
        return !pnames.filter { $0 == key.lowercased()}.isEmpty
    }
    
    /// Returns a boolean value for the given key.
    ///
    /// - Parameter key: property key.
    public func boolForKey(_ key: String) -> Bool {
        if let existingPair = keyValuePair(key: key) {
            return Bool(existingPair.value) ?? false || Int(existingPair.value) == 1
        }
        return false
    }
    
    /// Returns a string for the given SKTiled key.
    ///
    /// - Parameter key: property key.
    public func stringForKey(_ key: String) -> String? {
        for k in properties.keys {
            if k.lowercased() == key.lowercased() {
                return properties[k]
            }
        }
        return properties[key]
    }
    
    /// Returns a integer value for the given key.
    ///
    /// - Parameter key: property key.
    public func intForKey(_ key: String) -> Int? {
        if let existingPair = keyValuePair(key: key) {
            return Int(existingPair.value)
        }
        return nil
    }
    
    /// Returns a float value for the given key.
    ///
    /// - Parameter key: property key.
    /// - Returns: parsed double value.
    public func doubleForKey(_ key: String) -> Double? {
        if let existingPair = keyValuePair(key: key) {
            return Double(existingPair.value)
        }
        return nil
    }
    
    /// Returns a color given a property string.
    ///
    /// - Parameter key: property key.
    /// - Returns: parsed color.
    public func colorForKey(_ key: String) -> SKColor? {
        if let existingPair = keyValuePair(key: key) {
            return SKColor(hexString: existingPair.value)
        }
        return nil
    }
    
    /// Remove a named SKTiled property, returns the value as a string (if property exists).
    ///
    /// - Parameter key: property key.
    public func removeValue(for key: String) -> String? {
        if let existingPair = keyValuePair(key: key) {
            return properties.removeValue(forKey: existingPair.key)!
        }
        return nil
    }
    
    /// Set the node's properties values, optionally overwriting current values.
    ///
    /// - Parameters:
    ///   - attrs: dictionary of properties.
    ///   - overwrite: overwrite the current value, if one exists.
    public func setProperties(_ attrs: [String: String], overwrite: Bool = false) {
        var mutableProperties = self.properties
        for (key, value) in attrs {
            let currentValue = mutableProperties[key]
            if (currentValue == nil) || (overwrite == true) {
                mutableProperties[key] = value
            }
        }
        self.properties = mutableProperties
    }
    
    // MARK: - Helpers
    
    /// Returns a case-insensitive value for the given key.
    ///
    /// - Parameter key: property key.
    internal func keyValuePair(key: String) -> (key: String, value: String)? {
        for k in properties.keys {
            if (k.lowercased() == key.lowercased()) {
                return (key: k, value: properties[k]!)
            }
        }
        return nil
    }
    
    /// Returns true if the property is a numeric type.
    ///
    /// - Parameter key: property key.
    internal func hasNumericKey(_ key: String) -> Bool {
        if let existingPair = keyValuePair(key: key) {
            return Int(existingPair.value) != nil || Double(existingPair.value) != nil
        }
        return false
    }
    
    /// Returns a string array for the given key.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - separatedBy: separator character.
    internal func stringArrayForKey(_ key: String, separatedBy: String=",") -> [String] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: separatedBy).map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
        return [String]()
    }
    
    /// Returns a integer array for the given key.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - separatedBy: separator character.
    internal func integerArrayForKey(_ key: String, separatedBy: String=",") -> [Int] {
        if let existingPair = keyValuePair(key: key) {
            return existingPair.value.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)}.compactMap {
                    Int($0)
                }
        }
        return [Int]()
    }
    
    /// Returns a double array for the given key.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - separatedBy: separator character.
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




extension TiledObjectType where Self: SKNode {
    
    /// Returns a Tiled SpriteKit node with a matching unique ID.
    ///
    /// - Parameter uuid: unique Tiled node id to match.
    /// - Returns: child `TiledObjectType` node with the given unique id.
    public func getChild(uuid: String) -> SKNode? {
        return children.filter({
            if let tiled = $0 as? TiledObjectType {
                return tiled.uuid == uuid
            }
            return false
        }).first
    }
}



// MARK: - Deprecations

extension TiledObjectType {
    
    /// Sets a named SKTiled property. Returns the value, or nil if it does not exist.
    ///
    /// - Parameters:
    ///   - key: property key.
    ///   - value: property value.
    @available(*, deprecated, renamed: "setValue(for:)")
    public func setValue(forKey key: String, _ value: String) {
        setValue(for: key, value)
    }
    
    /// Remove a named `SKTiled` property, returns the value as a string (if property exists).
    ///
    /// - Parameter key: property key.
    @available(*, deprecated, renamed: "removeValue(for:)")
    public func removeProperty(forKey key: String) -> String? {
        return removeValue(for: key)
    }
}



/// :nodoc: Typealias for v1.2 compatibility.
public typealias SKTiledObject = TiledObjectType
