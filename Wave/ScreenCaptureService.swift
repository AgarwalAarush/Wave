import Foundation
import AppKit
import ScreenCaptureKit

final class ScreenCaptureService: @unchecked Sendable {
    static let shared = ScreenCaptureService()
    private init() {}

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
}
