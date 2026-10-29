import CoreGraphics
import DockpinCore
import Foundation
import os

/// Swallows mouse-moved (and dragged) events inside the guard bands, so the Dock
/// never sees the cursor pushing against another display's edge. The pointer itself still moves;
/// only the event that would wake the Dock is dropped.
///
/// The tap runs on its own thread so a busy main thread can never stall the mouse.
final class EdgeGuard: @unchecked Sendable {
    struct Config: Sendable {
        var layout: GuardLayout = .empty
        var enabled = true
        var optionBypass = true
        /// While dockpin itself walks the cursor to the Dock edge, hand movement is held back.
        var relocating = false
    }

    /// Marks the events dockpin posts itself, so the tap lets them through.
    static let syntheticMarker: Int64 = 0x646F_636B_7069_6E  // "dockpin"

    private let config = OSAllocatedUnfairLock(initialState: Config())
    private let bypassedAt = OSAllocatedUnfairLock<Date?>(initialState: nil)
    private var tap: CFMachPort?
    private var thread: Thread?

    var isRunning: Bool { tap != nil }

    /// Last time an event in a guard band went through because Option was held.
    var lastBypass: Date? { bypassedAt.withLock { $0 } }

    func update(_ change: @Sendable (inout Config) -> Void) {
        config.withLock { change(&$0) }
    }

    /// Fails (returns false) until the app has the Accessibility permission.
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        // Dragging a window or file into the edge calls the Dock just like moving does.
        let types: [CGEventType] = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        let mask = types.reduce(CGEventMask(0)) { $0 | CGEventMask(1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                let guardian = Unmanaged<EdgeGuard>.fromOpaque(refcon!).takeUnretainedValue()
                return guardian.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        self.tap = tap

        let thread = Thread { [self] in
            guard let tap = self.tap else { return }
            let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "dockpin.edge-guard"
        thread.qualityOfService = .userInteractive
        thread.start()
        self.thread = thread
        return true
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // The system turns slow or interrupted taps off; turn ours back on.
            Log.app.notice("event tap disabled (\(type == .tapDisabledByTimeout ? "timeout" : "user input", privacy: .public)), re-enabling")
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            let config = config.withLock { $0 }
            if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticMarker { break }
            if config.relocating { return nil }
            guard config.enabled, config.layout.blocks(event.location) else { break }
            if config.optionBypass && event.flags.contains(.maskAlternate) {
                bypassedAt.withLock { $0 = Date() }
                break
            }
            return nil
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }
}
