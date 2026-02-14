//
//  TransactionRowView.swift
//  DF868w
//
//  Ledgerly - Transaction list row
//

import SwiftUI
import SwiftData

struct TransactionRowView: View {
    let transaction: Transaction
    let categoryName: String
    let currencyCode: String

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(transaction.type == .income ? Theme.success : Theme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(CurrencyFormatter.format(transaction.amountDecimal, currencyCode: currencyCode))
                .font(Theme.headline)
                .foregroundStyle(transaction.type == .income ? Theme.success : Theme.primaryText)
        }
        .padding(.vertical, Theme.spacingS)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryName), \(transaction.type == .income ? "income" : "expense") \(CurrencyFormatter.format(transaction.amountDecimal, currencyCode: currencyCode))")
    }
}
