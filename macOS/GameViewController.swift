//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit
import AppKit


class GameViewController: NSViewController, Loggable {

    let demoController = DemoController.default


    // debugging labels
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    @IBOutlet weak var pauseInfoLabel: NSTextField!
    @IBOutlet weak var isolatedInfoLabel: NSTextField!
    @IBOutlet weak var coordinateInfoLabel: NSTextField!

    @IBOutlet weak var graphButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!
    @IBOutlet var demoFileAttributes: NSArrayController!


    var timer = Timer()
    var loggingLevel: LoggingLevel = SKTiledLoggingLevel
    var commandBackgroundColor: NSColor = NSColor(calibratedWhite: 0.2, alpha: 0.25)

    override func viewDidLoad() {
        super.viewDidLoad()


        // Configure the view.
        let skView = self.view as! SKView

        // setup the controller
        #if DEBUG
        SKTiledLoggingLevel = .debug
        #endif
        loggingLevel = SKTiledLoggingLevel
        demoController.loggingLevel = loggingLevel
        demoController.view = skView

        guard let currentURL = demoController.currentURL else {
            log("no tilemap to load.", level: .warning)
            return
        }

        //debugInfoLabel?.isHidden = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = false
        //debugInfoLabel?.isHidden = false
        #endif

        // SpriteKit optimizations
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true
        setupDebuggingLabels()

        //set up notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindowTitle), name: NSNotification.Name(rawValue: "updateWindowTitle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIControls), name: NSNotification.Name(rawValue: "updateUIControls"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: NSNotification.Name(rawValue: "updateCommandString"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loggingLevelUpdated), name: NSNotification.Name(rawValue: "loggingLevelUpdated"), object: nil)

        // create the game scene
        demoController.loadScene(url: currentURL, usePreviousCamera: false)
    }


    override func viewDidAppear() {
        super.viewDidAppear()
    }

    /**
     Set up the debugging labels. (Mimics the text style in iOS controller).
     */
    func setupDebuggingLabels() {
        mapInfoLabel.stringValue = "Map: "
        tileInfoLabel.stringValue = "Tile: "
        propertiesInfoLabel.stringValue = "Properties:"
        cameraInfoLabel.stringValue = "--"
        debugInfoLabel.stringValue = ""
        isolatedInfoLabel.stringValue = ""
        coordinateInfoLabel.stringValue = ""

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 2, height: 1)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.75)
        shadow.shadowBlurRadius = 0.5

        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debugInfoLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
        pauseInfoLabel.shadow = shadow
        isolatedInfoLabel.shadow = shadow
        coordinateInfoLabel.shadow = shadow
    }

    /**
     Action called when `fit to view` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func fitButtonPressed(_ sender: Any) {
        self.demoController.fitSceneToView()
    }

    /**
     Action called when `show grid` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.demoController.toggleMapDemoDrawGridBounds()
    }

    /**
     Action called when `show graph` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func graphButtonPressed(_ sender: Any) {
        self.demoController.toggleMapGraphVisualization()
    }

    /**
     Action called when `show objects` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func objectsButtonPressed(_ sender: Any) {
        self.demoController.toggleMapObjectDrawing()
    }

    /**
     Action called when `next` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.demoController.loadNextScene()
    }

    // MARK: - Tracking

    // MARK: - Mouse Events

    /**
     Mouse scroll wheel event handler.

     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }

        if let currentScene = view.scene as? SKTiledScene {
            currentScene.scrollWheel(with: event)
        }
    }

    /**
     Update the window's title bar with the current scene name.

     - parameter notification: `Notification` callback.
     */
    func updateWindowTitle(notification: Notification) {
        if let wintitle = notification.userInfo!["wintitle"] {
            if let infoDictionary = Bundle.main.infoDictionary {
                if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                    self.view.window?.title = "\(bundleName): \(wintitle as! String)"
                }
            }
        }
    }

    /**
     Update the window's logging menu current value.

     - parameter notification: `Notification` callback.
     */
    func loggingLevelUpdated(notification: Notification) {
        guard let mainMenu = NSApplication.shared().mainMenu else {
            Logger.default.log("cannot access main menu.", level: .warning, symbol: nil)
            return
        }

        let appMenu = mainMenu.item(withTitle: "Demo")!
        if let loggingMenu = appMenu.submenu?.item(withTitle: "Logging") {
            if let currentMenuItem = loggingMenu.submenu?.item(withTag: 1024) {
                if let loggingLevel = notification.userInfo!["loggingLevel"] as? LoggingLevel {
                    let newMenuTitle = loggingLevel.description.capitalized
                    currentMenuItem.title = newMenuTitle
                    currentMenuItem.isEnabled = false
                }
            }
        }
    }

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` notification.
     */
    func updateDebugLabels(notification: Notification) {
        //coordinateInfoLabel.isHidden = true
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.stringValue = propertiesInfo as! String
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.stringValue = cameraInfo as! String
        }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.stringValue = pauseInfo as! String
        }

        if let isolatedInfo = notification.userInfo!["isolatedInfo"] {
            isolatedInfoLabel.stringValue = isolatedInfo as! String
        }

        if let coordinateInfo = notification.userInfo!["coordinateInfo"] {
            coordinateInfoLabel.stringValue = coordinateInfo as! String
            //coordinateInfoLabel.isHidden = false
        }
    }


    /**
     Update the the command string label.

     - parameter notification: `Notification` notification.
     */
    func updateCommandString(notification: Notification) {
        timer.invalidate()
        var duration: TimeInterval = 3.0
        if let commandString = notification.userInfo!["command"] {
            var commandFormatted = commandString as! String
            commandFormatted = "\(commandFormatted)".uppercaseFirst
            debugInfoLabel.stringValue = "▹ \(commandFormatted)"
            debugInfoLabel.backgroundColor = commandBackgroundColor
            //debugInfoLabel.drawsBackground = true
        }

        if let commandDuration = notification.userInfo!["duration"] {
            duration = commandDuration as! TimeInterval
        }

        guard (duration > 0) else { return }
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GameViewController.resetCommandLabel), userInfo: nil, repeats: true)
    }

    /**
     Reset the command string label.
     */
    func resetCommandLabel() {
        timer.invalidate()
        debugInfoLabel.setStringValue("", animated: true, interval: 0.75)
        debugInfoLabel.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.0)
    }

    /**
     Enables/disable button controls based on the current map attributes.

    - parameter notification: `Notification` notification.
     */
    func updateUIControls(notification: Notification) {
        if let hasGraphs = notification.userInfo!["hasGraphs"] {
            graphButton.isEnabled = (hasGraphs as? Bool) == true
        }

        if let hasObjects = notification.userInfo!["hasObjects"] {
            objectsButton.isEnabled = (hasObjects as? Bool) == true
        }
    }
}


extension NSTextField {
    /**
     Set the string value of the text field, with optional animated fade.

     - parameter newValue: `String` new text value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            animate(change: { self.stringValue = newValue }, interval: interval)
        } else {
            stringValue = newValue
        }
    }

    /**
     Set the attributed string value of the text field, with optional animated fade.

     - parameter newValue: `NSAttributedString` new attributed string value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setAttributedStringValue(_ newValue: NSAttributedString, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard attributedStringValue != newValue else { return }
        if animated {
            animate(change: { self.attributedStringValue = newValue }, interval: interval)
        }
        else {
            attributedStringValue = newValue
        }
    }

    /**
     Private function to animate a fade effect.

     - parameter change: `() -> ()` closure.
     - parameter interval: `TimeInterval` effect length.
     */
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = interval / 2.0
            context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = interval / 2.0
                context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
}
