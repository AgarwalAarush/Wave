import Foundation
import AppKit

final class WindowFocusTracker: @unchecked Sendable {
    static let shared = WindowFocusTracker()

    struct FocusedWindow: Equatable {
        let bundleIdentifier: String
        let appName: String
        let windowTitle: String?

        static func == (lhs: FocusedWindow, rhs: FocusedWindow) -> Bool {
            lhs.bundleIdentifier == rhs.bundleIdentifier
        }
    }

    private(set) var currentFocused: FocusedWindow?
    private(set) var previousFocused: FocusedWindow?

    private init() {
        startTracking()
    }

    private func startTracking() {
        let workspace = NSWorkspace.shared

        // Track app activation
        workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }

        // Initialize with current frontmost app
        if let frontApp = workspace.frontmostApplication {
            currentFocused = FocusedWindow(
                bundleIdentifier: frontApp.bundleIdentifier ?? "",
                appName: frontApp.localizedName ?? "Unknown",
                windowTitle: nil
            )
        }
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        // Skip if it's Wave itself
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }

        let newFocused = FocusedWindow(
            bundleIdentifier: app.bundleIdentifier ?? "",
            appName: app.localizedName ?? "Unknown",
            windowTitle: nil
        )

        // Only update if different from current
        if currentFocused != newFocused {
            previousFocused = currentFocused
            currentFocused = newFocused
        }
    }

    /// Returns bundle identifiers for focused windows in priority order
    func getFocusedBundleIdentifiers() -> (current: String?, previous: String?) {
        return (currentFocused?.bundleIdentifier, previousFocused?.bundleIdentifier)
    }
}
