import Foundation
import AppKit
import ScreenCaptureKit

final class ScreenCaptureService: @unchecked Sendable {
    static let shared = ScreenCaptureService()
    private init() {}

    // MARK: - Full Screen Capture

    func captureFullScreen() async -> Data? {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return nil }

            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            return bitmap.representation(using: .png, properties: [.compressionFactor: 0.8])
        } catch {
            print("[Wave] Screenshot failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Available Targets

    func getAvailableTargets() async -> [CaptureTarget] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            var targets: [CaptureTarget] = []

            if let primaryDisplay = content.displays.first {
                targets.append(.fullScreen(display: primaryDisplay))
            }

            let validWindows = content.windows.filter { window in
                guard window.frame.width >= 100, window.frame.height >= 100 else { return false }
                guard window.owningApplication != nil else { return false }
                guard window.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
                return true
            }

            let sortedWindows = validWindows.sorted { a, b in
                let appA = a.owningApplication?.applicationName ?? ""
                let appB = b.owningApplication?.applicationName ?? ""
                if appA != appB { return appA < appB }
                return (a.title ?? "") < (b.title ?? "")
            }

            for window in sortedWindows {
                targets.append(.window(window))
            }

            return targets
        } catch {
            print("[Wave] Failed to get shareable content: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Targeted Capture

    func capture(target: CaptureTarget) async -> Data? {
        do {
            let config = SCStreamConfiguration()
            let filter: SCContentFilter

            switch target.kind {
            case .fullScreen(let display):
                config.width = display.width
                config.height = display.height
                filter = SCContentFilter(display: display, excludingWindows: [])

            case .window(let window):
                config.width = Int(window.frame.width)
                config.height = Int(window.frame.height)
                filter = SCContentFilter(desktopIndependentWindow: window)
            }

            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            return bitmap.representation(using: .png, properties: [.compressionFactor: 0.8])
        } catch {
            print("[Wave] Targeted capture failed: \(error.localizedDescription)")
            return nil
        }
    }
}
