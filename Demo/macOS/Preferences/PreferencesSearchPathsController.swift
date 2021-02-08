//
//  PreferencesSearchPathsController.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

import Cocoa


class PreferencesSearchPathsController: NSViewController {
    
    @IBOutlet weak var searchPathsTableView: NSTableView!
    
    var userSearchPaths: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        searchPathsTableView.delegate = self
        searchPathsTableView.dataSource = self
        
        loadUserSearchPaths()
    }
    
    func loadUserSearchPaths() {
        let defaults = UserDefaults.shared
        
        if let assetSearchPaths = defaults.array(forKey: "TiledAssetSearchPaths") as? [String] {
            userSearchPaths = assetSearchPaths
            searchPathsTableView.reloadData()
        }
    }
    
    @IBAction func addSearchPathAction(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Add an Asset Search Path"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            
            // Pathname of the file
            let result = dialog.url
            
            
            guard let newSearchPath = result else {
                Logger.default.log("asset search path is invalid.", level: .warning, symbol: "PreferencesSearchPathsController")
                return
            }
            
            
            let assetPath = newSearchPath.path
            
            // path contains the file path e.g
            Logger.default.log("adding search path '\(assetPath)'", level: .info, symbol: "PreferencesSearchPathsController")
            
            if (userSearchPaths == nil) {
                userSearchPaths = []
            }
            
            
            if !(userSearchPaths?.contains(assetPath) ?? false) {
                userSearchPaths?.append(assetPath)
                
                // add to defaults
                let defaults = UserDefaults.shared
                
                // create the array, if need be
                let assetSearchPaths = defaults.array(forKey: "TiledAssetSearchPaths") as? [String] ?? Array<String>()
                
                Logger.default.log("adding search path '\(assetPath)'", level: .info, symbol: "PreferencesSearchPathsController")
                var mutableAssetSearchPaths = assetSearchPaths
                
                // if the value doesn't exist already, add it
                if !mutableAssetSearchPaths.contains(assetPath) {
                    mutableAssetSearchPaths.append(assetPath)
                    
                    defaults.set(mutableAssetSearchPaths, forKey: "TiledAssetSearchPaths")
                    defaults.synchronize()
  
                    // call back to the demo controller
                    NotificationCenter.default.post(
                        name: Notification.Name.DemoController.AssetSearchPathsAdded,
                        object: nil,
                        userInfo: ["urls": [newSearchPath]]
                    )
                    
                } else {
                    fatalError("path already in search paths")
                }
                
            } else {
                fatalError("path already in search paths")
            }
            
            searchPathsTableView.reloadData()            
        }
    }
    
    @IBAction func removeSearchPathAction(_ sender: Any) {
        guard let assetSearchPaths = userSearchPaths else {
            return
        }
        
        var removedPaths: [String] = []
        let selectedRowIndexes = searchPathsTableView.selectedRowIndexes
        
        for index in selectedRowIndexes {
            let pathToRemove = assetSearchPaths[index]
            removedPaths.append(pathToRemove)
        }
        
        
        NotificationCenter.default.post(
            name: Notification.Name.DemoController.AssetSearchPathsRemoved,
            object: nil,
            userInfo: ["urls": removedPaths.map {
                        URL(fileURLWithPath: $0)
            }]
        )
        
        userSearchPaths = assetSearchPaths.filter({ removedPaths.contains($0) == false })
        searchPathsTableView.reloadData()
        
        // update defaults
        let defaults = UserDefaults.shared
        defaults.set(userSearchPaths, forKey: "TiledAssetSearchPaths")
        defaults.synchronize()
    }
}


// MARK: - Extensions



extension PreferencesSearchPathsController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let item = userSearchPaths?[row] else {
            return nil
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "UserSearchPath"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = item
            //cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }
    
    /// Notification object is the table view.
    ///
    /// - Parameter notification: event notification.
    func tableViewSelectionDidChange(_ notification: Notification) {
        print(notification)
    }
}



extension PreferencesSearchPathsController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return userSearchPaths?.count ?? 0
    }
}
