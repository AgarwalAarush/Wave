import Foundation
import AppKit
import ScreenCaptureKit

struct CaptureTarget: Identifiable, Equatable {
    enum Kind: Equatable {
        case fullScreen(SCDisplay)
        case window(SCWindow)

        static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case (.fullScreen(let a), .fullScreen(let b)):
                return a.displayID == b.displayID
            case (.window(let a), .window(let b)):
                return a.windowID == b.windowID
            default:
                return false
            }
        }
    }

    let id: String
    let kind: Kind
    let displayName: String
    let appName: String?
    let icon: NSImage?

    static func == (lhs: CaptureTarget, rhs: CaptureTarget) -> Bool {
        lhs.id == rhs.id
    }

    static func fullScreen(display: SCDisplay) -> CaptureTarget {
        CaptureTarget(
            id: "fullscreen-\(display.displayID)",
            kind: .fullScreen(display),
            displayName: "Entire Screen",
            appName: nil,
            icon: NSImage(systemSymbolName: "display", accessibilityDescription: "Screen")
        )
    }

    static func window(_ scWindow: SCWindow) -> CaptureTarget {
        let title = (scWindow.title?.isEmpty == false) ? scWindow.title! : "Untitled Window"
        let appName = scWindow.owningApplication?.applicationName
        let bundleID = scWindow.owningApplication?.bundleIdentifier

        var icon: NSImage?
        if let bundleID = bundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            icon = NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return CaptureTarget(
            id: "window-\(scWindow.windowID)",
            kind: .window(scWindow),
            displayName: title,
            appName: appName,
            icon: icon
        )
    }
}
