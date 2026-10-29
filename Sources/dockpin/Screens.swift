import AppKit
import DockpinCore

/// A connected display as the menu shows it.
struct ScreenInfo: Identifiable, Equatable {
    var id: String          // CGDisplay UUID: survives reconnects and ID reshuffles
    var name: String
    var frame: CGRect       // Quartz global coordinates
    var pixelSize: CGSize

    var title: String {
        "\(name) (\(Int(pixelSize.width))×\(Int(pixelSize.height)))"
    }
}

enum Screens {
    static func current() -> [ScreenInfo] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else { return nil }
            let displayID = CGDirectDisplayID(number.uint32Value)
            guard let uuid = uuidString(for: displayID) else { return nil }
            let mode = CGDisplayCopyDisplayMode(displayID)
            return ScreenInfo(
                id: uuid,
                name: screen.localizedName,
                frame: CGDisplayBounds(displayID),
                pixelSize: CGSize(width: mode?.pixelWidth ?? 0, height: mode?.pixelHeight ?? 0)
            )
        }
    }

    /// The display the Dock is on now. Asks the Dock for its rectangle (works with
    /// auto-hide too); if that private call is gone, falls back to the display whose
    /// usable area is inset on the Dock's edge, which auto-hide defeats.
    static func dockScreenID(edge: DockEdge) -> String? {
        if let rect = CoreDock.rect() {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            for screen in current() where screen.frame.contains(center) {
                return screen.id
            }
        }
        for screen in NSScreen.screens {
            let frame = screen.frame, visible = screen.visibleFrame
            let inset: CGFloat
            switch edge {
            case .bottom: inset = visible.minY - frame.minY
            case .left: inset = visible.minX - frame.minX
            case .right: inset = frame.maxX - visible.maxX
            }
            guard inset > 0,
                  let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else { continue }
            return uuidString(for: CGDirectDisplayID(number.uint32Value))
        }
        return nil
    }

    static func mainScreenID() -> String? {
        uuidString(for: CGMainDisplayID())
    }

    private static func uuidString(for displayID: CGDirectDisplayID) -> String? {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, uuid) as String
    }
}

enum DockPrefs {
    /// `defaults read com.apple.dock orientation`; absent means bottom.
    static func edge() -> DockEdge {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        let value = CFPreferencesCopyAppValue("orientation" as CFString, "com.apple.dock" as CFString) as? String
        return value.flatMap(DockEdge.init(rawValue:)) ?? .bottom
    }
}

/// HIServices' private CoreDock calls, looked up at run time so a future macOS
/// without them just means falling back, not crashing.
enum CoreDock {
    private typealias GetRect = @convention(c) (UnsafeMutablePointer<CGRect>) -> Void
    private static let getRect: GetRect? = {
        guard let handle = dlopen("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", RTLD_LAZY),
              let symbol = dlsym(handle, "CoreDockGetRect")
        else { return nil }
        return unsafeBitCast(symbol, to: GetRect.self)
    }()

    /// The Dock's frame in Quartz coordinates, where it shows even while hidden.
    static func rect() -> CGRect? {
        guard let getRect else { return nil }
        var rect = CGRect.zero
        getRect(&rect)
        return rect.isEmpty ? nil : rect
    }
}

/// Whether someone is actually at this session. dockpin never moves the pointer
/// on the lock screen, with the displays asleep, or from a background session.
enum Session {
    static var isPresent: Bool {
        let info = CGSessionCopyCurrentDictionary() as? [String: Any] ?? [:]
        let onConsole = info[kCGSessionOnConsoleKey as String] as? Bool ?? true
        let locked = info["CGSSessionScreenIsLocked"] as? Bool ?? false
        return onConsole && !locked && CGDisplayIsAsleep(CGMainDisplayID()) == 0
    }
}
