import SwiftUI

// MARK: - Palette Style Constants

enum PaletteStyle {
    static let animation = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let transition = AnyTransition.opacity.combined(with: .move(edge: .top))

    static let rowCornerRadius: CGFloat = 6
    static let rowPaddingHorizontal: CGFloat = 12
    static let rowPaddingVertical: CGFloat = 7
    static let containerPaddingHorizontal: CGFloat = 8
    static let containerPaddingVertical: CGFloat = 6
}

// MARK: - Palette Container

struct PaletteContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Color.waveDivider.frame(height: 1)
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
            .padding(.horizontal, PaletteStyle.containerPaddingHorizontal)
            .padding(.vertical, PaletteStyle.containerPaddingVertical)
        }
    }
}

// MARK: - Palette Row

struct PaletteRow<Leading: View, Trailing: View>: View {
    let isHighlighted: Bool
    let action: () -> Void
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        Button(action: action) {
            HStack {
                leading()
                Spacer()
                trailing()
            }
            .padding(.horizontal, PaletteStyle.rowPaddingHorizontal)
            .padding(.vertical, PaletteStyle.rowPaddingVertical)
            .background(
                isHighlighted ? Color.waveModelHighlight : Color.clear,
                in: RoundedRectangle(cornerRadius: PaletteStyle.rowCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

extension PaletteRow where Trailing == EmptyView {
    init(
        isHighlighted: Bool,
        action: @escaping () -> Void,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.isHighlighted = isHighlighted
        self.action = action
        self.leading = leading
        self.trailing = { EmptyView() }
    }
}
