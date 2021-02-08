//
//  Logging.swift
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

import Foundation


/// :nodoc: Loggable object protcol.
public protocol Loggable {
    
    /// The name of the object calling the logger.
    var logSymbol: String { get }
    
    /// Log funtion.
    ///
    /// - Parameters:
    ///   - message: message to log.
    ///   - level: severity level.
    ///   - file: originating module.
    ///   - method: caller method.
    ///   - line: caller source code line.
    func log(_ message: String, level: LoggingLevel, file: String, method: String, line: UInt) -> LogEvent
}



/// :nodoc:
public struct LogEvent: Hashable {
    public let date = Date()
    public var message: String
    public var severity: LoggingLevel
    public var symbol: String?
    
    
    public let file: String     = #file
    public let function: String = #function
    public let line: UInt       = #line
    public let column: UInt     = #column
    
    internal var rawString: String?
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - message: logging message.
    ///   - level: logging severity.
    ///   - caller: caller symbol.
    public init(_ message: String,
         level: LoggingLevel = LoggingLevel.info,
         caller: String? = nil) {
        
        self.message = message
        self.severity = level
        self.symbol = caller
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(file)
        hasher.combine(file)
    }
}


/// :nodoc: Logging level.
public enum LoggingLevel: UInt8 {
    case none
    case custom
    case fatal
    case error
    case warning
    case success
    case status
    case info
    case debug
}


/// Simple logging class.
internal class Logger {

    internal enum DateFormat {
        case none
        case short
        case long
    }

    /// Current user location
    internal var locale = Locale.current

    /// Preferred date format
    internal var dateFormat: DateFormat = DateFormat.none

    /// Default singleton instance.
    internal static let `default` = Logger()

    /// Default logging level.
    internal var loggingLevel: LoggingLevel = LoggingLevel.info

    /// Print a formatted log message to output.
    ///
    /// - Parameters:
    ///   - message: message to log.
    ///   - level: severity level.
    ///   - symbol: message sender name.
    ///   - file: originating module.
    ///   - method: caller method.
    ///   - line: reference to originating module line.
    @discardableResult
    func log(_ message: String,
             level: LoggingLevel = LoggingLevel.info,
             symbol: String? = nil,
             file: String = #file,
             method: String = #function,
             line: UInt = #line) -> LogEvent {

        var event = LogEvent(message, level: level, caller: symbol)
        
        // filter events at the current logging level (or higher)
        if (self.loggingLevel.rawValue > LoggingLevel.none.rawValue) && (level.rawValue <= self.loggingLevel.rawValue) {
            // format the message
            let formattedMessage = formatMessage(message, level: level,
                                                 symbol: symbol, file: file,
                                                 method: method, line: line)
            
            
            
            event.rawString = formattedMessage
            performInMain {
                let outputStream = (self.loggingLevel.rawValue < 3) ? stderr : stdout
                fputs("\(formattedMessage)\n", outputStream)
            }
        }
        return event
    }

    /// Formatted time stamp
    private var timeStamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = locale
        formatter.dateFormat = dateFormat.dateFormatString
        let dateStamp = formatter.string(from: Date())
        return "[" + dateStamp + "]"
    }

    /// Logger message formatter.
    ///
    /// - Parameters:
    ///   - message: message to log.
    ///   - level: severity level.
    ///   - symbol: message sender name.
    ///   - file: originating module.
    ///   - method: caller method.
    ///   - line: reference to originating module line.
    /// - Returns: formatted log string.
    private func formatMessage(_ message: String,
                               level: LoggingLevel = LoggingLevel.info,
                               symbol: String? = nil,
                               file: String = #file,
                               method: String = #function,
                               line: UInt = #line) -> String {

        // shorten file name
        let filename = URL(fileURLWithPath: file).lastPathComponent


        if (level == LoggingLevel.custom) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "➤ \(formatted)"
        }

        if (level == LoggingLevel.status) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "⭑ \(formatted)"
        }

        if (level == LoggingLevel.success) {
            return "\n ✽ Success! \(message)"
        }


        // result string
        var result: [String] = (dateFormat == DateFormat.none) ? [] : [timeStamp]

        result += (symbol == nil) ? [filename] : ["[" + symbol! + "]"]
        result += [String(describing: level), message]
        return result.joined(separator: ": ")
    }
}


/// Perform the given function in the main thread.
///
/// - Parameter action: closure.
internal func performInMain(_ action: @escaping () -> Void) {
    if (Thread.isMainThread == true) {
        action()
    } else {
        DispatchQueue.main.async(execute: action)
    }
}



/// Methods for all loggable objects.
extension Loggable {

    /// Returns a string description of the object.
    public var logSymbol: String {
        return String(describing: type(of: self))
    }

    /// Default logging method.
    ///
    /// - Parameters:
    ///   - message: message to log.
    ///   - level: severity level.
    ///   - file: originating module.
    ///   - method: the caller method.
    ///   - line: the caller source code line.
    @discardableResult
    public func log(_ message: String,
                    level: LoggingLevel,
                    file: String = #file,
                    method: String = #function,
                    line: UInt = #line) -> LogEvent {

        return Logger.default.log(message, level: level, symbol: self.logSymbol, file: file, method: method, line: line)
    }

    /// Logging call with an optional, custom symbol.
    ///
    /// - Parameters:
    ///   - message: message to log.
    ///   - level: severity level.
    ///   - file: originating module.
    ///   - method: the caller method.
    ///   - line: the caller source code line.
    @discardableResult
    func log(_ message: String,
             level: LoggingLevel,
             symbol: String? = nil) -> LogEvent {

        Logger.default.log(message, level: level, symbol: self.logSymbol, file: #file, method: #function, line: #line)
    }
}


extension Logger.DateFormat {


    /// The date format string associated with the locale.
    internal var dateFormatString: String {
        switch self {
            case .long:
                return "yyyy-MM-dd HH:mm:ss"
            default:
                return "HH:mm:ss"
        }
    }
}


extension LoggingLevel: Comparable {
    public static func < (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func == (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


/// :nodoc:
extension LoggingLevel: CustomStringConvertible {

    /// String representation of logging level.
    public var description: String {
        switch self {
            case .none: return "none"
            case .custom: return "CUSTOM"
            case .fatal: return "FATAL"
            case .error: return "ERROR"
            case .warning: return "WARNING"
            case .success: return "SUCCESS"
            case .status: return "STATUS"
            case .info: return "INFO"
            case .debug: return "DEBUG"
        }
    }

    /// Array of all options.
    public static let all: [LoggingLevel] = [.none, .fatal, .error, .warning, .success, .info, .debug, .custom]
}


// MARK: - Extensions

extension SKTilemap: Loggable {}
extension TiledLayerObject: Loggable {}
extension SKTileset: Loggable {}
extension SKTilemapParser: Loggable {}
extension TiledDebugDrawNode: Loggable {}
extension SKTileObject: Loggable {}
/// :nodoc:
extension SKTile: Loggable {}
extension SKTiledScene: Loggable {}
extension SKTiledSceneCamera: Loggable {}
