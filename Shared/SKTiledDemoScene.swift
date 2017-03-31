//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit
import Foundation

#if os(iOS)
import UIKit
#else
import Cocoa
#endif


public class SKTiledDemoScene: SKTiledScene {
    
    public var uiScale: CGFloat = 1
    public var debugMode: Bool = false
    
    // hud buttons
    public var buttons: [ButtonNode] = []
    public var resetButton: ButtonNode!
    public var showGridButton: ButtonNode!
    public var showObjectsButton: ButtonNode!
    public var loadNextButton:  ButtonNode!
    
    // info labels
    public var mapInformationLabel: SKLabelNode!
    public var tileInformationLabel: SKLabelNode!
    public var propertiesInformationLabel: SKLabelNode!
    
    /// global information label font size.
    private let labelFontSize: CGFloat = 11
    
    internal var selected: [TiledLayerObject] = []
    internal var editMode: Bool = false
    
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // setup demo UI
        setupDemoUI()
        setupDebuggingLabels()
        updateHud()
        
        #if os(OSX)
        updateTrackingViews()
        #endif
    }
    
    // MARK: - Setup
    /**
     Set up interface elements for this demo.
     */
    public func setupDemoUI() {
        guard let view = self.view else { return }
        guard let cameraNode = cameraNode else { return }
        
        // set up camera overlay UI
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition * 10 : 5000

        if (resetButton == nil){
            resetButton = ButtonNode(defaultImage: "scale-button-norm", highlightImage: "scale-button-pressed", action: {
                if let cameraNode = self.cameraNode {
                    cameraNode.fitToView()
                }
            })
            
            cameraNode.overlay.addChild(resetButton)
            buttons.append(resetButton)
            
            // position towards the bottom of the scene
            resetButton.position.x -= (view.bounds.size.width / 7)
            resetButton.position.y -= (view.bounds.size.height / 2.25)
            resetButton.zPosition = lastZPosition
        }
        
        if (showGridButton == nil){
            showGridButton = ButtonNode(defaultImage: "grid-button-norm", highlightImage: "grid-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                tilemap.debugDraw = !tilemap.debugDraw
            })
            
            cameraNode.overlay.addChild(showGridButton)
            buttons.append(showGridButton)
            // position towards the bottom of the scene
            showGridButton.position.y -= (view.bounds.size.height / 2.25)
            showGridButton.zPosition = lastZPosition
        }
                
        if (showObjectsButton == nil){
            showObjectsButton = ButtonNode(defaultImage: "objects-button-norm", highlightImage: "objects-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                let debugState = !tilemap.showObjects
                tilemap.showObjects = debugState
            })
            
            cameraNode.overlay.addChild(showObjectsButton)
            buttons.append(showObjectsButton)
            // position towards the bottom of the scene
            showObjectsButton.position.y -= (view.bounds.size.height / 2.25)
            showObjectsButton.zPosition = lastZPosition
            
            let hasObjects = (tilemap != nil) ? tilemap.objectGroups.count > 0 : false
            showObjectsButton.isUserInteractionEnabled = hasObjects
        }
        
        
        if (loadNextButton == nil){
            loadNextButton = ButtonNode(defaultImage: "next-button-norm", highlightImage: "next-button-pressed", action: {
                self.loadNextScene()
            })
            cameraNode.overlay.addChild(loadNextButton)
            buttons.append(loadNextButton)
            // position towards the bottom of the scene
            loadNextButton.position.x += (view.bounds.size.width / 7)
            loadNextButton.position.y -= (view.bounds.size.height / 2.25)
            loadNextButton.zPosition = lastZPosition
        }
    }
    
    /**
     Setup debugging labels.
     */
    public func setupDebuggingLabels() {
        guard self.view != nil else { return }
        guard let cameraNode = cameraNode else { return }
        var tilemapInfoY: CGFloat = 0.77
        var tileInfoY: CGFloat = 0.81
        var propertiesInfoY: CGFloat = 0.85
        
        #if os(iOS)
        tilemapInfoY = 1.0 - tilemapInfoY
        tileInfoY = 1.0 - tileInfoY
        propertiesInfoY = 1.0 - propertiesInfoY
        #endif
        
        if (mapInformationLabel == nil){
            // setup tilemap label
            mapInformationLabel = SKLabelNode(fontNamed: "Courier")
            mapInformationLabel.fontSize = labelFontSize
            mapInformationLabel.text = "Tilemap:"
            cameraNode.overlay.addChild(mapInformationLabel)
        }
        
        if (tileInformationLabel == nil){
            // setup tile information label
            tileInformationLabel = SKLabelNode(fontNamed: "Courier")
            tileInformationLabel.fontSize = labelFontSize
            tileInformationLabel.text = "Tile:"
            cameraNode.overlay.addChild(tileInformationLabel)
        }
        
        if (propertiesInformationLabel == nil){
            // setup tile information label
            propertiesInformationLabel = SKLabelNode(fontNamed: "Courier")
            propertiesInformationLabel.fontSize = labelFontSize
            propertiesInformationLabel.text = "ID:"
            cameraNode.overlay.addChild(propertiesInformationLabel)
        }
        
        mapInformationLabel.posByCanvas(x: 0.5, y: tilemapInfoY)
        tileInformationLabel.isHidden = true
        propertiesInformationLabel.isHidden = true
        tileInformationLabel.posByCanvas(x: 0.5, y: tileInfoY)
        propertiesInformationLabel.posByCanvas(x: 0.5, y: propertiesInfoY)
    }
    
    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: TimeInterval=0) -> DebugTileShape {
        // validate the coordinate
        let validCoord = layer.isValid(x, y)
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
        
        // add debug tile shape
        let tile = DebugTileShape(layer: layer, tileColor: tileColor)
        tile.zPosition = lastZosition
        tile.position = layer.pointForCoordinate(x, y)
        layer.addChild(tile)
        if (duration > 0) {
            let fadeAction = SKAction.fadeAlpha(to: 0, duration: duration)
            tile.run(fadeAction, completion: {
                tile.removeFromParent()
            })
        }
        return tile
    }
    
    // MARK: - Deinitialization
    deinit {
        // Deregister for scene updates
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadPreviousScene"), object: nil)
        removeAllActions()
        removeAllChildren()
    }
    
    /**
     Call back to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadNextScene"), object: nil)
    }
    
    public func loadPreviousScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadPreviousScene"), object: nil)
    }
    
    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        let currentScale = Int(size.width / 400)
        uiScale = CGFloat(currentScale > 1 ? currentScale : 1)
        //uiScale = pow(2, ceil(log(uiScale)/log(2)))
        
        updateHud()
        
        #if os(OSX)
        updateTrackingViews()
        #endif
    }
    
    /**
     Filters events to allow buttons to receive focus.
     
     - parameter point: `CGPoint` event position.
     - returns:  `Bool` point is valid scene point.
    */
    fileprivate func isValidPosition(point: CGPoint) -> Bool {
        let nodesUnderCursor = nodes(at: point)
        for node in nodesUnderCursor {
            if let _ = node as? ButtonNode {
                return false
            }
        }
        return true
    }

    /**
     Update HUD elements when the view size changes.
     */
    fileprivate func updateHud(){
        guard let view = self.view else { return }
        let activeButtons = buttons.filter( {$0.isHidden == false})
        guard activeButtons.count > 0 else { return }
        
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition * 10 : 5000
        
        let viewSize = view.bounds.size
        let buttonYPos: CGFloat = -(size.height * 0.4)
        
        activeButtons.forEach {$0.setScale(uiScale)}
        activeButtons.forEach {$0.zPosition = lastZPosition * 2}
        
        var tilemapInfoY: CGFloat = 0.77
        var tileInfoY: CGFloat = 0.81
        var propertiesInfoY: CGFloat = 0.85
        
        #if os(iOS)
        tilemapInfoY = 1.0 - tilemapInfoY
        tileInfoY = 1.0 - tileInfoY
        propertiesInfoY = 1.0 - propertiesInfoY
        #endif
        
        let buttonWidths = activeButtons.map { $0.size.width }
        let maxWidth = buttonWidths.reduce(0, {$0 + $1})

        let spacing = (viewSize.width - maxWidth) / CGFloat(activeButtons.count + 1)
        
        var current = spacing + (buttonWidths[0] / 2)
        for button in activeButtons {
            let buttonScenePos = CGPoint(x: current - (viewSize.width / 2), y: buttonYPos)
            button.position = buttonScenePos
            button.zPosition = lastZPosition
            current += spacing + button.size.width
        }
        
        let dynamicFontSize = labelFontSize * (size.width / 600)

        // Update information labels
        if let mapInformationLabel = mapInformationLabel {
            mapInformationLabel.fontSize = dynamicFontSize
            mapInformationLabel.zPosition = lastZPosition
            mapInformationLabel.posByCanvas(x: 0.5, y: tilemapInfoY)
            mapInformationLabel.text = tilemap?.description
        }
        
        if let tileInformationLabel = tileInformationLabel {
            tileInformationLabel.fontSize = dynamicFontSize
            tileInformationLabel.zPosition = lastZPosition
            tileInformationLabel.posByCanvas(x: 0.5, y: tileInfoY)
        }
        
        if let propertiesInformationLabel = propertiesInformationLabel {
            propertiesInformationLabel.fontSize = dynamicFontSize
            propertiesInformationLabel.zPosition = lastZPosition
            propertiesInformationLabel.posByCanvas(x: 0.5, y: propertiesInfoY)
        }
    }
    
    // MARK: - Callbacks
    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        updateHud()
    }
}



#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        for touch in touches {
            
            // make sure there are no UI objects under the mouse
            let scenePosition = touch.location(in: self)
            if !isValidPosition(point: scenePosition) { return }
            
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            
            
            let coord = baseLayer.coordinateAtTouchLocation(touch)
            // add a tile shape to the base layer where the user has clicked
            
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 5)
            
            // update the tile information label
            let coordStr = "Coord: \(coord.coordDescription), \(positionInLayer.roundTo())"
            tileInformationLabel.isHidden = false
            tileInformationLabel.text = coordStr
            
            // tile properties output
            var propertiesInfoString = ""
            if let tile = tilemap.firstTileAt(coord: coord) {
                propertiesInfoString = "Tile ID: \(tile.tileData.id)"
                if tile.tileData.propertiesString != "" {
                    propertiesInfoString += "; \(tile.tileData.propertiesString)"
                }
            }
            
            propertiesInformationLabel.isHidden = false
            propertiesInformationLabel.text = propertiesInfoString
        }
    }
}
#endif


#if os(OSX)
// Mouse-based event handling
extension SKTiledDemoScene {
        
    override open func mouseDown(with event: NSEvent) {
        guard let tilemap = tilemap else { return }
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseDown(with: event)
        
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.location(in: self)
        if !isValidPosition(point: scenePosition) { return }
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event: event)
        // get the coordinate at that position
        let coord = baseLayer.coordinateAtMouseEvent(event: event)

        if (tilemap.isPaused == false){
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(floor(coord.x)), Int(floor(coord.y)), duration: 3)
        }

        // update the tile information label
        let coordStr = "Coord: \(coord.coordDescription), \(positionInLayer.roundTo())"
        tileInformationLabel.isHidden = false
        tileInformationLabel.text = coordStr
        
        // tile properties output
        var propertiesInfoString = ""
        if let tile = tilemap.firstTileAt(coord: coord) {
            propertiesInfoString = "Tile ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
            
            if let layer = tile.layer {
                if !selected.contains(layer) {
                    selected.append(layer)
                }
            }
        }
        propertiesInformationLabel.isHidden = false
        propertiesInformationLabel.text = propertiesInfoString
    }
    
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.location(in: self)
        if !isValidPosition(point: scenePosition) { return }
        
        // get the position in the baseLayer (inverted)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.screenToTileCoords(positionInLayer)
        
        tileInformationLabel?.isHidden = false
        tileInformationLabel?.text = "Coord: \(coord.coordDescription), \(positionInLayer.roundTo())"
        
        // tile properties output
        var propertiesInfoString = ""
        if let tile = tilemap.firstTileAt(coord: coord) {
            //tile.highlightWithColor(tilemap.highlightColor)
            propertiesInfoString = "Tile ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
        }
        
        propertiesInformationLabel.isHidden = false
        propertiesInformationLabel.text = propertiesInfoString
    }
        
    override open func mouseDragged(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(event)
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseUp(with: event)
        selected = []
    }
    
    override open func scrollWheel(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scrollWheel(with: event)
    }
    
    override open func keyDown(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        
        // 'F' key fits the map to the view
        if event.keyCode == 0x03 {
            if (tilemap != nil) {
                cameraNode.fitToView()
            }
        }
        
        // 'D' shows debug view
        if event.keyCode == 0x02 {
            if let tilemap = tilemap {
                tilemap.debugDraw = !tilemap.debugDraw
            }
        }
        
        // 'O' shows objects
        if event.keyCode == 0x1F {
            if let tilemap = tilemap {
                tilemap.showObjects = !tilemap.showObjects
            }
        }
        
        // 'P' pauses the map
        if event.keyCode == 0x23 {
            self.isPaused = !self.isPaused
        }
                
        // 'G' shows the grid
        if event.keyCode == 0x05 {
            if let tilemap = tilemap {
                tilemap.debugDraw = !tilemap.debugDraw
            }
        }
        
        // 'H' hides the HUD
        if event.keyCode == 0x04 {
            let debugState = !cameraNode.showOverlay
            cameraNode.showOverlay = debugState
            
            if let view = self.view {
                view.showsFPS = debugState
                view.showsNodeCount = debugState
                view.showsDrawCount = debugState
            }
        }
        
        
        // 'A' & '1' reset the camera to 100%
        if event.keyCode == 0x12 || event.keyCode == 0x00 {
            if let tilemap = tilemap {
                cameraNode.resetCamera(toScale: tilemap.worldScale)
            } else {
                cameraNode.resetCamera()
            }
        }
        
        // '→' advances to the next scene
        if event.keyCode == 0x7C {
            self.loadNextScene()
        }
        
        // '←' advances to the next scene
        if event.keyCode == 0x7B {
            self.loadPreviousScene()
        }
        
        // 'E' toggles edit mode
        if event.keyCode == 0x0E {
            editMode = !editMode
        }
    }
    
    /**
     Remove old tracking views and add the current.
    */
    open func updateTrackingViews(){
        if let view = self.view {
            let options = [NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.activeAlways] as NSTrackingAreaOptions
            // clear out old tracking areas
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
            
            let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea)
        }
    }
}
#endif


open class ButtonNode: SKSpriteNode {
    
    open var buttonAction: () -> ()
    
    // textures
    open var selectedTexture: SKTexture!
    open var hoveredTexture: SKTexture!
    open var defaultTexture: SKTexture! {
        didSet {
            defaultTexture.filteringMode = .nearest
            self.texture = defaultTexture
        }
    }
    
    open var disabled: Bool = false {
        didSet {
            guard oldValue != disabled else { return }
            isUserInteractionEnabled = !disabled
        }
    }
    
    // actions to show highlight scaling & hover (OSX)
    fileprivate let scaleAction: SKAction = SKAction.scale(by: 0.95, duration: 0.025)
    fileprivate let hoverAction: SKAction = SKAction.colorize(with: SKColor.white, colorBlendFactor: 0.5, duration: 0.025)
    
    public init(defaultImage: String, highlightImage: String, action: @escaping () -> ()) {
        buttonAction = action
        
        defaultTexture = SKTexture(imageNamed: defaultImage)
        selectedTexture = SKTexture(imageNamed: highlightImage)
        
        defaultTexture.filteringMode = .nearest
        selectedTexture.filteringMode = .nearest
        
        super.init(texture: defaultTexture, color: SKColor.clear, size: defaultTexture.size())
        isUserInteractionEnabled = true
    }
    
    public init(texture: SKTexture, highlightTexture: SKTexture, action: @escaping () -> ()) {
        defaultTexture = texture
        selectedTexture = highlightTexture
        buttonAction = action
        
        defaultTexture.filteringMode = .nearest
        selectedTexture.filteringMode = .nearest
        
        super.init(texture: defaultTexture, color: SKColor.clear, size: texture.size())
        isUserInteractionEnabled = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        buttonAction = { _ in }
        super.init(coder: aDecoder)
    }
    
    override open var isUserInteractionEnabled: Bool {
        didSet {
            guard oldValue != isUserInteractionEnabled else { return }
            color = isUserInteractionEnabled ? SKColor.clear : SKColor.gray
            colorBlendFactor = isUserInteractionEnabled ? 0 : 0.8
        }
    }
    
    /**
     Runs the trigger action.
     */
    open func buttonTriggered() {
        if isUserInteractionEnabled {
            buttonAction()
        }
    }
    
    // swap textures when button is pressed
    open var wasPressed = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != wasPressed else { return }
            let action = wasPressed ? scaleAction : scaleAction.reversed()
            run(action)
        }
    }
    
    // swap textures when mouse hovers
    open var mouseHover = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != mouseHover else { return }
            texture = mouseHover ? selectedTexture : defaultTexture
            let action = mouseHover ? hoverAction : hoverAction.reversed()
            run(action)
        }
    }
}

#if os(iOS)
public extension ButtonNode {
    
    // MARK: - Touch Handling
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isUserInteractionEnabled {
            wasPressed = true
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        wasPressed = false
        if containsTouches(touches) {
            buttonTriggered()
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        wasPressed = false
    }
    
    /**
     Returns true if any of the touches are within the `ButtonNode` body.
     
     - parameter touches: `Set<UITouch>`
     - returns: `Bool` button was touched.
     */
    fileprivate func containsTouches(_ touches: Set<UITouch>) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        return touches.contains { touch in
            let touchPoint = touch.location(in: scene)
            let touchedNode = scene.atPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
    }
}
#endif


#if os(OSX)
extension ButtonNode {
    
    override open func mouseEntered(with event: NSEvent) {
        if isUserInteractionEnabled {
            if containsEvent(event){
                mouseHover = true
            }
        }
    }
    
    override open func mouseExited(with event: NSEvent) {
        mouseHover = false
    }
    
    override open func mouseDown(with event: NSEvent) {
        if isUserInteractionEnabled {
            wasPressed = true
        }
    }
    
    override open func mouseUp(with event: NSEvent) {
        wasPressed = false
        if containsEvent(event) {
            buttonTriggered()
        }
    }
    
    /**
     Returns true if any of the touches are within the `ButtonNode` body.
     
     - parameter touches: `Set<UITouch>`
     - returns: `Bool` button was touched.
     */
    fileprivate func containsEvent(_ event: NSEvent) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        let touchedNode = scene.atPoint(event.location(in: scene))
        return touchedNode === self || touchedNode.inParentHierarchy(self)
    }
}
#endif

