import AppKit
import Combine
import DockpinCore

@MainActor
final class AppModel: ObservableObject {
    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: Keys.enabled); apply() } }
    @Published var pinnedID: String? { didSet { defaults.set(pinnedID, forKey: Keys.pinned); apply() } }
    @Published var optionBypass: Bool { didSet { defaults.set(optionBypass, forKey: Keys.optionBypass); apply() } }
    @Published var launchAtLogin: Bool = LoginItem.isEnabled
    @Published private(set) var trusted = Permissions.isTrusted
    @Published private(set) var screens: [ScreenInfo] = []
    @Published private(set) var edge: DockEdge = .bottom

    /// Pinned, permitted, and the tap is live.
    var isActive: Bool { enabled && trusted && edgeGuard.isRunning }

    private let edgeGuard = EdgeGuard()
    private let defaults = UserDefaults.standard
    private var timers: [Timer] = []
    private var accessPoll: Timer?
    private var observers: [NSObjectProtocol] = []

    private enum Keys {
        static let enabled = "enabled"
        static let pinned = "pinnedDisplay"
        static let optionBypass = "optionBypass"
    }

    init() {
        defaults.register(defaults: [Keys.enabled: true, Keys.optionBypass: true])
        enabled = defaults.bool(forKey: Keys.enabled)
        optionBypass = defaults.bool(forKey: Keys.optionBypass)
        pinnedID = defaults.string(forKey: Keys.pinned)

        refresh()
        if pinnedID == nil {
            // First run: pin wherever the Dock is right now.
            pinnedID = Screens.dockScreenID(edge: edge) ?? Screens.mainScreenID()
        }

        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        })
        // Moving the Dock to another side posts nothing we can rely on; a cheap poll covers it.
        timers.append(Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, DockPrefs.edge() != self.edge else { return }
                self.refresh()
            }
        })
        startWhenTrusted()
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            try LoginItem.set(on)
        } catch {
            NSLog("dockpin: login item: \(error.localizedDescription)")
        }
        launchAtLogin = LoginItem.isEnabled
    }

    func requestAccess() {
        Permissions.request()
        Permissions.openSettings()
    }

    /// Re-reads displays and the Dock side, and hands the guard a fresh layout.
    func refresh() {
        screens = Screens.current()
        edge = DockPrefs.edge()
        apply()
    }

    private func apply() {
        let layout = GuardLayout(
            displays: screens.map { Display(id: $0.id, frame: $0.frame) },
            pinnedID: effectivePinnedID,
            edge: edge
        )
        let enabled = enabled, optionBypass = optionBypass
        edgeGuard.update {
            $0.layout = layout
            $0.enabled = enabled
            $0.optionBypass = optionBypass
        }
        objectWillChange.send()
    }

    /// If the pinned display is unplugged, keep the Dock where it is now instead of
    /// letting it wander, until the pinned one comes back.
    private var effectivePinnedID: String? {
        if let pinnedID, screens.contains(where: { $0.id == pinnedID }) { return pinnedID }
        return Screens.dockScreenID(edge: edge) ?? Screens.mainScreenID()
    }

    private func startWhenTrusted() {
        if trusted, edgeGuard.start() {
            objectWillChange.send()
            return
        }
        accessPoll = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.trusted = Permissions.isTrusted
                if self.trusted, self.edgeGuard.start() {
                    self.accessPoll?.invalidate()
                    self.accessPoll = nil
                    self.objectWillChange.send()
                }
            }
        }
    }
}
