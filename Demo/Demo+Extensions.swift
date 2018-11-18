//
//  Demo+Extensions.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden on 3/28/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//


import SpriteKit
import GameController


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



extension SKTiledDemoScene {

    /**
     Setup game controllers.
     */
    @objc public func connectControllers() {
        self.isPaused = false
        
        for controller in GCController.controllers() where controller.microGamepad != nil {
            controller.microGamepad?.valueChangedHandler = nil
            #if os(tvOS)
            log("setting up tvOS remote...", level: .info)
            #endif
            setupMicroController(controller: controller)
        }
    }

    /**
     Remove game controllers.
     */
    @objc public func disconnectControllers() {
        self.isPaused = true
    }

    /**

     Setup a tvOS remote control.

     - parameter controller: `GCController` controller instance.
     */
    public func setupMicroController(controller: GCController) {

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
        }
    }


    /**
     Setup controller notification observers.
     */
    public func setupControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connectControllers), name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectControllers), name: Notification.Name.GCControllerDidDisconnect, object: nil)
    }
}
