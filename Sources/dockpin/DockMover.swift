import AppKit
import DockpinCore

/// Brings the Dock to a display. macOS has no API for this, so do what a person
/// does: run the cursor into that display's Dock edge, then put it back.
enum DockMover {
    /// Blocks for about half a second; call off the main thread.
    static func push(_ trigger: DockTrigger, guard edgeGuard: EdgeGuard) {
        let home = CGEvent(source: nil)?.location
        let source = CGEventSource(stateID: .hidSystemState)
        edgeGuard.update { $0.relocating = true }
        DispatchQueue.main.sync { NSCursor.hide() }
        defer {
            if let home {
                CGWarpMouseCursorPosition(home)
                // A warp posts no event, so the Dock would keep its icons magnified
                // as if the pointer were still on it. Tell it where the pointer is.
                if let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                                       mouseCursorPosition: home, mouseButton: .left) {
                    event.setIntegerValueField(.eventSourceUserData, value: EdgeGuard.syntheticMarker)
                    event.post(tap: .cghidEventTap)
                }
            }
            // Reconnect the pointer to the mouse at once instead of after the warp's pause.
            CGAssociateMouseAndMouseCursorPosition(1)
            edgeGuard.update { $0.relocating = false }
            DispatchQueue.main.sync { NSCursor.unhide() }
        }

        func move(to point: CGPoint) {
            CGWarpMouseCursorPosition(point)
            guard let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                                      mouseCursorPosition: point, mouseButton: .left) else { return }
            event.setIntegerValueField(.eventSourceUserData, value: EdgeGuard.syntheticMarker)
            event.post(tap: .cghidEventTap)
        }

        CGWarpMouseCursorPosition(trigger.start)
        Thread.sleep(forTimeInterval: 0.03)
        let steps = 8
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            move(to: CGPoint(x: trigger.start.x + (trigger.end.x - trigger.start.x) * t,
                             y: trigger.start.y + (trigger.end.y - trigger.start.y) * t))
            Thread.sleep(forTimeInterval: 0.015)
        }
        // Keep pressing against the edge; this is what the Dock waits for.
        for _ in 0..<10 {
            move(to: trigger.end)
            Thread.sleep(forTimeInterval: 0.025)
        }
    }
}
