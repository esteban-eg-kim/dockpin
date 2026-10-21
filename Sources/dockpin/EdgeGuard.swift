import CoreGraphics
import DockpinCore
import Foundation
import os

/// Swallows mouse-moved events inside the guard bands, so the Dock never sees the
/// cursor pushing against another display's edge. The pointer itself still moves;
/// only the event that would wake the Dock is dropped.
///
/// The tap runs on its own thread so a busy main thread can never stall the mouse.
final class EdgeGuard: @unchecked Sendable {
    struct Config: Sendable {
        var layout: GuardLayout = .empty
        var enabled = true
        var optionBypass = true
    }

    private let config = OSAllocatedUnfairLock(initialState: Config())
    private var tap: CFMachPort?
    private var thread: Thread?

    var isRunning: Bool { tap != nil }

    func update(_ change: @Sendable (inout Config) -> Void) {
        config.withLock { change(&$0) }
    }

    /// Fails (returns false) until the app has the Accessibility permission.
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
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
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        case .mouseMoved:
            let config = config.withLock { $0 }
            guard config.enabled else { break }
            if config.optionBypass && event.flags.contains(.maskAlternate) { break }
            if config.layout.blocks(event.location) { return nil }
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }
}
