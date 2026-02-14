//
//  PrimaryButton.swift
//  DF868w
//
//  Ledgerly - Primary CTA button
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Theme.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(Theme.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Theme.spacingS) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(Theme.headline)
            }
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.accentMuted.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
        }
        .buttonStyle(.plain)
    }
}
