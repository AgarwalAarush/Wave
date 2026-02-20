import SwiftUI
import AppKit
import CoreText

extension Font {
    static func waveSystem(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        let nsWeight = NSFont.Weight(weight)
        let baseFont: NSFont

        switch design {
        case .monospaced:
            baseFont = NSFont.monospacedSystemFont(ofSize: size, weight: nsWeight)
        default:
            // Mirrors CSS stacks like ui-sans-serif/-apple-system/system-ui.
            baseFont = NSFont.systemFont(ofSize: size, weight: nsWeight)
        }

        let featureSettings: [[NSFontDescriptor.FeatureKey: Int]] = [[
            .typeIdentifier: kLigaturesType,
            .selectorIdentifier: kCommonLigaturesOffSelector,
        ]]

        let descriptor = baseFont.fontDescriptor.addingAttributes([
            NSFontDescriptor.AttributeName.featureSettings: featureSettings,
        ])

        let ligatureFreeFont = NSFont(descriptor: descriptor, size: size) ?? baseFont
        return Font(ligatureFreeFont)
    }
}

private extension NSFont.Weight {
    init(_ weight: Font.Weight) {
        switch weight {
        case .ultraLight:
            self = .ultraLight
        case .thin:
            self = .thin
        case .light:
            self = .light
        case .regular:
            self = .regular
        case .medium:
            self = .medium
        case .semibold:
            self = .semibold
        case .bold:
            self = .bold
        case .heavy:
            self = .heavy
        case .black:
            self = .black
        default:
            self = .regular
        }
    }
}
