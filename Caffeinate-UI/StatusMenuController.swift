//
//  StatusMenuController.swift
//  Caffeinate-UI
//
//  Created by Jose Felix Gomez on 5/4/19.
//  Copyright © 2019 Jose Felix Gomez. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    
    // MARK: Attributes and Outlets
 
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var status = CaffeinateStatus.off
    var caffeinateTask: Process!
    var duration: Int? // Selected duration. nil == forever
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var foreverMenuItem: NSMenuItem!
    @IBOutlet weak var oneHourMenuItem: NSMenuItem!
    @IBOutlet weak var twoHoursMenuItem: NSMenuItem!
    @IBOutlet weak var fiveHoursMenuItem: NSMenuItem!
    
    // MARK: Event Bindings
    @IBAction func foreverClicked(_ sender: Any) {
        setTimeTo(nil)
    }
    
    @IBAction func oneHourClicked(_ sender: Any) {
        setTimeTo(1.hour)
    }
    
    @IBAction func twoHoursClicked(_ sender: Any) {
        setTimeTo(2.hours)
    }
    
    @IBAction func fiveHoursClicked(_ sender: Any) {
        setTimeTo(5.hours)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    @objc func statusMenuClicked(sender: AnyObject) {
        let event = NSApp.currentEvent!
        
        if (event.type == NSEvent.EventType.rightMouseUp) ||
            (event.modifierFlags.contains(.control)) {
            displayMenu()
        } else {
            toggleState()
        }
    }
    
    @objc func macWillSleep(_ notification: NSNotification) {
        if status == .on { toggleState() }
    }
    
    @objc func macDidWake(_ notification: NSNotification) {
        displayMenu()
    }
    
    override func awakeFromNib() {
        // Setup bindings
        if let button = item.button {
            button.action = #selector(statusMenuClicked(sender:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Click to toggle. Right-click for options."
        }
        
        // Observers to turn Caffeinate off if the computer lid gets closed, and to show it again once awake
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(macWillSleep(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(macDidWake(_:)), name: NSWorkspace.didWakeNotification, object: nil)
        
        setTimeTo(nil)
    }
    
    @objc func caffeinateTaskDidTerminate(_ notification: NSNotification) {
        toggleOff()
    }
    
    // MARK: Actions
    @objc func displayMenu() {
        // This method is deprecated, however it's the only way I could make right click work differently than left clicking
        item.popUpMenu(statusMenu)
    }
    
    func setMenuIconTo(_ state:CaffeinateStatus) {
        item.button?.image = NSImage(named: "\(state)_icon_32x32")
    }

    // Turns on and sets the time to the specified duration. If duration is nil, then it's turned on forever.
    func setTimeTo(_ duration: Int?) {
        self.duration = duration
        
        updateMenuItems()
        
        switch status {
        case .on:
            toggleOff()
            toggleOn()
        case .off:
            toggleOn()
        }
    }

    func updateMenuItems() {
        switch duration {
        case 1.hour:
            foreverMenuItem.state = NSControl.StateValue.off
            oneHourMenuItem.state = NSControl.StateValue.on
            twoHoursMenuItem.state = NSControl.StateValue.off
            fiveHoursMenuItem.state = NSControl.StateValue.off
        case 2.hours:
            foreverMenuItem.state = NSControl.StateValue.off
            oneHourMenuItem.state = NSControl.StateValue.off
            twoHoursMenuItem.state = NSControl.StateValue.on
            fiveHoursMenuItem.state = NSControl.StateValue.off
        case 5.hours:
            foreverMenuItem.state = NSControl.StateValue.off
            oneHourMenuItem.state = NSControl.StateValue.off
            twoHoursMenuItem.state = NSControl.StateValue.off
            fiveHoursMenuItem.state = NSControl.StateValue.on
        default:
            foreverMenuItem.state = NSControl.StateValue.on
            oneHourMenuItem.state = NSControl.StateValue.off
            twoHoursMenuItem.state = NSControl.StateValue.off
            fiveHoursMenuItem.state = NSControl.StateValue.off
        }
    }
    
    @objc func toggleState() {
        switch status {
        case .on:
            toggleOff()
        case .off:
            toggleOn()
        }
    }
    
    @objc func toggleOn() {
        status = .on
        setMenuIconTo(.on)
        runCaffeinateTask()
    }
    
    @objc func toggleOff() {
        status = .off
        setMenuIconTo(.off)
        NotificationCenter.default.removeObserver(self, name: Process.didTerminateNotification, object: caffeinateTask)
        terminateCaffeinateTask()
    }

    func runCaffeinateTask() {
        caffeinateTask = Process()
        caffeinateTask.launchPath = "/usr/bin/caffeinate"
        caffeinateTask.arguments = ["-w \(ProcessInfo().processIdentifier)", "-di"]
        if duration != nil {
            caffeinateTask.arguments?.append("-t \(duration!)")
            NotificationCenter.default.addObserver(self, selector: #selector(caffeinateTaskDidTerminate(_:)), name: Process.didTerminateNotification, object: caffeinateTask)
        }

        caffeinateTask.launch()
    }
    
    func terminateCaffeinateTask() {
        caffeinateTask.terminate()
    }
}
