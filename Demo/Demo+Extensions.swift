//
//  Demo+Extensions.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden.
//
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
import GameController
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


extension Notification.Name {
    
    public struct Demo {
        public static let ReloadScene                   = Notification.Name(rawValue: "com.sktiled.notification.name.demo.reloadScene")
        public static let LoadNextScene                 = Notification.Name(rawValue: "com.sktiled.notification.name.demo.loadNextScene")
        public static let FlushScene                    = Notification.Name(rawValue: "com.sktiled.notification.name.demo.flushScene")
        public static let LoadPreviousScene             = Notification.Name(rawValue: "com.sktiled.notification.name.demo.loadPreviousScene")
        public static let UpdateDebugging               = Notification.Name(rawValue: "com.sktiled.notification.name.demo.updateDebugging")
        public static let SceneLoaded                   = Notification.Name(rawValue: "com.sktiled.notification.name.demo.sceneLoaded")
        public static let FocusObjectsChanged           = Notification.Name(rawValue: "com.sktiled.notification.name.demo.focusObjectsChanged")
        public static let WindowTitleUpdated            = Notification.Name(rawValue: "com.sktiled.notification.name.demo.windowTitleUpdated")
        public static let TileUnderCursor               = Notification.Name(rawValue: "com.sktiled.notification.name.demo.tileUnderCursor")
        public static let ObjectUnderCursor             = Notification.Name(rawValue: "com.sktiled.notification.name.demo.objectUnderCursor")
        public static let ControllerConnected           = Notification.Name(rawValue: "com.sktiled.notification.name.demo.controllerConnected")
        public static let ControllerDisconnected        = Notification.Name(rawValue: "com.sktiled.notification.name.demo.controllerDisconnected")
        
        
        
        public static let ControlInputReceived          = Notification.Name(rawValue: "com.sktiled.notification.name.demo.controlInputReceived")
    }
    
    public struct Debug {
        public static let UpdateDebugging               = Notification.Name(rawValue: "com.sktiled.notification.name.debug.updateDebugging")
        public static let CommandIssued                 = Notification.Name(rawValue: "com.sktiled.notification.name.debug.commandIssued")
        public static let TileUpdated                   = Notification.Name(rawValue: "com.sktiled.notification.name.debug.tileUpdated")
        public static let MapDebuggingChanged           = Notification.Name(rawValue: "com.sktiled.notification.name.debug.mapDebuggingChanged")
        public static let MapEffectsRenderingChanged    = Notification.Name(rawValue: "com.sktiled.notification.name.debug.mapEffectsRenderingChanged")
        public static let MapObjectVisibilityChanged    = Notification.Name(rawValue: "com.sktiled.notification.name.debug.mapObjectVisibilityChanged")
    }
}


// MARK: - Controllers



extension SKTiledDemoScene {
    
    /// Called when a controller is connected.
    ///
    ///  `GCMicroGamepad` refers to a Siri remote.
    ///  `GCExtendedGamepad` refers to a gamepad.
    @objc public func controllerDidConnect() {
        /// pause the scene
        self.isPaused = false
        
        for controller in GCController.controllers() where controller.microGamepad != nil {
            controller.microGamepad?.valueChangedHandler = nil
            controller.extendedGamepad?.valueChangedHandler = nil
            
            if (controller.isGamepad == true) {
                setupGamepadController(controller: controller)
            } else {
                setupMicroController(controller: controller)
            }
        }
    }
    
    /// Called when a controller is disconnected.
    @objc public func controllerDidDisconnect() {
        self.isPaused = true
    }
    
    
    /**
     
     Setup a gamepad controller.
     
     - parameter controller: `GCController` controller instance.
     */
    public func setupGamepadController(controller: GCController) {
        guard (controller.isGamepad == true) else {
            return
        }
        
        let movementScale: CGFloat = 10
        let zoomScale: CGFloat = 0.25

        // closure for handling controller actions
        controller.extendedGamepad?.valueChangedHandler = {
            (gamepad: GCExtendedGamepad, element: GCControllerElement) in
            
            guard let skView = self.view,
                let cameraNode = self.cameraNode else {
                return
            }

            if (gamepad.leftThumbstick == element) {
                
                let xval = gamepad.leftThumbstick.xAxis.value
                let yval = gamepad.leftThumbstick.yAxis.value
                
                
                let length = hypotf(xval, yval)
                if (length > 0.0) {
                    let inverseLength = 1 / length
                    let moveVector = float2(x: xval * inverseLength, y: yval * inverseLength)
                    
                    
                    cameraNode.position.x -= CGFloat(moveVector.x) * movementScale
                    cameraNode.position.y -= CGFloat(moveVector.y) * movementScale
                    
                    for delegate in cameraNode.delegates {
                        delegate.cameraPositionChanged?(newPosition: cameraNode.position)
                    }
                }

            } else if (gamepad.rightThumbstick == element) {
                
                let xval = gamepad.rightThumbstick.xAxis.value
                let yval = gamepad.rightThumbstick.yAxis.value
                
                
                let length = hypotf(xval, yval)
                if (length > 0.0) {
                    let inverseLength = 1 / length
                    let moveVector = float2(x: xval * inverseLength, y: yval * inverseLength)
                    
                    let newZoom = cameraNode.zoom + CGFloat(moveVector.y) * zoomScale
                    cameraNode.setCameraZoom(newZoom)
                }
                
                
            // Gamepad Buttons
                
            } else if (gamepad.buttonA == element) {
                var isPressed = false
                if (gamepad.buttonA.isPressed == true) {
                    isPressed = true
                }
                
                let pressedString = (isPressed == true) ? "pressed" : "released"
                let command = "'A' button \(pressedString)"
                
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
            
            } else if (gamepad.buttonB == element) {
                var isPressed = false
                if (gamepad.buttonB.isPressed == true) {
                    isPressed = true
                }
                
                let pressedString = (isPressed == true) ? "pressed" : "released"
                let command = "'A' button \(pressedString)"
                
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
                
            } else if (gamepad.buttonX == element) {
                var isPressed = false
                if (gamepad.buttonX.isPressed == true) {
                    isPressed = true
                }
                
                let pressedString = (isPressed == true) ? "pressed" : "released"
                let command = "'X' button \(pressedString)"
                
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
            
            } else if (gamepad.buttonY == element) {
                var isPressed = false
                if (gamepad.buttonY.isPressed == true) {
                    isPressed = true
                }
                
                let pressedString = (isPressed == true) ? "pressed" : "released"
                let command = "'Y' button \(pressedString)"
                
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
                
            
            // Gamepad Directional Pad

                
            } else if (gamepad.dpad.left == element) {

                let command = "digital input 'left'"
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
            
            } else if (gamepad.dpad.right == element) {
                
                let command = "digital input 'right'"
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
            
            } else if (gamepad.dpad.up == element) {
                
                let command = "digital input 'up'"
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
                
            } else if (gamepad.dpad.down == element) {
                
                let command = "digital input 'down'"
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.CommandIssued,
                    object: controller,
                    userInfo: ["command": command, "duration": 1]
                )
                
            }
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.ControlInputReceived,
                object: controller
            )
        }
    }
    
    
    /**
     
     Setup a Siri remote control.
     
     - parameter controller: `GCController` controller instance.
     */
    public func setupMicroController(controller: GCController) {
        guard (controller.isGamepad == false) else {
            return
        }

        // closure for handling controller actions
        controller.microGamepad?.valueChangedHandler = {
            (gamepad: GCMicroGamepad, element: GCControllerElement) in
            
            gamepad.reportsAbsoluteDpadValues = true
            gamepad.allowsRotation = true
            
            
            guard let skView = self.view,
                  let cameraNode = self.cameraNode else {
                return
            }
            
            
            // buttonX = play/pause
            if (gamepad.buttonX == element) {
                print("⭑ 'X' button pressed...")
                if (gamepad.buttonX.isPressed) {
                    let nextMode: CameraControlMode = CameraControlMode(rawValue: cameraNode.controlMode.rawValue + 1) ?? .none
                    cameraNode.controlMode = nextMode
                    
                    let command = "camera control changed: '\(nextMode)'"
                    
                    NotificationCenter.default.post(
                        name: Notification.Name.Debug.CommandIssued,
                        object: nil,
                        userInfo: ["command": command, "duration": 1]
                    )
                    
                    
                    //cameraNode.updateFocusIfNeeded()
                } else {
                    print("⭑ 'X' button released...")
                }
                
                
            } else if (gamepad.buttonA == element) {
                if (gamepad.buttonA.isPressed) {
                    print("⭑ 'A' button pressed...")
                } else {
                    print("⭑ 'A' button released...")
                }
                
            } else if (gamepad.dpad == element) {
                
                let viewSize = skView.bounds.size
                let viewWidth = viewSize.width
                let viewHeight = viewSize.width
                
                let xValue = CGFloat(gamepad.dpad.xAxis.value)
                let yValue = CGFloat(gamepad.dpad.yAxis.value)
                
                let isReleased = (abs(xValue) == 0) || (abs(yValue) == 0)
                
                if (cameraNode.controlMode == .zoom) {
                    if (isReleased == true) {
                        return
                    }
                    
                    //let currentZoom = cameraNode.zoom
                    cameraNode.setCameraZoom(cameraNode.zoom + yValue)
                }
                
                // if we're in movement mode, update the camera's position
                if (cameraNode.controlMode == .dolly) {
                    if (isReleased == true) {
                        return
                    }
                    
                    cameraNode.centerOn(scenePoint: CGPoint(x: viewWidth * xValue, y: viewHeight * yValue))
                }
            }
            
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.ControlInputReceived,
                object: controller
            )
        }
    }

    
    
    /// Watch for controller connections.
    public func setupControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect), name: Notification.Name.GCControllerDidDisconnect, object: nil)
    }
}



/// :nodoc:
extension GCController {
    
    /// Returns the controller name.
    var controllerName: String {
        return (isRemote == true) ? "Siri Remote" : "Gamepad"
    }
    
    /// Returns true if the controller is a tvOS Siri remote.
    var isRemote: Bool {
        return (extendedGamepad == nil)
    }
    
    /// Returns true if the controller is an extended game controller.
    var isGamepad: Bool {
        return (extendedGamepad != nil)
    }
    
    /// Returns the UI image name for this controller.
    var imageName: String {
        return (isRemote == true) ? "remote" : "pamepad"
    }
}




// MARK: - UIKit

#if os(iOS) || os(tvOS)

/// :nodoc:
extension UILabel {
    
    /**
     Set the string value of the text field, with optional animated fade.
     
     - parameter newValue: `String` new text value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setTextValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        if animated {
            animate(change: { self.text = newValue }, interval: interval)
        } else {
            text = newValue
        }
    }
    
    /**
     Private function to animate a fade effect.
     
     - parameter change: `() -> Void` closure.
     - parameter interval: `TimeInterval` effect length.
     */
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        let fadeDuration: TimeInterval = 0.5
        
        UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.text = ""
            self.alpha = 1.0
        }, completion: { (Bool) -> Void in
            change()
            UIView.animate(withDuration: fadeDuration, delay: interval, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.alpha = 0.0
            }, completion: nil)
        })
    }
}
#endif



// MARK: - Deprecations

extension SKTiledDemoScene {
    
    /// Called when a controller is connected.
    @available(*, deprecated, renamed: "controllerDidConnect")
    @objc public func connectControllers() {
        controllerDidConnect()
    }
    
    /// Called when a controller is disconnected.
    @available(*, deprecated, renamed: "controllerDidDisconnect")
    @objc public func disconnectControllers() {
        controllerDidDisconnect()
    }
}
