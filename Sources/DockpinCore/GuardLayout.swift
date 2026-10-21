import CoreGraphics

/// Screen edge the Dock sits on (`defaults read com.apple.dock orientation`).
public enum DockEdge: String, Sendable, CaseIterable {
    case bottom, left, right
}

/// A display in global Quartz coordinates: origin at the top-left of the
/// main display, y grows downward (what `CGDisplayBounds` and `CGEvent.location` use).
public struct Display: Sendable, Equatable {
    public var id: String
    public var frame: CGRect

    public init(id: String, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

/// The strips of screen where mouse-moved events must not reach the Dock.
///
/// The Dock follows the cursor to another display when it is pushed against that
/// display's Dock edge. For every display except the pinned one, we guard a thin
/// band along that edge, but only where nothing lies beyond it: a stretch of edge
/// shared with a neighbouring display is a doorway, not a wall, and stays open.
public struct GuardLayout: Sendable, Equatable {
    public private(set) var bands: [CGRect]

    public static let empty = GuardLayout(bands: [])

    init(bands: [CGRect]) {
        self.bands = bands
    }

    /// - Parameters:
    ///   - pinnedID: the display the Dock should stay on. If it is not among
    ///     `displays`, nothing is guarded: there is no right answer to enforce.
    ///   - thickness: band depth in points, measured inward from the edge.
    public init(displays: [Display], pinnedID: String?, edge: DockEdge, thickness: CGFloat = 4) {
        guard let pinnedID, displays.contains(where: { $0.id == pinnedID }) else {
            self = .empty
            return
        }
        var bands: [CGRect] = []
        for display in displays where display.id != pinnedID {
            let others = displays.filter { $0.id != display.id }
            for span in Self.outerSpans(of: display.frame, edge: edge, others: others.map(\.frame)) {
                bands.append(Self.band(along: span, of: display.frame, edge: edge, thickness: thickness))
            }
        }
        self.bands = bands
    }

    /// True when an event at `point` would count as pushing the Dock away.
    public func blocks(_ point: CGPoint) -> Bool {
        for band in bands where band.contains(point) {
            return true
        }
        return false
    }

    // MARK: - Geometry

    /// Parts of the edge (as ranges along it) with no other display on the far side.
    static func outerSpans(of frame: CGRect, edge: DockEdge, others: [CGRect]) -> [ClosedRange<CGFloat>] {
        let tolerance: CGFloat = 1
        var spans: [ClosedRange<CGFloat>]
        var neighbours: [ClosedRange<CGFloat>] = []
        switch edge {
        case .bottom:
            spans = [frame.minX...frame.maxX]
            for other in others where abs(other.minY - frame.maxY) <= tolerance {
                neighbours.append(other.minX...other.maxX)
            }
        case .left:
            spans = [frame.minY...frame.maxY]
            for other in others where abs(other.maxX - frame.minX) <= tolerance {
                neighbours.append(other.minY...other.maxY)
            }
        case .right:
            spans = [frame.minY...frame.maxY]
            for other in others where abs(other.minX - frame.maxX) <= tolerance {
                neighbours.append(other.minY...other.maxY)
            }
        }
        for cut in neighbours {
            spans = spans.flatMap { subtract(cut, from: $0) }
        }
        return spans
    }

    static func subtract(_ cut: ClosedRange<CGFloat>, from span: ClosedRange<CGFloat>) -> [ClosedRange<CGFloat>] {
        guard cut.lowerBound < span.upperBound, cut.upperBound > span.lowerBound else { return [span] }
        var rest: [ClosedRange<CGFloat>] = []
        if span.lowerBound < cut.lowerBound { rest.append(span.lowerBound...cut.lowerBound) }
        if cut.upperBound < span.upperBound { rest.append(cut.upperBound...span.upperBound) }
        return rest
    }

    static func band(along span: ClosedRange<CGFloat>, of frame: CGRect, edge: DockEdge, thickness: CGFloat) -> CGRect {
        let length = span.upperBound - span.lowerBound
        switch edge {
        case .bottom:
            return CGRect(x: span.lowerBound, y: frame.maxY - thickness, width: length, height: thickness)
        case .left:
            return CGRect(x: frame.minX, y: span.lowerBound, width: thickness, height: length)
        case .right:
            return CGRect(x: frame.maxX - thickness, y: span.lowerBound, width: thickness, height: length)
        }
    }
}
