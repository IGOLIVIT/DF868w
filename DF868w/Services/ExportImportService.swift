//
//  ExportImportService.swift
//  DF868w
//
//  Ledgerly - CSV export and JSON backup/restore
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

struct ExportImportError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct BackupData: Codable {
    let version: Int
    let exportDate: Date
    let transactions: [TransactionExport]
    let categories: [CategoryExport]
    let budgets: [BudgetExport]
    let goals: [GoalExport]
    let templates: [TemplateExport]
    let paymentMethods: [PaymentMethodExport]
}

struct TransactionExport: Codable {
    let id: UUID
    let type: String
    let amount: Double
    let currencyCode: String
    let categoryId: UUID
    let date: Date
    let note: String
    let paymentMethodId: UUID?
    let tags: [String]
}

struct CategoryExport: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorKey: String
    let sortOrder: Int
}

struct BudgetExport: Codable {
    let categoryId: UUID
    let monthKey: String
    let limit: Double
}

struct GoalExport: Codable {
    let id: UUID
    let name: String
    let targetAmount: Double
    let targetDate: Date
    let currentAmount: Double
}

struct TemplateExport: Codable {
    let id: UUID
    let name: String
    let type: String
    let amount: Double
    let categoryId: UUID
    let paymentMethodId: UUID?
    let sortOrder: Int
}

struct PaymentMethodExport: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let sortOrder: Int
}

@Observable
final class ExportImportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportCSV(transactions: [Transaction], categories: [Category], currencyCode: String) throws -> Data {
        var csv = "Date,Type,Category,Amount,Note,Payment Method,Tags\n"
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })

        for tx in transactions.sorted(by: { $0.date > $1.date }) {
            let cat = categoryMap[tx.categoryId] ?? "Unknown"
            let pm = "" // Could resolve if needed
            let tags = tx.tags.joined(separator: "; ")
            let row = "\(tx.date.formatted(date: .abbreviated, time: .omitted)),\(tx.type.rawValue),\(cat),\(tx.amountDecimal),\"\(tx.note.replacingOccurrences(of: "\"", with: "\"\""))\",\(pm),\"\(tags)\"\n"
            csv += row
        }
        guard let data = csv.data(using: .utf8) else {
            throw ExportImportError(message: "Failed to encode CSV")
        }
        return data
    }

    func exportJSON() throws -> Data {
        let transactions = try modelContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let categories = try modelContext.fetch(FetchDescriptor<Category>())
        let budgets = try modelContext.fetch(FetchDescriptor<Budget>())
        let goals = try modelContext.fetch(FetchDescriptor<Goal>())
        let templates = try modelContext.fetch(FetchDescriptor<Template>())
        let paymentMethods = try modelContext.fetch(FetchDescriptor<PaymentMethod>())

        let backup = BackupData(
            version: 1,
            exportDate: Date(),
            transactions: transactions.map { tx in
                TransactionExport(
                    id: tx.id,
                    type: tx.typeRaw,
                    amount: NSDecimalNumber(decimal: tx.amountDecimal).doubleValue,
                    currencyCode: tx.currencyCode,
                    categoryId: tx.categoryId,
                    date: tx.date,
                    note: tx.note,
                    paymentMethodId: tx.paymentMethodId,
                    tags: tx.tags
                )
            },
            categories: categories.map { CategoryExport(id: $0.id, name: $0.name, iconName: $0.iconName, colorKey: $0.colorKey, sortOrder: $0.sortOrder) },
            budgets: budgets.map { BudgetExport(categoryId: $0.categoryId, monthKey: $0.monthKey, limit: NSDecimalNumber(decimal: $0.limitDecimal).doubleValue) },
            goals: goals.map { GoalExport(id: $0.id, name: $0.name, targetAmount: NSDecimalNumber(decimal: $0.targetAmount).doubleValue, targetDate: $0.targetDate, currentAmount: NSDecimalNumber(decimal: $0.currentAmount).doubleValue) },
            templates: templates.map { TemplateExport(id: $0.id, name: $0.name, type: $0.typeRaw, amount: NSDecimalNumber(decimal: $0.amountDecimal).doubleValue, categoryId: $0.categoryId, paymentMethodId: $0.paymentMethodId, sortOrder: $0.sortOrder) },
            paymentMethods: paymentMethods.map { PaymentMethodExport(id: $0.id, name: $0.name, iconName: $0.iconName, sortOrder: $0.sortOrder) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    func importJSON(_ data: Data, replaceExisting: Bool = false) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        guard backup.version >= 1 else {
            throw ExportImportError(message: "Unsupported backup version")
        }

        if replaceExisting {
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: Budget.self)
            try modelContext.delete(model: Goal.self)
            try modelContext.delete(model: Template.self)
            try modelContext.delete(model: Category.self)
            try modelContext.delete(model: PaymentMethod.self)
        }

        let existingCats = Set((try? modelContext.fetch(FetchDescriptor<Category>()).map(\.id)) ?? [])
        let existingPMs = Set((try? modelContext.fetch(FetchDescriptor<PaymentMethod>()).map(\.id)) ?? [])

        for c in backup.categories where !existingCats.contains(c.id) || replaceExisting {
            if replaceExisting, let old = try? modelContext.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.id == c.id })).first {
                modelContext.delete(old)
            }
            let cat = Category(id: c.id, name: c.name, iconName: c.iconName, colorKey: c.colorKey, isSystem: false, sortOrder: c.sortOrder)
            modelContext.insert(cat)
        }

        for pm in backup.paymentMethods where !existingPMs.contains(pm.id) || replaceExisting {
            if replaceExisting, let old = try? modelContext.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.id == pm.id })).first {
                modelContext.delete(old)
            }
            let payment = PaymentMethod(id: pm.id, name: pm.name, iconName: pm.iconName, sortOrder: pm.sortOrder)
            modelContext.insert(payment)
        }

        for tx in backup.transactions {
            let transaction = Transaction(
                id: tx.id,
                type: TransactionType(rawValue: tx.type) ?? .expense,
                amount: Decimal(tx.amount),
                currencyCode: tx.currencyCode,
                categoryId: tx.categoryId,
                date: tx.date,
                note: tx.note,
                paymentMethodId: tx.paymentMethodId,
                tags: tx.tags
            )
            modelContext.insert(transaction)
        }

        for b in backup.budgets {
            let budget = Budget(categoryId: b.categoryId, monthKey: b.monthKey, limit: Decimal(b.limit))
            modelContext.insert(budget)
        }

        for g in backup.goals {
            let goal = Goal(id: g.id, name: g.name, targetAmount: Decimal(g.targetAmount), targetDate: g.targetDate, currentAmount: Decimal(g.currentAmount))
            modelContext.insert(goal)
        }

        for t in backup.templates {
            let template = Template(id: t.id, name: t.name, type: TransactionType(rawValue: t.type) ?? .expense, amount: Decimal(t.amount), categoryId: t.categoryId, paymentMethodId: t.paymentMethodId, sortOrder: t.sortOrder)
            modelContext.insert(template)
        }

        try modelContext.save()
    }
}
