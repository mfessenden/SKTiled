//
//  Demo+Controllers.swift
//  SKTiled
//
//  Copyright © 2021 Michael Fessenden. all rights reserved.
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

import SpriteKit
import GameController


// MARK: - Controllers

extension SKTiledDemoScene {
    
    /// Setup game controllers when a controller is connected. Called when the `Notification.Name.GCControllerDidConnect` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc public func connectControllers(notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }
        
        self.isPaused = false
        
        if (controller.isGamepad == true) {
            setupGamepadController(controller: controller)
        } else {
            setupMicroController(controller: controller)
        }
    }
    
    /// Remove game controllers. Called when the `Notification.Name.GCControllerDidDisconnect` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc public func disconnectControllers(notification: Notification) {
        self.isPaused = true
    }
    
    /// Setup a tvOS remote control.
    ///
    /// - Parameter controller: controller instance.
    public func setupMicroController(controller: GCController) {
        guard let skView = self.view,
              let cameraNode = self.cameraNode else {
            return
        }
        
        log("setting up tvOS remote...", level: .info)
        
        controller.microGamepad?.valueChangedHandler = nil
        
        // closure for handling controller actions
        controller.microGamepad?.valueChangedHandler = {
            (gamepad: GCMicroGamepad, element: GCControllerElement) in
            
            gamepad.reportsAbsoluteDpadValues = true
            gamepad.allowsRotation = true
            
            // buttonX = play/pause
            if ( gamepad.buttonX == element) {
                if (gamepad.buttonX.isPressed) {
                    let nextMode: CameraControlMode = CameraControlMode(rawValue: cameraNode.controlMode.rawValue + 1) ?? .none
                    cameraNode.controlMode = nextMode
                }
                
            } else if (gamepad.dpad == element) {
                
                let viewSize = skView.bounds.size
                let viewWidth = viewSize.width
                let viewHeight = viewSize.width
                
                let xValue = CGFloat(gamepad.dpad.xAxis.value)
                let yValue = CGFloat(gamepad.dpad.yAxis.value)
                
                let maxValue: CGFloat = max(xValue, yValue)
                
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
                    
                    let currentPosition = cameraNode.position
                    
                    //cameraNode.centerOn(scenePoint: CGPoint(x: viewWidth * xValue, y: viewHeight * yValue))
                    cameraNode.moveCamera(location: CGPoint(x: viewWidth * xValue, y: viewHeight * yValue), previous: currentPosition)
                }
                
                
                if (cameraNode.controlMode == .rotate) {
                    if (isReleased == true) {
                        return
                    }
                    
                    //let currentZoom = cameraNode.zoom
                    cameraNode.rotation += maxValue
                }
            }
        }
    }
    
    
    /// Setup an extended gamepad controller.
    ///
    /// - Parameter controller: controller instance.
    public func setupGamepadController(controller: GCController) {
        guard let skView = self.view,
              let cameraNode = self.cameraNode else {
            return
        }
        
        log("setting up Gamepad...", level: .info)
        
        
    }
    
    /// Setup controller notification observers.
    public func setupControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connectControllers), name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectControllers), name: Notification.Name.GCControllerDidDisconnect, object: nil)
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
        return (extendedGamepad == nil) && (microGamepad != nil)
    }
    
    /// Returns true if the controller is an extended game controller.
    var isGamepad: Bool {
        return (extendedGamepad != nil) && (microGamepad != nil)
    }
    
    /// Returns the UI image name for this controller.
    var imageName: String {
        return (isRemote == true) ? "remote" : "pamepad"
    }
}
