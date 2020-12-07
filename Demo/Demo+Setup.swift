//
//  Demo+Setup.swift
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


extension SKTiledDemoScene {
    
    /**
     Special setup functions for various included demo content.
     
     - parameter fileNamed: `String` tiled filename.
     */
    func setupDemoLevel(fileNamed: String) {
        guard let tilemap = tilemap else { return }
        
        let baseFilename = fileNamed.components(separatedBy: "/").last!
        
        let walkableTiles = tilemap.getTilesWithProperty("walkable", true)
        let walkableTilesString = (walkableTiles.isEmpty == true) ? "" : ", \(walkableTiles.count) walkable tiles."
        log("setting up level: \"\(baseFilename)\"\(walkableTilesString)", level: .debug)
        
        switch baseFilename {
            
            case "dungeon-16x16.tmx":                
                if let upperGraphLayer = tilemap.tileLayers(named: "Graph-Upper").first {
                    _ = upperGraphLayer.initializeGraph(walkable: walkableTiles)
                }
                
                if let lowerGraphLayer = tilemap.tileLayers(named: "Graph-Lower").first {
                    _ = lowerGraphLayer.initializeGraph(walkable: walkableTiles)
                }

            case "roguelike-16x16.tmx":
                if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                    _ = graphLayer.initializeGraph(walkable: walkableTiles)
                }

            default:
                return
        }
        
        
        NotificationCenter.default.post(
            name: Notification.Name.Demo.WindowTitleUpdated,
            object: nil,
            userInfo: ["wintitle": fileNamed]
        )
    }
}
