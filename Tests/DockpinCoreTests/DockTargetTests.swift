import Testing
@testable import DockpinCore

@Test func pinnedWinsWhenConnected() {
    #expect(dockTarget(pinned: "a", fallback: "b", connected: ["a", "b"]) == "a")
}

@Test func fallbackWhenPinnedIsUnplugged() {
    #expect(dockTarget(pinned: "a", fallback: "b", connected: ["b", "c"]) == "b")
}

@Test func nothingWhenNeitherIsConnected() {
    #expect(dockTarget(pinned: "a", fallback: "b", connected: ["c"]) == nil)
    #expect(dockTarget(pinned: "a", fallback: nil, connected: ["c"]) == nil)
    #expect(dockTarget(pinned: nil, fallback: nil, connected: ["c"]) == nil)
}

@Test func fallbackEqualToPinnedIsIgnored() {
    #expect(dockTarget(pinned: "a", fallback: "a", connected: ["c"]) == nil)
}
