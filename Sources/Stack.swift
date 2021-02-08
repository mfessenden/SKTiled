//
//  Stack.swift
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


/// Simple stack structure.
struct Stack<T> {
    
    /// Internal array of items.
    fileprivate var items: [T] = []
    
    /// Indicates the stack is empty.
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    /// Returns the number of items stored in the stack.
    var count: Int {
        return items.count
    }
    
    /// Push a new item onto the stack.
    ///
    /// - Parameter item: stack item.
    mutating func push(_ item: T) {
        items.append(item)
    }
    
    /// Remove the last item added.
    ///
    /// - Returns: stack item.
    mutating func pop() -> T? {
        return items.popLast()
    }
    
    /// Clear the items in the stack.
    mutating func removeAll() {
        items.removeAll(keepingCapacity: false)
    }
    
    /// Returns the last element added, but does not remove it.
    ///
    /// - Returns: stack item.
    mutating func top() -> T? {
        return items.last
    }
}


// MARK: - Extensions


extension Stack: Sequence {
    
    /// Iterate the stack items.
    ///
    /// - Returns: iterator.
    public func makeIterator() -> AnyIterator<T> {
        var curr = self
        return AnyIterator {
            return curr.pop()
        }
    }
}
