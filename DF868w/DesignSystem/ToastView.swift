//
//  ToastView.swift
//  DF868w
//
//  Ledgerly - Success toast overlay
//

import SwiftUI

struct ToastMessage: Equatable {
    let text: String
    let icon: String

    static func success(_ text: String) -> ToastMessage {
        ToastMessage(text: text, icon: "checkmark.circle.fill")
    }
}

struct ToastView: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: message.icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.success)
            Text(message.text)
                .font(Theme.callout)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingM)
        .background {
            RoundedRectangle(cornerRadius: Theme.radiusM)
                .fill(Theme.secondaryBackground)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        }
    }
}
