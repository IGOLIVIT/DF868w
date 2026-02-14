//
//  Theme.swift
//  DF868w
//
//  Ledgerly - Design System
//

import SwiftUI

/// Central theme layer for all semantic colors. Use Theme tokens instead of hardcoded colors.
enum Theme {
    // MARK: - Backgrounds
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let cardSurface = Color("CardSurface")

    // MARK: - Text
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")

    // MARK: - Accent
    static let accent = Color("Accent")
    static let accentMuted = Color("AccentMuted")

    // MARK: - Semantic
    static let divider = Color("Divider")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let danger = Color("Danger")

    // MARK: - Spacing scale
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner radii
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 24

    // MARK: - Shadows
    static let shadowLight = ShadowStyle(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    static let shadowMedium = ShadowStyle(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Typography
extension Theme {
    static let titleLarge = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let titleMedium = Font.system(.title, design: .rounded).weight(.semibold)
    static let titleSmall = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline, design: .rounded).weight(.medium)
    static let body = Font.system(.body, design: .default)
    static let callout = Font.system(.callout, design: .default)
    static let caption = Font.system(.caption, design: .default)
    static let caption2 = Font.system(.caption2, design: .default)
    static let title3 = Font.system(.title3, design: .rounded)
}
