//
//  BudgetService.swift
//  DF868w
//
//  Ledgerly - Budget calculations and management
//

import Foundation
import SwiftData

struct BudgetSummary {
    let categoryId: UUID
    let limit: Decimal
    let spent: Decimal
    let percentage: Decimal
    let isOver: Bool
    let isNear: Bool
}

@Observable
final class BudgetService {
    private let modelContext: ModelContext
    private let transactionService: TransactionService

    init(modelContext: ModelContext, transactionService: TransactionService) {
        self.modelContext = modelContext
        self.transactionService = transactionService
    }

    func budgets(for monthKey: String) throws -> [Budget] {
        var desc = FetchDescriptor<Budget>(predicate: #Predicate<Budget> { $0.monthKey == monthKey })
        desc.sortBy = [SortDescriptor(\.categoryId)]
        return try modelContext.fetch(desc)
    }

    func budget(for categoryId: UUID, monthKey: String) throws -> Budget? {
        var desc = FetchDescriptor<Budget>(predicate: #Predicate<Budget> {
            $0.categoryId == categoryId && $0.monthKey == monthKey
        })
        desc.fetchLimit = 1
        return try modelContext.fetch(desc).first
    }

    func createOrUpdateBudget(categoryId: UUID, monthKey: String, limit: Decimal) throws {
        if let existing = try budget(for: categoryId, monthKey: monthKey) {
            existing.limitDecimal = limit
        } else {
            let budget = Budget(categoryId: categoryId, monthKey: monthKey, limit: limit)
            modelContext.insert(budget)
        }
        try modelContext.save()
    }

    func deleteBudget(_ budget: Budget) throws {
        modelContext.delete(budget)
        try modelContext.save()
    }

    func budgetSummaries(for monthKey: String) throws -> [BudgetSummary] {
        let budgets = try self.budgets(for: monthKey)
        let expenses = try transactionService.transactionsInMonth(monthKey, type: .expense)
        let spentByCategory = Dictionary(grouping: expenses, by: \.categoryId)
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amountDecimal } }

        return budgets.compactMap { budget -> BudgetSummary? in
            let spent = spentByCategory[budget.categoryId] ?? 0
            let limit = budget.limitDecimal
            let percentage: Decimal = limit > 0 ? spent / limit : 0
            let isOver = spent > limit
            let isNear = limit > 0 && percentage >= 0.9 && !isOver
            return BudgetSummary(
                categoryId: budget.categoryId,
                limit: limit,
                spent: spent,
                percentage: percentage,
                isOver: isOver,
                isNear: isNear
            )
        }
    }

    func totalBudgetSpentPercent(for monthKey: String) -> Decimal {
        guard let summaries = try? budgetSummaries(for: monthKey), !summaries.isEmpty else {
            return 0
        }
        let totalLimit = summaries.reduce(Decimal(0)) { $0 + $1.limit }
        let totalSpent = summaries.reduce(Decimal(0)) { $0 + $1.spent }
        guard totalLimit > 0 else { return 0 }
        return totalSpent / totalLimit
    }

    func topOverspentCategories(for monthKey: String, limit: Int = 3) -> [BudgetSummary] {
        (try? budgetSummaries(for: monthKey)) ?? []
            .filter { $0.isOver }
            .sorted { $0.spent - $0.limit > $1.spent - $1.limit }
            .prefix(limit)
            .map { $0 }
    }
}
