import SwiftUI

struct ScreenshotPalette: View {
    let targets: [CaptureTarget]
    let highlightedIndex: Int
    let onSelect: (CaptureTarget) -> Void

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
            if let appName = target.appName {
                Text(appName)
                    .font(.waveSystem(size: 11))
                    .foregroundStyle(Color.waveTextSecondary)
            }
        }
    }
}
