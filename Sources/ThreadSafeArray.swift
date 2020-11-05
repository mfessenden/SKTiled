//
//  ThreadSafeArray.swift
//  SKTiled
//
//  Created by Michael Fessenden.
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

import Foundation


/// Thread-safe storage container.
internal class ThreadSafeArray<Element>: Equatable {

    fileprivate let uuid = UUID().uuidString
    fileprivate let queue: DispatchQueue
    
    internal var array: [Element] = []

    init(queue: DispatchQueue? = nil) {
        self.queue = (queue == nil) ? DispatchQueue(label: "com.sktiled.storageQueue", attributes: .concurrent) : queue!
    }

    /// Number of elements in the array.
    var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }

    /// A Boolean value indicating whether the collection is empty.
    var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }

    /**

     Returns a boolean indicating the array contains the given element.

     - Parameters:
       - predicate: `(Element) -> Bool` conditional expression.
       - returns: `Bool` array contains the given element.
     */
    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(where: predicate) }
        return result
    }

    /**

     Append a new element to the end of the array.

     - Parameters:
       - element: `Element` element to append.
     */
    func append( _ element: Element) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }

    /**

     Adds new elements to the array.

     - Parameters:
       - elements: `[Element]` array of elements to append.
    */
    func append(contentsOf elements: [Element]) {
        queue.async(flags: .barrier) {
            self.array += elements
        }
    }

    /**

     Insert a new element at the specified position.

     - Parameters:
       - element: `Element` array of elements to append.
       - index:   `Int` index to insert at.
     */
    func insert( _ element: Element, at index: Int) {
        queue.async(flags: .barrier) {
            self.array.insert(element, at: index)
        }
    }

    /// Removes and returns the element at the specified position.
    func remove(at index: Int, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let element = self.array.remove(at: index)

            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }

    /**

     Removes and returns the element at the specified position.

     - Parameters:
       - predicate:  `(Element) -> Bool` conditional expression.
       - completion: `([Element]) -> Void)?` optional completion closure.
     */
    func remove(where predicate: @escaping (Element) -> Bool, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            guard let index = self.array.firstIndex(where: predicate) else {
                return
            }
            let element = self.array.remove(at: index)

            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }

    /**

     Removes all elements from the array.

     - Parameters:
       - completion: `([Element]) -> Void)?` optional completion closure.
     */
    func removeAll(completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let elements = self.array
            self.array.removeAll()

            DispatchQueue.main.async {
                completion?(elements)
            }
        }
    }


    /// Accesses the element at the specified position if it exists.
    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            queue.sync {
                guard self.array.startIndex..<self.array.endIndex ~= index else { return }
                result = self.array[index]
            }
            return result
        }
        set {
            guard let newValue = newValue else { return }
            queue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
    }
}



// MARK: - Extensions



extension ThreadSafeArray: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: ThreadSafeArray<Element>, rhs: ThreadSafeArray<Element>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}



// Allows the cache array to act as a collection.
extension ThreadSafeArray: Sequence {

    internal func makeIterator() -> AnyIterator<Element> {
        var arrayIndex = 0
        return AnyIterator {
            if arrayIndex < self.count {
                let element = self[arrayIndex]
                arrayIndex+=1
                return element
            } else {
                arrayIndex = 0
                return nil
            }
        }
    }
}


extension ThreadSafeArray where Element: Equatable {
    /**

     Returns a boolean indicating the array contains the given element.

     - Parameters:
     - element: `Element -> Bool` element to query.
     - returns: `Bool` array contains the given element.
     */
    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(element) }
        return result
    }
}


extension ThreadSafeArray {

    func filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        queue.sync { result = self.array.filter(isIncluded) }
        return result
    }

    /// Returns the first index in which an element of the collection satisfies the given predicate.
    func index(where predicate: (Element) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.array.firstIndex(where: predicate) }
        return result
    }

    /// Returns the elements of the collection, sorted using the given predicate as the comparison between elements.
    func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        var result: [Element] = []
        queue.sync { result = self.array.sorted(by: areInIncreasingOrder) }
        return result
    }

    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    func compactMap<Elements>(_ transform: (Element) -> Elements?) -> [Elements] {
        var result: [Elements] = []
        queue.sync { result = self.array.compactMap(transform) }
        return result
    }

    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.array.forEach(body) }
    }
}


extension ThreadSafeArray: CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of the array and its elements.
    var description: String {
        var result = ""
        queue.sync { result = self.array.description }
        return result
    }

    var debugDescription: String {
        return description
    }
}
