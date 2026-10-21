import AppKit
import ApplicationServices

enum Permissions {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that adds dockpin to the Accessibility list.
    static func request() {
        // The value of kAXTrustedCheckOptionPrompt; the global itself is not concurrency-safe.
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    static func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
