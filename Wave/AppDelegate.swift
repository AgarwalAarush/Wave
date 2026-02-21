import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    private var panel: WavePanel!
    private var settingsWindow: SettingsWindow?
    private let chatViewModel = ChatViewModel()
    private var statusItem: NSStatusItem?
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }
        applyAppearance()
        setupPanel()
        setupSettingsWindow()
        setupMenuBarItem()
        setupMainMenu()
        setupNotificationObservers()
        HotKeyManager.shared.onToggle = { [weak self] in self?.toggle() }
        HotKeyManager.shared.register()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: .appearanceChanged,
            object: nil
        )
    }

    @objc private func handleAppearanceChange() {
        applyAppearance()
    }

    func applyAppearance() {
        let value = UserDefaults.standard.string(forKey: "appearance") ?? "system"
        switch value {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
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

    // MARK: - Settings Window

    private func setupSettingsWindow() {
        settingsWindow = SettingsWindow()

        let hosting = NSHostingView(rootView: SettingsView())
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        settingsWindow?.contentView = hosting

        settingsWindow?.delegate = self

        if let window = settingsWindow, let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - window.frame.width / 2
            let y = screenFrame.midY - window.frame.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Main Menu (for Cmd+,)

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "Wave", action: nil, keyEquivalent: "")
        appMenuItem.submenu = appMenu

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(menuOpenSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Wave", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
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
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
