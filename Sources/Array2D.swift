//
//  Array2D.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

import Foundation


/// Two-dimensional array structure.
struct Array2D<T> {
    
    /// Vertical count.
    let columns: Int
    
    /// Horizontal count.
    let rows: Int
    
    /// Internal array of values.
    fileprivate var items: [T?]
    
    /// Instantiate with row & column values.
    ///
    /// - Parameters:
    ///   - columns: column count.
    ///   - rows: row count.
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        items = Array(repeating: nil, count: rows*columns)
    }
    
    /// Returns the size of the array.
    var count: Int {
        return self.items.count
    }
    
    /// Returns true if the array is empty.
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    /// Returns true if the array contains the given object.
    ///
    /// - Parameter obj: node.
    /// - Returns: array contains the given node.
    func contains<T : Equatable>(_ obj: T) -> Bool {
        let filtered = self.items.filter {$0 as? T == obj}
        return filtered.isEmpty == false
    }
    
    /// Empty the array.
    mutating func removeAll() {
        items.removeAll()
    }
}



// MARK: - Extensions

extension Array2D {
    

}



extension Array2D: Sequence {
    
    /// Enumerate the array.
    ///
    /// - Returns: array iterator.
    internal func makeIterator() -> AnyIterator<T?> {
        var arrayIndex = 0
        return AnyIterator {
            if arrayIndex < self.count {
                let element = self.items[arrayIndex]
                arrayIndex+=1
                return element
            } else {
                arrayIndex = 0
                return nil
            }
        }
    }
    
    /// Subscript the array with row & column.
    subscript(column: Int, row: Int) -> T? {
        get {
            return items[row*columns + column]
        }
        set {
            items[row*columns + column] = newValue
        }
    }
    
    /// Subscript the array with row & column.
    subscript(column: Int32, row: Int32) -> T? {
        get {
            return items[Int(row)*columns + Int(column)]
        }
        set {
            items[Int(row)*columns + Int(column)] = newValue
        }
    }
}


/// :nodoc:
extension Array2D: CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible {
    
    /// A textual representation of the array.
    var description: String {
        let array = items.compactMap { $0 }
        return "Array2D: \(array.count) items"
    }
    
    /// A textual representation of the array, used for debugging.
    var debugDescription: String {
        return "<\(description)>"
    }
    
    /// Returns a custom mirror of the array.
    var customMirror: Mirror {
        var rowdata: [String] = []
        let colSize = 4
        
        for r in 0..<rows {
            var rowResult: String = ""
            
            for c in 0..<columns {
                let comma: String = (c < columns - 1) ? ", " : ""
                
                if let value = self[c, r] {
                    if let tile = value as? SKTile {                        
                        let gid = tile.tileData.globalID   // was `id`
                        let gidString = "\(gid)".padEven(toLength: colSize, withPad: " ")
                        rowResult += "\(gidString)\(comma)"
                    } else {
                        rowResult += "\(value)\(comma)"
                    }
                } else {
                    let nilData = String(repeating: "-", count: colSize)
                    rowResult += "\(nilData)\(comma)"
                }
            }
            rowdata.append(rowResult)
        }
        
        return Mirror(self, children: KeyValuePairs<String, Any>(dictionaryLiteral: ("columns", columns), ("rows", rowdata)))
    }
}
