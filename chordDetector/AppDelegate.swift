import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    var chordDetectorController: ChordDetectorController!
    var popover: NSPopover!
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        chordDetectorController = ChordDetectorController()
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "---"
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 150, height: 100)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(rootView: ChordDisplayView(chordDetectorController: chordDetectorController))
        
        statusBarItem.button?.action = #selector(togglePopover(_:))
        statusBarItem.button?.target = self
        
        chordDetectorController.enableTitleUpdate { [weak self] chordName in
            DispatchQueue.main.async {
                self?.statusBarItem.button?.title = chordName
            }
        }
        chordDetectorController.startMIDIMonitoring();
        
        // イベントモニターで強制的にクリック検知
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleClick(event: event)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        chordDetectorController.stopMIDIMonitoring()
    }
    
    private var floatingWindow: NSWindow?
    
    private var popoverWindow: NSWindow?
    
    func handleClick(event: NSEvent) {
        guard let button = statusBarItem.button else { return }

        let buttonFrame = button.window?.frame ?? .zero
        let mouseLocation = NSEvent.mouseLocation
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        let flippedLocation = NSPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)

        if buttonFrame.contains(flippedLocation) {
            togglePopover(nil)
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
                popoverWindow = nil
                statusBarItem.button?.title = chordDetectorController.currentChord
                chordDetectorController.enableTitleUpdate { [weak self] chordName in
                    DispatchQueue.main.async {
                        self?.statusBarItem.button?.title = chordName
                    }
                }
            } else {
                chordDetectorController.enableTitleUpdate{_ in }
                statusBarItem.button?.title = "🎹"
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
