//
//  CurrencySettingsView.swift
//  DF868w
//
//  Ledgerly - Currency selection
//

import SwiftUI
import SwiftData

struct CurrencySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [Preferences]

    var body: some View {
        List {
            ForEach(CurrencyFormatter.supportedCurrencies, id: \.code) { item in
                Button {
                    if let prefs = preferences.first {
                        prefs.currencyCode = item.code
                        try? modelContext.save()
                    }
                } label: {
                    HStack {
                        Text("\(item.code) – \(item.name)")
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        if preferences.first?.currencyCode == item.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Currency")
    }
}
