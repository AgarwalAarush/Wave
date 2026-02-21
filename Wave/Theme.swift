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
        light: Color(hex: 0xFFFFFF),
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

    static let waveModelPill = Color(
        light: Color.black.opacity(0.05),
        dark: Color.white.opacity(0.08)
    )

    static let waveModelHighlight = Color(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.12)
    )

    static let waveDropdownBackground = Color(
        light: Color(hex: 0xEBE9E4),
        dark: Color(hex: 0x3A3732)
    )

    static let waveAccent = Color(
        light: Color(hex: 0x2AA198),
        dark: Color(hex: 0x5DD6C8)
    )

    static let waveUserBubble = Color(
        light: Color(hex: 0xF4F4F4),
        dark: Color(hex: 0x303030)
    )

    static let waveSettingsBackground = Color(
        light: Color(hex: 0xF5F5F5),
        dark: Color(hex: 0x1E1E1E)
    )

    static let waveSettingsSidebar = Color(
        light: Color(hex: 0xE8E8E8),
        dark: Color(hex: 0x2A2A2A)
    )

    static let waveSettingsCard = Color(
        light: Color(hex: 0xFFFFFF),
        dark: Color(hex: 0x2F2F2F)
    )

    static let waveSettingsRowHover = Color(
        light: Color(hex: 0x2AA198).opacity(0.1),
        dark: Color(hex: 0x5DD6C8).opacity(0.15)
    )

    // MARK: - Code Block Colors

    static let waveCodeBackground = Color(
        light: Color(hex: 0xF5F5F5),
        dark: Color(hex: 0x1E1E1E)
    )

    static let waveCodeHeader = Color(
        light: Color(hex: 0xE8E8E8),
        dark: Color(hex: 0x2D2D2D)
    )

    static let waveCodeText = Color(
        light: Color(hex: 0x1A1A1A),
        dark: Color(hex: 0xD4D4D4)
    )

    static let waveCodeKeyword = Color(
        light: Color(hex: 0xAF00DB),
        dark: Color(hex: 0xC586C0)
    )

    static let waveCodeString = Color(
        light: Color(hex: 0xA31515),
        dark: Color(hex: 0xCE9178)
    )

    static let waveCodeComment = Color(
        light: Color(hex: 0x008000),
        dark: Color(hex: 0x6A9955)
    )

    static let waveCodeNumber = Color(
        light: Color(hex: 0x098658),
        dark: Color(hex: 0xB5CEA8)
    )

    static let waveCodeType = Color(
        light: Color(hex: 0x267F99),
        dark: Color(hex: 0x4EC9B0)
    )

    static let waveCodeFunction = Color(
        light: Color(hex: 0x795E26),
        dark: Color(hex: 0xDCDCAA)
    )

    static let waveCodePreprocessor = Color(
        light: Color(hex: 0x0000FF),
        dark: Color(hex: 0x9CDCFE)
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
