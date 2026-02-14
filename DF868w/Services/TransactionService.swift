//
//  TransactionService.swift
//  DF868w
//
//  Ledgerly - Transaction CRUD and queries
//

import Foundation
import SwiftData

@Observable
final class TransactionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func allTransactions() throws -> [Transaction] {
        var desc = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(desc)
    }

    func transactions(
        from start: Date? = nil,
        to end: Date? = nil,
        type: TransactionType? = nil,
        categoryId: UUID? = nil,
        paymentMethodId: UUID? = nil,
        searchText: String? = nil
    ) throws -> [Transaction] {
        var results: [Transaction]
        let sort = [SortDescriptor<Transaction>(\.date, order: .reverse)]

        if let start, let end {
            var desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.date >= start && $0.date <= end }, sortBy: sort)
            results = try modelContext.fetch(desc)
        } else if let start {
            var desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.date >= start }, sortBy: sort)
            results = try modelContext.fetch(desc)
        } else if let end {
            var desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.date <= end }, sortBy: sort)
            results = try modelContext.fetch(desc)
        } else {
            var desc = FetchDescriptor<Transaction>(sortBy: sort)
            results = try modelContext.fetch(desc)
        }

        if let type {
            results = results.filter { $0.typeRaw == type.rawValue }
        }
        if let categoryId {
            results = results.filter { $0.categoryId == categoryId }
        }
        if let paymentMethodId {
            results = results.filter { $0.paymentMethodId == paymentMethodId }
        }
        if let searchText, !searchText.isEmpty {
            let lower = searchText.lowercased()
            results = results.filter { tx in
                tx.note.lowercased().contains(lower) ||
                tx.tags.contains { $0.lowercased().contains(lower) }
            }
        }

        return results
    }

    func transactionsInMonth(_ monthKey: String, type: TransactionType? = nil) throws -> [Transaction] {
        let (start, end) = monthRange(for: monthKey)
        return try transactions(from: start, to: end, type: type)
    }

    func transactionsGroupedByDay(_ transactions: [Transaction]) -> [(date: Date, items: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { tx -> Date in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.keys.sorted(by: >).map { date in
            (date: date, items: grouped[date]!.sorted { $0.date > $1.date })
        }
    }

    func totalIncome(for transactions: [Transaction]) -> Decimal {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountDecimal }
    }

    func totalExpense(for transactions: [Transaction]) -> Decimal {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountDecimal }
    }

    func net(for transactions: [Transaction]) -> Decimal {
        totalIncome(for: transactions) - totalExpense(for: transactions)
    }

    func create(_ transaction: Transaction) throws {
        modelContext.insert(transaction)
        try modelContext.save()
    }

    func update(_ transaction: Transaction) throws {
        transaction.updatedAt = Date()
        try modelContext.save()
    }

    func delete(_ transaction: Transaction) throws {
        modelContext.delete(transaction)
        try modelContext.save()
    }

    func duplicate(_ transaction: Transaction) throws -> Transaction {
        let copy = Transaction(
            type: transaction.type,
            amount: transaction.amountDecimal,
            currencyCode: transaction.currencyCode,
            categoryId: transaction.categoryId,
            date: Date(),
            note: transaction.note,
            paymentMethodId: transaction.paymentMethodId,
            tags: transaction.tags
        )
        try create(copy)
        return copy
    }

    func transaction(by id: UUID) throws -> Transaction? {
        var desc = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
        desc.fetchLimit = 1
        return try modelContext.fetch(desc).first
    }

    func lastUsedCategory(for type: TransactionType) -> UUID? {
        var desc = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.typeRaw == type.rawValue },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        desc.fetchLimit = 1
        return try? modelContext.fetch(desc).first?.categoryId
    }

    func frequentlyUsedCategories(for type: TransactionType, limit: Int = 5) -> [UUID] {
        let txs = (try? transactions(type: type)) ?? []
        let counts = Dictionary(grouping: txs, by: \.categoryId).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map(\.key)
    }

    private func monthRange(for monthKey: String) -> (Date, Date) {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, let year = parts.first, let month = parts.last else {
            return (Date.distantPast, Date())
        }
        var startComps = DateComponents()
        startComps.year = year
        startComps.month = month
        startComps.day = 1
        var endComps = startComps
        endComps.month = month + 1
        endComps.day = 0
        let calendar = Calendar.current
        let start = calendar.date(from: startComps) ?? Date()
        let end = calendar.date(from: endComps) ?? calendar.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }
}
