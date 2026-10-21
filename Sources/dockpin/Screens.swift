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

    /// The display the Dock is on now: the one whose usable area is inset on the
    /// Dock's edge. Unknowable while the Dock auto-hides; then we say nil.
    static func dockScreenID(edge: DockEdge) -> String? {
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
