import AppKit

final class SettingsWindow: NSWindow {

    private static let cornerRadius: CGFloat = 18
    private static let defaultWidth: CGFloat = 620
    private static let defaultHeight: CGFloat = 460

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultWidth, height: Self.defaultHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "Settings"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)

        minSize = NSSize(width: 520, height: 400)
    }

    override func makeKey() {
        super.makeKey()
        configureContentViewRounding()
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        configureContentViewRounding()
    }

    private func configureContentViewRounding() {
        guard let contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = Self.cornerRadius
        contentView.layer?.masksToBounds = true
    }
}
