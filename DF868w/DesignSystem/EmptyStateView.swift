//
//  EmptyStateView.swift
//  DF868w
//
//  Ledgerly - Empty state placeholder
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.secondaryText.opacity(0.6))

            VStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(Theme.titleSmall)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(actionTitle, icon: "plus", action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Theme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
