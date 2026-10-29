/// Which display the Dock should be on right now.
///
/// The pinned display when it is connected, otherwise the user's fallback when that
/// is connected, otherwise nil: leave the Dock where it is until one comes back.
public func dockTarget(pinned: String?, fallback: String?, connected: Set<String>) -> String? {
    if let pinned, connected.contains(pinned) { return pinned }
    if let fallback, fallback != pinned, connected.contains(fallback) { return fallback }
    return nil
}
