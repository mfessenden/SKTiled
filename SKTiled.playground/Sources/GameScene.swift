import Foundation
import SpriteKit
import SKTiled
import PlaygroundSupport


public class GameScene: SKScene, SKTilemapDelegate {
    
    public var tmxFilename: String
    public var tilemap: SKTilemap!
    
    public init(size: CGSize, tmxFile: String) {
        tmxFilename = tmxFile
        super.init(size: size)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMove(to view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: tmxFilename, delegate: self) {
            self.tilemap = tilemap
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
        }
    }
    
    public func didRenderMap(_ tilemap: SKTilemap) {
        print("# tilemap rendered: (\(tilemap.tileCount) tiles)")
    }
}
