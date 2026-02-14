//
//  GlassCard.swift
//  DF868w
//
//  Ledgerly - Glass-style card component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Theme.spacingL)
            .background {
                RoundedRectangle(cornerRadius: Theme.radiusL)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.radiusL)
                            .stroke(Theme.divider.opacity(0.5), lineWidth: 0.5)
                    }
            }
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacingL)
            .background {
                RoundedRectangle(cornerRadius: Theme.radiusL)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.radiusL)
                            .stroke(Theme.divider.opacity(0.5), lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

#Preview {
    ZStack {
        Theme.primaryBackground.ignoresSafeArea()
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Balance")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.secondaryText)
                Text("$1,234.56")
                    .font(Theme.titleLarge)
                    .foregroundStyle(Theme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
