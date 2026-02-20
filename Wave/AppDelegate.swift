import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: WavePanel!
    private let chatViewModel = ChatViewModel()
    private var statusItem: NSStatusItem?
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }
        setupPanel()
        setupMenuBarItem()
        HotKeyManager.shared.onToggle = { [weak self] in self?.toggle() }
        HotKeyManager.shared.register()
    }

    // MARK: - Panel

    private func setupPanel() {
        panel = WavePanel()

        let rootView = ContentView(viewModel: chatViewModel)
            .environment(\.dismissPanel, { [weak self] in self?.hidePanel() })

        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = [.minSize, .maxSize, .intrinsicContentSize]
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        panel.contentView = hosting
        panel.positionAtTopCenter()
    }

    func toggle() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        panel.positionAtTopCenter()
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func hidePanel() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        })
    }

    func newChat() {
        chatViewModel.newChat()
    }

    // MARK: - Menu Bar

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wave.3.right", accessibilityDescription: "Wave")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Wave", action: #selector(menuToggle), keyEquivalent: "\u{08}"))
        menu.items.last?.keyEquivalentModifierMask = .shift
        menu.addItem(NSMenuItem(title: "New Chat", action: #selector(menuNewChat), keyEquivalent: "n"))
        menu.items.last?.keyEquivalentModifierMask = .command
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Wave", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func menuToggle() { toggle() }
    @objc private func menuNewChat() { newChat() }

    @objc private func menuOpenSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        DispatchQueue.main.async {
            for window in NSApp.windows where window.title == "Settings" || window.identifier?.rawValue.contains("Settings") == true {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                return
            }
        }
    }
}
