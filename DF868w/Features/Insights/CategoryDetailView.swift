//
//  CategoryDetailView.swift
//  DF868w
//
//  Ledgerly - Category analytics and transactions
//

import SwiftUI
import SwiftData
import Charts

struct CategoryDetailView: View {
    @Environment(AppStore.self) private var store
    let categoryId: UUID
    let categoryName: String
    let currencyCode: String
    let monthKey: String

    private var weeklyData: [DailyExpensePoint] {
        store.chartDataBuilder.weeklySpendByCategory(categoryId: categoryId, monthKey: monthKey)
    }

    private var transactions: [Transaction] {
        (try? store.transactionService.transactionsInMonth(monthKey, type: .expense)) ?? []
            .filter { $0.categoryId == categoryId }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                if !weeklyData.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: Theme.spacingM) {
                            Text("Spending by week")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            Chart(weeklyData) { point in
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                                )
                                .foregroundStyle(Theme.accent)
                            }
                            .frame(height: 140)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: Theme.spacingM) {
                        Text("Transactions")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        ForEach(transactions, id: \.id) { tx in
                            HStack {
                                Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                if !tx.note.isEmpty {
                                    Text(tx.note)
                                        .font(Theme.body)
                                        .foregroundStyle(Theme.primaryText)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(CurrencyFormatter.format(tx.amountDecimal, currencyCode: currencyCode))
                                    .font(Theme.callout)
                                    .foregroundStyle(Theme.primaryText)
                            }
                            .padding(.vertical, 4)
                        }
                        if transactions.isEmpty {
                            Text("No transactions this month.")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(categoryName)
    }
}
