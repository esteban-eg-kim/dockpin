import CoreGraphics

/// Where to push the cursor to call the Dock onto a display, the way a person would:
/// start a little inside the display and run into its Dock edge.
public struct DockTrigger: Sendable, Equatable {
    public var start: CGPoint
    public var end: CGPoint

    /// Pushes at the middle of the longest outer stretch of the edge, never where a
    /// neighbouring display lies beyond it (the cursor would just cross over).
    /// Nil when the whole edge is shared, so there is nowhere to push.
    public init?(display: Display, among displays: [Display], edge: DockEdge, approach: CGFloat = 50) {
        let others = displays.filter { $0.id != display.id }.map(\.frame)
        let spans = GuardLayout.outerSpans(of: display.frame, edge: edge, others: others)
        guard let span = spans.max(by: { $0.upperBound - $0.lowerBound < $1.upperBound - $1.lowerBound }),
              span.upperBound - span.lowerBound >= 2
        else { return nil }
        let mid = ((span.lowerBound + span.upperBound) / 2).rounded(.down)
        let frame = display.frame
        switch edge {
        case .bottom:
            start = CGPoint(x: mid, y: frame.maxY - approach)
            end = CGPoint(x: mid, y: frame.maxY - 1)
        case .left:
            start = CGPoint(x: frame.minX + approach, y: mid)
            end = CGPoint(x: frame.minX, y: mid)
        case .right:
            start = CGPoint(x: frame.maxX - approach, y: mid)
            end = CGPoint(x: frame.maxX - 1, y: mid)
        }
    }
}
