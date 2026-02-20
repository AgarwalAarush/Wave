import SwiftUI
import AppKit

extension Color {
    /// Initialize a Color that resolves differently in light vs dark mode.
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
}

// MARK: - Wave Palette

extension Color {
    static let wavePanelBackground = Color(
        light: Color(hex: 0xF5F3EF),
        dark: Color(hex: 0x2F2C27)
    )

    static let waveTextPrimary = Color(
        light: Color(hex: 0x1A1A1A),
        dark: Color(hex: 0xEDEDED)
    )

    static let waveTextSecondary = Color(
        light: Color(hex: 0x6B6B6B),
        dark: Color(hex: 0x9A9A9A)
    )

    static let waveBorder = Color(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.1)
    )

    static let waveDivider = Color(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.08)
    )

    static let waveError = Color(
        light: Color(hex: 0xD32F2F),
        dark: Color(hex: 0xEF5350)
    )

    static let waveShadow = Color(
        light: Color.black.opacity(0.15),
        dark: Color.black.opacity(0.4)
    )

    static let waveIcon = Color(
        light: Color(hex: 0x8A8A8A),
        dark: Color(hex: 0x808080)
    )

    static let waveHint = Color(
        light: Color(hex: 0xAAAAAA),
        dark: Color(hex: 0x5A5A5A)
    )
}

// MARK: - Hex Initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
