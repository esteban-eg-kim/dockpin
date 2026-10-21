import CoreGraphics
import Testing
@testable import DockpinCore

// Quartz coordinates: y grows downward, the main display's top-left is (0, 0).
private let laptop = Display(id: "laptop", frame: CGRect(x: 0, y: 0, width: 1512, height: 982))
private let monitorRight = Display(id: "right", frame: CGRect(x: 1512, y: -400, width: 2560, height: 1440))
private let monitorAbove = Display(id: "above", frame: CGRect(x: -500, y: -1440, width: 2560, height: 1440))

@Test func pinnedDisplayIsNeverGuarded() {
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "laptop", edge: .bottom)
    #expect(!layout.blocks(CGPoint(x: 700, y: 981)))
}

@Test func otherDisplaysBottomEdgeIsGuarded() {
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "laptop", edge: .bottom)
    #expect(layout.blocks(CGPoint(x: 2500, y: 1039)))   // monitorRight maxY = 1040
    #expect(!layout.blocks(CGPoint(x: 2500, y: 1030)))  // above the band
}

@Test func switchingPinMovesTheWall() {
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "right", edge: .bottom)
    #expect(layout.blocks(CGPoint(x: 700, y: 981)))
    #expect(!layout.blocks(CGPoint(x: 2500, y: 1039)))
}

@Test func edgeSharedWithDisplayBelowStaysOpen() {
    // monitorAbove sits on top of the laptop, overlapping x 0..1512 of its bottom edge.
    let layout = GuardLayout(displays: [laptop, monitorAbove], pinnedID: "laptop", edge: .bottom)
    #expect(!layout.blocks(CGPoint(x: 700, y: -1)))     // doorway down to the laptop
    #expect(layout.blocks(CGPoint(x: -300, y: -1)))     // overhang left of the laptop
    #expect(layout.blocks(CGPoint(x: 1800, y: -1)))     // overhang right of the laptop
    #expect(layout.bands.count == 2)
}

@Test func leftDock() {
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "right", edge: .left)
    #expect(layout.blocks(CGPoint(x: 1, y: 500)))
    // monitorRight's left edge touches the laptop for y 0..982, and is open above that only
    // for the pinned display, which is not guarded at all.
    #expect(!layout.blocks(CGPoint(x: 1513, y: -200)))
}

@Test func rightDockLeavesSharedSegmentOpen() {
    // The laptop's right edge is fully covered by monitorRight (y -400..1040 ⊇ 0..982).
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "right", edge: .right)
    #expect(layout.bands.isEmpty)
}

@Test func unknownPinGuardsNothing() {
    let layout = GuardLayout(displays: [laptop, monitorRight], pinnedID: "gone", edge: .bottom)
    #expect(layout == .empty)
    #expect(GuardLayout(displays: [laptop], pinnedID: nil, edge: .bottom) == .empty)
}

@Test func singleDisplayHasNothingToGuard() {
    #expect(GuardLayout(displays: [laptop], pinnedID: "laptop", edge: .bottom).bands.isEmpty)
}

@Test func subtractSplitsSpan() {
    #expect(GuardLayout.subtract(10...20, from: 0...30) == [0...10, 20...30])
    #expect(GuardLayout.subtract(-5...40, from: 0...30) == [])
    #expect(GuardLayout.subtract(40...50, from: 0...30) == [0...30])
}

// A real desk: 4K main, a small panel hanging below it, a portrait monitor to the right.
private let lgMain = Display(id: "lg4k", frame: CGRect(x: 0, y: 0, width: 3008, height: 1692))
private let panelBelow = Display(id: "panel", frame: CGRect(x: 1317, y: 1692, width: 1024, height: 683))
private let portrait = Display(id: "portrait", frame: CGRect(x: 3008, y: -322, width: 1440, height: 2560))

@Test func realDeskPinnedToMain() {
    let layout = GuardLayout(displays: [lgMain, panelBelow, portrait], pinnedID: "lg4k", edge: .bottom)
    #expect(layout.blocks(CGPoint(x: 1800, y: 2374)))   // panel's bottom
    #expect(layout.blocks(CGPoint(x: 3700, y: 2237)))   // portrait's bottom
    #expect(!layout.blocks(CGPoint(x: 1800, y: 1691)))  // main itself
}

@Test func realDeskPinnedToPortraitKeepsDoorwayToPanel() {
    let layout = GuardLayout(displays: [lgMain, panelBelow, portrait], pinnedID: "portrait", edge: .bottom)
    #expect(!layout.blocks(CGPoint(x: 1800, y: 1691)))  // main → panel below: open
    #expect(layout.blocks(CGPoint(x: 500, y: 1691)))    // main, left of the panel
    #expect(layout.blocks(CGPoint(x: 2800, y: 1691)))   // main, right of the panel
    #expect(layout.blocks(CGPoint(x: 1800, y: 2374)))   // panel's own bottom
}
