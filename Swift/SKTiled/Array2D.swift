//
//  Array2D.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import Foundation


public struct Array2D<T> {
    public let columns: Int
    public let rows: Int
    public var array: [T?]
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array(count: rows*columns, repeatedValue: nil)
    }
    
    public subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
    
    public var count: Int { return self.array.count }
    public var isEmpty: Bool { return array.isEmpty }
    
    public func contains<T : Equatable>(obj: T) -> Bool {
        let filtered = self.array.filter {$0 as? T == obj}
        return filtered.count > 0
    }
}




extension Array2D: SequenceType {
    public typealias Generator = AnyGenerator<T?>
    
    public func generate() -> Array2D.Generator {
        var index: Int = 0
        return AnyGenerator {
            if index < self.array.count {
                return self.array[index++]
            }
            return nil
        }
    }
}


extension Array2D: GeneratorType {
    public typealias Element = T
    mutating public func next() -> Element? { return array.removeLast() }
}


extension Array2D {
    public var description: String {
        var result = "\nArray2D: rows: \(rows), columns: \(columns)"
        for row in 0..<rows {
            var rowResult = ""
            for col in 0..<columns {
                if let obj = self[col,row] {
                    rowResult += "\(obj), "
                } else {
                    rowResult += "nil, "
                }
            }
            result += "\n\(rowResult)"
        }
        return  result
    }
}
