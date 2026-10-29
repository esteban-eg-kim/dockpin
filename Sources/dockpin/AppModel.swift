import AppKit
import Combine
import DockpinCore

@MainActor
final class AppModel: ObservableObject {
    @Published var enabled: Bool {
        didSet {
            defaults.set(enabled, forKey: Keys.enabled)
            apply()
            if enabled { resetWatch(); bringDock(userAsked: true) }
        }
    }
    @Published var pinnedID: String? {
        didSet {
            defaults.set(pinnedID, forKey: Keys.pinned)
            if fallbackID == pinnedID { fallbackID = nil }
            apply()
            if pinnedID != oldValue { resetWatch(); bringDock(userAsked: true) }
        }
    }
    /// Where the Dock goes while the pinned display is unplugged; nil keeps it where it is.
    @Published var fallbackID: String? {
        didSet {
            defaults.set(fallbackID, forKey: Keys.fallback)
            apply()
            if fallbackID != oldValue { resetWatch() }
        }
    }
    @Published var optionBypass: Bool { didSet { defaults.set(optionBypass, forKey: Keys.optionBypass); apply() } }
    @Published var launchAtLogin: Bool = LoginItem.isEnabled
    @Published private(set) var trusted = Permissions.isTrusted
    @Published private(set) var screens: [ScreenInfo] = []
    @Published private(set) var edge: DockEdge = .bottom

    /// Pinned, permitted, and the tap is live.
    var isActive: Bool { enabled && trusted && edgeGuard.isRunning }

    /// The display the Dock should be on now (pinned, else fallback), if any is connected.
    var targetID: String? {
        dockTarget(pinned: pinnedID, fallback: fallbackID, connected: Set(screens.map(\.id)))
    }

    private let edgeGuard = EdgeGuard()
    private let defaults = UserDefaults.standard
    private var timers: [Timer] = []
    private var accessPoll: Timer?
    private var moving = false
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    // Watchdog: macOS also moves the Dock by itself (displays waking up and
    // reconnecting one by one), which no event filter can stop. So we look
    // every couple of seconds and bring it home.
    private var lastDockScreen: String?
    /// Where the user put the Dock on purpose with Option; left alone until it comes home.
    private var parkedOn: String?
    /// Give displays time to settle after a change before judging where the Dock is.
    private var settleUntil = Date.distantPast
    /// Consecutive fetches that didn't stick; stop after a few rather than keep grabbing the pointer.
    private var failedFetches = 0
    private static let maxFetches = 3

    private enum Keys {
        static let enabled = "enabled"
        static let pinned = "pinnedDisplay"
        static let fallback = "fallbackDisplay"
        static let optionBypass = "optionBypass"
    }

    init() {
        defaults.register(defaults: [Keys.enabled: true, Keys.optionBypass: true])
        enabled = defaults.bool(forKey: Keys.enabled)
        optionBypass = defaults.bool(forKey: Keys.optionBypass)
        pinnedID = defaults.string(forKey: Keys.pinned)
        fallbackID = defaults.string(forKey: Keys.fallback)

        refresh()
        if pinnedID == nil {
            // First run: pin wherever the Dock is right now.
            pinnedID = Screens.dockScreenID(edge: edge) ?? Screens.mainScreenID()
        }

        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) { model in
            model.refresh()
        }
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.screensDidWakeNotification) { model in
            Log.app.notice("displays woke up")
            model.resetWatch(settle: 3, keepParked: true)
        }
        observe(DistributedNotificationCenter.default(), Notification.Name("com.apple.screenIsUnlocked")) { model in
            Log.app.notice("screen unlocked")
            model.resetWatch(settle: 1, keepParked: true)
        }
        // Hears about display changes as they happen, before AppKit gets round to it.
        CGDisplayRegisterReconfigurationCallback({ _, flags, info in
            guard !flags.contains(.beginConfigurationFlag), let info else { return }
            let model = Unmanaged<AppModel>.fromOpaque(info)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    let model = model.takeUnretainedValue()
                    model.resetWatch(settle: 2, keepParked: true)
                    model.refresh()
                }
            }
        }, Unmanaged.passUnretained(self).toOpaque())

        // Neither the Dock changing sides nor macOS moving it posts anything we can
        // rely on; a cheap poll covers both.
        timers.append(Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        })
        startWhenTrusted()
        lastDockScreen = Screens.dockScreenID(edge: edge)
        Log.app.notice("started: accessibility \(self.trusted ? "allowed" : "missing", privacy: .public), pinned \(self.name(self.pinnedID), privacy: .public), Dock on \(self.name(self.lastDockScreen), privacy: .public)")
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, _ handle: @escaping @MainActor (AppModel) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if let self { handle(self) }
            }
        }
        observers.append((center, token))
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
        let before = screens.map(\.id)
        screens = Screens.current()
        if screens.map(\.id) != before {
            Log.app.notice("displays: \(self.screens.map(\.name).joined(separator: ", "), privacy: .public)")
            resetWatch(settle: 2, keepParked: true)
        }
        edge = DockPrefs.edge()
        apply()
    }

    private func resetWatch(settle seconds: TimeInterval = 0, keepParked: Bool = false) {
        failedFetches = 0
        if !keepParked { parkedOn = nil }
        settleUntil = max(settleUntil, Date().addingTimeInterval(seconds))
    }

    private func name(_ id: String?) -> String {
        guard let id else { return "unknown" }
        return screens.first(where: { $0.id == id })?.name ?? id
    }

    private func tick() {
        if DockPrefs.edge() != edge { refresh() }
        let current = Screens.dockScreenID(edge: edge)
        if let current, current != lastDockScreen {
            if let lastDockScreen {
                let onPurpose = edgeGuard.lastBypass.map { Date().timeIntervalSince($0) < 5 } ?? false
                Log.app.notice("Dock moved: \(self.name(lastDockScreen), privacy: .public) → \(self.name(current), privacy: .public)\(onPurpose ? " (Option held)" : "", privacy: .public)")
                if onPurpose { parkedOn = current }
            }
            lastDockScreen = current
        }
        guard let target = targetID else { return }
        if current == target {
            failedFetches = 0
            parkedOn = nil
            return
        }
        guard isActive, !moving, Date() >= settleUntil,
              let current, current != parkedOn,
              Session.isPresent,
              NSEvent.pressedMouseButtons == 0  // not in the middle of a drag
        else { return }
        guard failedFetches < Self.maxFetches else { return }
        failedFetches += 1
        Log.app.notice("Dock is on \(self.name(current), privacy: .public), fetching it to \(self.name(target), privacy: .public) (try \(self.failedFetches))")
        bringDock(userAsked: false)
        if failedFetches == Self.maxFetches {
            Log.app.error("giving up fetching the Dock until displays or settings change")
        }
    }

    private func apply() {
        let layout = GuardLayout(
            displays: screens.map { Display(id: $0.id, frame: $0.frame) },
            pinnedID: guardedFor,
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

    /// Moves the Dock onto the target display if it is elsewhere. If we can't tell
    /// where the Dock is, only move when the user asked.
    func bringDock(userAsked: Bool) {
        guard isActive, !moving, Session.isPresent,
              let targetID, let target = screens.first(where: { $0.id == targetID })
        else { return }
        let current = Screens.dockScreenID(edge: edge)
        if current == targetID { return }
        if current == nil && !userAsked { return }
        let displays = screens.map { Display(id: $0.id, frame: $0.frame) }
        guard let trigger = DockTrigger(
            display: Display(id: target.id, frame: target.frame), among: displays, edge: edge
        ) else {
            Log.app.error("\(target.name, privacy: .public): its whole Dock edge touches other displays, nowhere to push")
            return
        }

        moving = true
        parkedOn = nil
        let edgeGuard = edgeGuard
        // If the push misses, the watchdog (tick) tries again a moment later.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            DockMover.push(trigger, guard: edgeGuard)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.moving = false
            }
        }
    }

    /// The display the guard treats as home: the target, or, with none connected,
    /// wherever the Dock is now, so it stays put instead of wandering.
    private var guardedFor: String? {
        targetID ?? Screens.dockScreenID(edge: edge) ?? Screens.mainScreenID()
    }

    private func startWhenTrusted() {
        if trusted, edgeGuard.start() {
            objectWillChange.send()
            bringDock(userAsked: false)
            return
        }
        // Poll until granted: System Settings tells us nothing when it changes.
        accessPoll = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.trusted = Permissions.isTrusted
                if self.trusted, self.edgeGuard.start() {
                    Log.app.notice("accessibility allowed, guarding")
                    self.accessPoll?.invalidate()
                    self.accessPoll = nil
                    self.objectWillChange.send()
                    self.bringDock(userAsked: false)
                }
            }
        }
    }
}
