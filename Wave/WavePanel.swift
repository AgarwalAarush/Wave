import AppKit

final class WavePanel: NSPanel {

    private var pinnedTopY: CGFloat?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 52),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func positionAtTopCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.origin.x + (screenFrame.width - frame.width) / 2
        let topY = screenFrame.origin.y + screenFrame.height - 8
        pinnedTopY = topY
        setFrameOrigin(NSPoint(x: x, y: topY - frame.height))
    }

    /// Keep the top edge pinned so the panel grows downward when content height changes.
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        var rect = frameRect
        if let topY = pinnedTopY {
            rect.origin.y = topY - rect.size.height
            if let screen = NSScreen.main {
                let sf = screen.visibleFrame
                rect.origin.x = sf.origin.x + (sf.width - rect.size.width) / 2
            }
        }
        super.setFrame(rect, display: flag)
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        var rect = frameRect
        if let topY = pinnedTopY {
            rect.origin.y = topY - rect.size.height
            if let screen = NSScreen.main {
                let sf = screen.visibleFrame
                rect.origin.x = sf.origin.x + (sf.width - rect.size.width) / 2
            }
        }
        super.setFrame(rect, display: displayFlag, animate: animateFlag)
    }
}
