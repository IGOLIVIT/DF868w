//
//  FilterChip.swift
//  DF868w
//
//  Ledgerly - Filter chip component
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.callout)
                .foregroundStyle(isSelected ? .white : Theme.primaryText)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(isSelected ? Theme.accent : Theme.secondaryBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
