import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    var chordDetectorController: ChordDetectorController!
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        chordDetectorController = ChordDetectorController()
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "---"
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 150, height: 100)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ChordDisplayView(chordDetectorController: chordDetectorController))
        
        statusBarItem.button?.action = #selector(togglePopover(_:))
        statusBarItem.button?.target = self
        
        chordDetectorController.startMIDIMonitoring { [weak self] chordName in
            DispatchQueue.main.async {
                self?.statusBarItem.button?.title = chordName
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        chordDetectorController.stopMIDIMonitoring()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                let buttonRect = button.window?.convertToScreen(button.frame) ?? NSRect.zero
                let screenRect = NSScreen.main?.frame ?? NSRect.zero
                let popoverRect = NSRect(x: buttonRect.midX - 75, y: screenRect.height - 120, width: 150, height: 100)
                popover.show(relativeTo: popoverRect, of: button.window?.contentView ?? button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
