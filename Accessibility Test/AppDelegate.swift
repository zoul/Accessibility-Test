import Cocoa
import ApplicationServices

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1) {
            self.startWatchingWindowEvents()
        }
    }

    func startWatchingWindowEvents() {

        let systemAXElement = AXUIElementCreateSystemWide()

        var applicationAXElement: CFTypeRef?
        AXUIElementCopyAttributeValue(systemAXElement, kAXFocusedApplicationAttribute as CFString, &applicationAXElement)
        assert(applicationAXElement != nil)

        var windowAXElement: CFTypeRef?
        AXUIElementCopyAttributeValue(applicationAXElement as! AXUIElement, kAXFocusedWindowAttribute as CFString, &windowAXElement)
        assert(windowAXElement != nil)

        print("Got window AX element:", windowAXElement! as Any)

        // Expected behaviour: While the window is being dragged its top left corner
        // sticks to the mouse pointer. Actual behaviour on 10.11+: the window position
        // doesn’t change, it just flickers intermittently. The actual feature in our
        // app is a bit different, this is just an example of the behaviour.
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { event in

            var newPosition = self.carbonPointFrom(cocoaPoint: NSEvent.mouseLocation())
            let positionValue = AXValueCreate(.cgPoint, &newPosition)
            AXUIElementSetAttributeValue(windowAXElement as! AXUIElement, kAXPositionAttribute as CFString, positionValue!)

            return event
        }
    }

    func carbonPointFrom(cocoaPoint: NSPoint) -> CGPoint {
        guard let menuScreen = NSScreen.screens()?.first else { fatalError() }
        let menuScreenHeight = NSMaxY(menuScreen.frame)
        return CGPoint(x: cocoaPoint.x, y: menuScreenHeight - cocoaPoint.y)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

