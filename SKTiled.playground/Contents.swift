#if os(iOS)
import UIKit
let viewSize = CGSize(width: 375, height: 667)
#else
import Cocoa
let viewSize = CGSize(width: 600, height: 450)
#endif
import SKTiled
import PlaygroundSupport
import SpriteKit


PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true


var viewRect = CGRect(x: 0, y:0, width: viewSize.width, height: viewSize.height)

// create a view
let view = SKView(frame: viewRect)
view.ignoresSiblingOrder = true

// create a scene
let tmxFilename = "zelda1"
var scene = GameScene(size: viewSize, tmxFile: tmxFilename)


// display the scene
view.showsNodeCount = true
view.showsDrawCount = true
view.showsPhysics = true
view.presentScene(scene)


PlaygroundSupport.PlaygroundPage.current.liveView = view
let tilemap = scene.tilemap!
