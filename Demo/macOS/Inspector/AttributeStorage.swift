//
//  AttributeStorage.swift
//  SKTiled Demo - macOS
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Cocoa


/// Manages attribute storage for display in a generic attribute editor interface.
public struct AttributeStorage {
    
    fileprivate var items: [String: Set<AnyHashable>] = [:]
    
    /// Add a value to the stack.
    ///
    /// - Parameters:
    ///   - value: attribute value.
    ///   - key: attribute key.
    /// - Returns: attribute was added sucessfully.
    @discardableResult
    public mutating func add(value: AnyHashable, for key: String) -> (inserted: Bool, memberAfterInsert: AnyHashable)? {
        if var currentValue = items[key] {
            // (Bool, AnyHashable)
            let result = currentValue.insert(value)
            items[key] = currentValue
            return result
        }
        items[key] = [value]
        return (true, value)
    }
    
    /// Add a dictionary of values to the storage.
    ///
    /// - Parameter values: key/value pairs.
    public mutating func add(values: [String: Any]) {
        for (key, value) in values {
            if let hashable = value as? AnyHashable {
                self.add(value: hashable, for: key)
            }
        }
    }
    
    /// Returns the number of attributes stored with the given key.
    ///
    /// - Parameter key: attribute key.
    /// - Returns: number of items matching the given key.
    public func valueCount(for key: String) -> Int {
        return items[key]?.count ?? 0
    }
    
    /// Returns the current value(s) for the given key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - defaultValue: default value, if the key doesn't already exist in the storage.
    /// - Returns: array of values, or `nil` if the key doesn't exist.
    public mutating func value(for key: String, defaultValue: AnyHashable? = nil) -> Set<AnyHashable>? {
        if let currentValue = items[key] {
            return currentValue
        }
        
        if let defaultValue = defaultValue {
            items[key] = [defaultValue]
        }
        
        return nil
    }
    
    /// Returns the first value for the given key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - fallback: fallback value (if there are multiple values).
    /// - Returns: the value for the given key.
    public func firstValue(key: String, fallback: String = "multiple") -> AnyHashable? {
        guard let currentValues = items[key] else {
            return nil
        }
        
        if (currentValues.count > 1) {
            return fallback
        }
        
        return currentValues.first!
    }
    
    /// Returns the first value for the given key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - fallback: fallback value (if there are multiple values).
    ///   - defaultValue: default value, if the key doesn't already exist in the storage.
    /// - Returns: the value for the given key.
    public mutating func firstValue(for key: String, fallback: String = "multiple", defaultValue: AnyHashable? = nil) -> AnyHashable? {
        guard let currentValues = items[key] else {
            if let defaultValue = defaultValue {
                add(value: defaultValue, for: key)
                return defaultValue
            }
            return nil
        }
        
        if (currentValues.count > 1) {
            return fallback
        }
        
        return currentValues.first!
    }
    
    /// Removes all of the values in storage.
    public mutating func removeAll() {
        items.removeAll()
    }
    
    /// Returns the first boolean value for the given key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - fallback: fallback value (if there are multiple values).
    /// - Returns: the value for the given key.
    public func firstBooleanValue(key: String, fallback: Bool = false) -> Bool {
        guard let currentValues = items[key] else {
            return fallback
        }
        
        guard let firstValue = currentValues.first as? Bool else {
            print("❗️type for key '\(key)' is wrong: \(currentValues.first!)")
            return fallback
        }
        
        if (currentValues.count > 1) {
            return fallback
        }
        
        return (firstValue == true) ? true : false
    }
    
    
    public init() {}
}



// MARK: - Extensions


/// Convenience extensions.
extension AttributeStorage {
    
    /// Returns the number of attributes stored.
    public var attributeCount: Int {
        return items.count
    }
    
    /// Returns the number of values stored.
    public var valueCount: Int {
        var vcount = 0
        for (_, valset) in items {
            vcount += valset.count
        }
        return vcount
    }
    
    /// Returns the first value for the key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - defaultValue: default value to insert if the key doesn't exist.
    /// - Returns: attribute value.
    public mutating func firstValue(for key: String, defaultValue: AnyHashable? = nil) -> AnyHashable? {
        return firstValue(for: key, fallback: "multiple", defaultValue: defaultValue)
    }
    
    public func dump() {
        print("\n# Attributes:")
        
        for key in items.keys.sorted() {
            if let values = items[key] {
                var valstr = ""
                for value in values {
                    valstr += "'\(value)', "
                }
                print("  - '\(key)': \(valstr)")
            }
        }
    }
}



extension AttributeStorage: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return "AttributeStorate: \(attributeCount) attributes, \(valueCount) values"
    }
    
    public var debugDescription: String {
        return "<\(description)>"
    }
}



/// :nodoc: Custom mirror for tiles.
extension AttributeStorage: CustomReflectable {
    
    /// Mirror for the attribute dictionary.
    public var customMirror: Mirror {
        return Mirror(self, children: ["attributes": items], displayStyle: .dictionary)
    }
}




// CLEANME: move this to `Demo+Extensions` module?
extension NSTextField {
    
    
    /// Allows this textfield to display the correct value depending on the number of values stored for the given key.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - attribute: attribute storage.
    internal func setStringValue(for key: String, attribute: AttributeStorage, fallback: String? = nil) {
        let valueCount = attribute.valueCount(for: key)
        let fallbackString = fallback ?? "multiple"
        let isPlaceholderString = valueCount > 1
        if let firstValue = attribute.firstValue(key: key, fallback: fallbackString) {
            if (isPlaceholderString == true) {
                placeholderString = String(describing: fallbackString)
            } else {
                stringValue = String(describing: firstValue)
            }
        } else {
            stringValue = ""
        }
    }
    
    /// Allows this textfield to display the correct value depending on the number of values stored for the given key.
    ///
    /// - Parameters:
    ///   - keys: attribute keys.
    ///   - attribute: attribute storage.
    internal func setStringValue(keys: [String], attribute: AttributeStorage, fallback: String? = nil) {
        var bestKey: String?
        for key in keys {
            if (attribute.valueCount(for: key) == 1) {
                bestKey = key
            }
        }
        
        if let keyToSearchFor = bestKey {
            self.setStringValue(for: keyToSearchFor, attribute: attribute, fallback: fallback)
        }
    }
}


extension NSButton {
    
    
    /// Set the checkbox value for this checkbox based on a stored attribute key. The fallback argument will be used in the event of multiple values being found.
    ///
    /// - Parameters:
    ///   - key: attribute key.
    ///   - attribute: attribute storage instance.
    ///   - fallback: fallback value.
    internal func setCheckState(for key: String, attribute: AttributeStorage, fallback: NSButton.StateValue = NSControl.StateValue.off) {
        let valueCount = attribute.valueCount(for: key)
        let fallbackState = fallback
        let checkState = attribute.firstBooleanValue(key: key)
        self.state = (checkState == true) ? .on : .off
    }
}
