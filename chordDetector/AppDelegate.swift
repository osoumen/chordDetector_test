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
    
    private var floatingWindow: NSWindow?
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                
                if let popoverWindow = popover.contentViewController?.view.window {
                    let screenRect = NSScreen.main?.frame ?? NSRect.zero
                    let newOrigin = NSPoint(
                        x: (screenRect.width - popoverWindow.frame.width) / 2,
                        y: screenRect.height - 150
                    )
                    popoverWindow.setFrameOrigin(newOrigin)
                }
            }
        }
    }
}
