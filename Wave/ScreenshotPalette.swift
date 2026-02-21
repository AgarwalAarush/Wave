import SwiftUI
import ScreenCaptureKit

struct ScreenshotPalette: View {
    let targets: [CaptureTarget]
    let highlightedIndex: Int
    let onSelect: (CaptureTarget) -> Void

    private var currentFocusedBundle: String? {
        WindowFocusTracker.shared.currentFocused?.bundleIdentifier
    }

    private var previousFocusedBundle: String? {
        WindowFocusTracker.shared.previousFocused?.bundleIdentifier
    }

    var body: some View {
        PaletteContainer {
            if targets.isEmpty {
                loadingRow
            } else {
                ForEach(Array(targets.enumerated()), id: \.element.id) { index, target in
                    screenshotRow(target: target, index: index)
                }
            }
        }
    }

    private var loadingRow: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading windows...")
                .font(.waveSystem(size: 13))
                .foregroundStyle(Color.waveTextSecondary)
        }
        .padding(.vertical, 8)
    }

    private func shortcutLabel(for target: CaptureTarget, at index: Int) -> String? {
        // Skip full screen targets
        guard case .window = target.kind else { return nil }

        // Find first window matching current focused app
        if let currentBundle = currentFocusedBundle {
            let firstCurrentIndex = targets.firstIndex { t in
                if case .window(let w) = t.kind {
                    return w.owningApplication?.bundleIdentifier == currentBundle
                }
                return false
            }
            if firstCurrentIndex == index {
                return "⌘⇧1"
            }
        }

        // Find first window matching previous focused app
        if let previousBundle = previousFocusedBundle {
            let firstPreviousIndex = targets.firstIndex { t in
                if case .window(let w) = t.kind {
                    return w.owningApplication?.bundleIdentifier == previousBundle
                }
                return false
            }
            if firstPreviousIndex == index {
                return "⌘⇧2"
            }
        }

        return nil
    }

    @ViewBuilder
    private func screenshotRow(target: CaptureTarget, index: Int) -> some View {
        PaletteRow(
            isHighlighted: index == highlightedIndex,
            action: { onSelect(target) }
        ) {
            HStack(spacing: 8) {
                if let icon = target.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "macwindow")
                        .font(.waveSystem(size: 14))
                        .foregroundStyle(Color.waveIcon)
                        .frame(width: 16, height: 16)
                }

                Text(target.displayName)
                    .font(.waveSystem(size: 13, weight: .medium))
                    .foregroundStyle(Color.waveTextPrimary)
                    .lineLimit(1)
            }
        } trailing: {
            HStack(spacing: 8) {
                if let shortcut = shortcutLabel(for: target, at: index) {
                    Text(shortcut)
                        .font(.waveSystem(size: 10, weight: .medium))
                        .foregroundStyle(Color.waveAccent)
                }
                if let appName = target.appName {
                    Text(appName)
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                }
            }
        }
    }
}
