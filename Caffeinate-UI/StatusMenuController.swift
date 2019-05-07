//
//  StatusMenuController.swift
//  Caffeinate-UI
//
//  Created by Jose Felix Gomez on 5/4/19.
//  Copyright © 2019 Jose Felix Gomez. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var status = "off"
    var caffeinateTask: Process!
    var duration: Int? // Selected duration. nil == forever

    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var foreverMenuItem: NSMenuItem!
    @IBOutlet weak var twoHoursMenuItem: NSMenuItem!
    
    @IBAction func foreverClicked(_ sender: Any) {
        foreverMenuItem.state = NSControl.StateValue.on
        twoHoursMenuItem.state = NSControl.StateValue.off
        duration = nil

        if status == "on" {
            toggleState(self)
            toggleState(self) // Keep the status
        }
    }
    
    @IBAction func twoHoursClicked(_ sender: Any) {
        foreverMenuItem.state = NSControl.StateValue.off
        twoHoursMenuItem.state = NSControl.StateValue.on
        duration = 2
        
        if status == "on" {
            toggleState(self)
            toggleState(self)  // Keep the status
        }
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    

    override func awakeFromNib() {
        if let button = item.button {
            button.action = #selector(statusMenuClicked(sender:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Click to toggle. Right-click for options."
        }
        
        foreverMenuItem.state = NSControl.StateValue.on
        toggleState(self)
        
        // Observers to turn Caffeinate off if the computer lid gets closed, and to show it again once awake
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(macWillSleep(sender:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(macDidWake(sender:)), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    fileprivate func setMenuIconTo(_ state:String) {
        item.button?.image = NSImage(named: "\(state)_icon_32x32")
        self.status = state
    }

    @objc fileprivate func statusMenuClicked(sender: AnyObject) {
        let event = NSApp.currentEvent!
        
        if (event.type == NSEvent.EventType.rightMouseUp) ||
            (event.modifierFlags.contains(.control)) {
            displayMenu(sender)
        } else {
            toggleState(sender)
        }
    }
    
    @objc fileprivate func macWillSleep(sender: AnyObject) {
        print("Mac will Sleep")
        if status == "on" { toggleState(self) }
    }
    
    @objc fileprivate func macDidWake(sender: AnyObject) {
        print("Mac did Wake!")
        displayMenu(self)
    }
    
    @objc fileprivate func displayMenu(_ sender: AnyObject) {
        // This method is deprecated, however it's the only way I could make right click work differently than left clicking
        item.popUpMenu(statusMenu)
}
    
    @objc fileprivate func toggleState(_ sender: AnyObject) {
        if status == "on" {
            toggleOff(sender)
        } else {
            toggleOn(sender)
        }
    }
    
    @objc func toggleOn(_ sender: AnyObject) {
        setMenuIconTo("on")
        runCaffeinateTask()
    }
    
    @objc func toggleOff(_ sender: AnyObject) {
        setMenuIconTo("off")
        terminateCaffeinateTask()
    }
    
    func terminateCaffeinateTask() {
        caffeinateTask.terminate()
    }
    
    func runCaffeinateTask() {
        caffeinateTask = Process()
        caffeinateTask.launchPath = "/usr/bin/caffeinate"
        caffeinateTask.arguments = ["-w \(ProcessInfo().processIdentifier)", "-di"]
        if self.duration != nil {
            caffeinateTask.arguments?.append("-t \(duration! * 10)")
            NotificationCenter.default.addObserver(self, selector: #selector(toggleOff(_:)), name: Process.didTerminateNotification, object: caffeinateTask)
        }

        caffeinateTask.launch()
    }
}
