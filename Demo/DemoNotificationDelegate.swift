//
//  DemoNotificationDelegate.swift
//  SKTiled Demo - macOS
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


@objc protocol DemoNotificationDelegate {
    
    /// Send a debugging message to the UI delegate.
    ///
    /// - Parameters:
    ///   - message: message string.
    ///   - duration: how long the message should be displayed (0 is indefinite).
    @objc func updateCommandString(_ message: String, duration: TimeInterval)
}


// MARK: - Extensions


/// :nodoc:
extension NSObject: DemoNotificationDelegate {
    
    /// Send a debugging message to the UI delegate.
    ///
    /// - Parameters:
    ///   - message: message string.
    ///   - duration: how long the message should be displayed (0 is indefinite).
    @objc func updateCommandString(_ message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            
            NotificationCenter.default.post(
                name: Notification.Name.Debug.DebuggingMessageSent,
                object: nil,
                userInfo: ["message": message, "duration": duration]
            )
        }
    }
}
