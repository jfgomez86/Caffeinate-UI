//
//  StatusMenuController.swift
//  Caffeinate-UI
//
//  Created by Jose Felix Gomez on 5/4/19.
//  Copyright © 2019 Jose Felix Gomez. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    let item : NSStatusItem? = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var status = "off"
    var caffeinateTask: Process!

    override func awakeFromNib() {
        if let button = item?.button {
            button.action = #selector(statusMenuClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Click to toggle. Right-click for options."
        }
        toggleState(self)
    }
    
    fileprivate func setMenuIconTo(_ state:String) {
        item?.button?.image = NSImage(named: "\(state)_icon_32x32")
        self.status = state
    }

    @objc fileprivate func statusMenuClicked(_ sender: AnyObject) {
        let event = NSApp.currentEvent!
        
        if (event.type == NSEvent.EventType.rightMouseUp) ||
            (event.modifierFlags.contains(.control)) {
            displayMenu(sender)
        } else {
            toggleState(sender)
        }
    }
    
    @objc fileprivate func displayMenu(_ sender: AnyObject) {
        statusMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc fileprivate func toggleState(_ sender: AnyObject) {
        if status == "on" {
            setMenuIconTo("off")
            terminateCaffeinateTask()
        } else {
            setMenuIconTo("on")
            runCaffeinateTask()
        }
    }
    
    func terminateCaffeinateTask() {
        caffeinateTask.terminate()
    }
    
    func runCaffeinateTask() {
        caffeinateTask = Process()
        caffeinateTask.launchPath = "/usr/bin/caffeinate"
        caffeinateTask.arguments = ["-w \(ProcessInfo().processIdentifier)"]
        caffeinateTask.launch()
    }
}
