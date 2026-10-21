import CoreGraphics
import Testing
@testable import DockpinCore

private let lgMain = Display(id: "lg4k", frame: CGRect(x: 0, y: 0, width: 3008, height: 1692))
private let panelBelow = Display(id: "panel", frame: CGRect(x: 1317, y: 1692, width: 1024, height: 683))
private let portrait = Display(id: "portrait", frame: CGRect(x: 3008, y: -322, width: 1440, height: 2560))
private let desk = [lgMain, panelBelow, portrait]

@Test func pushesStraightDownOnTheEdge() throws {
    let trigger = try #require(DockTrigger(display: portrait, among: desk, edge: .bottom))
    #expect(trigger.end == CGPoint(x: 3728, y: 2237))
    #expect(trigger.start == CGPoint(x: 3728, y: 2188))
}

@Test func avoidsTheDoorwayToADisplayBelow() throws {
    // The middle of lgMain's bottom (x 1504) is above the panel; pushing there would
    // drop the cursor onto the panel. The longer outer stretch is x 0..1317.
    let trigger = try #require(DockTrigger(display: lgMain, among: desk, edge: .bottom))
    #expect(trigger.end == CGPoint(x: 658, y: 1691))
    #expect(!(1317...2341).contains(trigger.end.x))
}

@Test func sideDocks() throws {
    let left = try #require(DockTrigger(display: lgMain, among: desk, edge: .left))
    #expect(left.end == CGPoint(x: 0, y: 846))
    #expect(left.start.x > left.end.x)
    let right = try #require(DockTrigger(display: portrait, among: desk, edge: .right))
    #expect(right.end == CGPoint(x: 4447, y: 958))
}

@Test func fullyCoveredEdgeHasNoTrigger() {
    let laptop = Display(id: "laptop", frame: CGRect(x: 0, y: 0, width: 1512, height: 982))
    let wide = Display(id: "wide", frame: CGRect(x: -500, y: 982, width: 2560, height: 1440))
    #expect(DockTrigger(display: laptop, among: [laptop, wide], edge: .bottom) == nil)
}
