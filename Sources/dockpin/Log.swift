import os

/// `log stream --predicate 'subsystem == "io.github.esteban-eg-kim.dockpin"'`
/// shows what dockpin saw and did, e.g. why the Dock ended up elsewhere.
enum Log {
    static let app = Logger(subsystem: "io.github.esteban-eg-kim.dockpin", category: "app")
}
