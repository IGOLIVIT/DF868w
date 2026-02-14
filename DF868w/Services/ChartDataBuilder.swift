//
//  ChartDataBuilder.swift
//  DF868w
//
//  Ledgerly - Chart data preparation
//

import Foundation
import SwiftData

struct DailyExpensePoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

struct CategoryBreakdownItem: Identifiable {
    let id: UUID
    let name: String
    let amount: Decimal
    let percentage: Decimal
}

struct IncomeExpenseBarData: Identifiable {
    let id = UUID()
    let label: String
    let income: Decimal
    let expense: Decimal
}

@Observable
final class ChartDataBuilder {
    private let transactionService: TransactionService
    private let modelContext: ModelContext

    init(transactionService: TransactionService, modelContext: ModelContext) {
        self.transactionService = transactionService
        self.modelContext = modelContext
    }

    func monthlyExpenseLineData(monthKey: String) -> [DailyExpensePoint] {
        let transactions = (try? transactionService.transactionsInMonth(monthKey, type: .expense)) ?? []
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { tx -> Date in
            calendar.startOfDay(for: tx.date)
        }
        let days = grouped.keys.sorted()
        return days.map { date in
            let amount = (grouped[date] ?? []).reduce(Decimal(0)) { $0 + $1.amountDecimal }
            return DailyExpensePoint(date: date, amount: amount)
        }.sorted { $0.date < $1.date }
    }

    func categoryBreakdown(monthKey: String) -> [CategoryBreakdownItem] {
        let transactions = (try? transactionService.transactionsInMonth(monthKey, type: .expense)) ?? []
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amountDecimal }
        guard total > 0 else { return [] }

        let categories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        let byCategory = Dictionary(grouping: transactions, by: \.categoryId)
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amountDecimal } }

        return byCategory.compactMap { categoryId, amount -> CategoryBreakdownItem? in
            guard let cat = categoryMap[categoryId] else { return nil }
            return CategoryBreakdownItem(
                id: categoryId,
                name: cat.name,
                amount: amount,
                percentage: amount / total
            )
        }.sorted { $0.amount > $1.amount }
    }

    func incomeVsExpenseBarData(months: Int = 6) -> [IncomeExpenseBarData] {
        let calendar = Calendar.current
        var result: [IncomeExpenseBarData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for i in (0..<months).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let monthKey = monthKey(from: date)
            let txs = (try? transactionService.transactionsInMonth(monthKey)) ?? []
            let income = transactionService.totalIncome(for: txs)
            let expense = transactionService.totalExpense(for: txs)
            result.append(IncomeExpenseBarData(
                label: formatter.string(from: date),
                income: income,
                expense: expense
            ))
        }
        return result
    }

    func weeklySpendByCategory(categoryId: UUID, monthKey: String) -> [DailyExpensePoint] {
        let transactions = (try? transactionService.transactionsInMonth(monthKey, type: .expense)) ?? []
        let filtered = transactions.filter { $0.categoryId == categoryId }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { tx -> Date in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.keys.sorted().map { date in
            let amount = (grouped[date] ?? []).reduce(Decimal(0)) { $0 + $1.amountDecimal }
            return DailyExpensePoint(date: date, amount: amount)
        }.sorted { $0.date < $1.date }
    }

    private func monthKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
