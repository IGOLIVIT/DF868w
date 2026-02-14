//
//  SeedData.swift
//  DF868w
//
//  Ledgerly - Default categories and initial data
//

import Foundation
import SwiftData

enum SeedData {

    static let defaultCategories: [(name: String, icon: String, color: String)] = [
        ("Groceries", "cart.fill", "green"),
        ("Transport", "car.fill", "blue"),
        ("Coffee", "cup.and.saucer.fill", "brown"),
        ("Rent", "house.fill", "indigo"),
        ("Health", "heart.fill", "red"),
        ("Shopping", "bag.fill", "purple"),
        ("Entertainment", "ticket.fill", "orange"),
        ("Education", "book.fill", "teal"),
        ("Travel", "airplane", "cyan"),
        ("Bills", "doc.text.fill", "gray"),
        ("Salary", "banknote.fill", "green"),
        ("Freelance", "laptopcomputer", "blue"),
        ("Other", "ellipsis.circle.fill", "gray")
    ]

    static let defaultPaymentMethods: [(name: String, icon: String)] = [
        ("Cash", "banknote"),
        ("Card", "creditcard"),
        ("Transfer", "arrow.left.arrow.right")
    ]

    static let defaultTemplates: [(name: String, type: TransactionType, amount: Decimal, categoryIndex: Int)] = [
        ("Coffee", .expense, 5.00, 2),
        ("Taxi", .expense, 15.00, 1),
        ("Groceries", .expense, 50.00, 0),
        ("Salary", .income, 3000.00, 10)
    ]

    static func seedIfNeeded(context: ModelContext) {
        var needsSeed = false

        let categoryDesc = FetchDescriptor<Category>()
        if (try? context.fetch(categoryDesc).count) == 0 {
            needsSeed = true
        }

        if needsSeed {
            seedDefaults(context: context)
        }
    }

    static func seedDefaults(context: ModelContext) {
        // Categories
        for (index, cat) in defaultCategories.enumerated() {
            let category = Category(
                name: cat.name,
                iconName: cat.icon,
                colorKey: cat.color,
                isSystem: true,
                sortOrder: index
            )
            context.insert(category)
        }

        // Payment methods
        for (index, pm) in defaultPaymentMethods.enumerated() {
            let payment = PaymentMethod(name: pm.name, iconName: pm.icon, sortOrder: index)
            context.insert(payment)
        }

        // Preferences
        let prefs = Preferences(currencyCode: "USD", onboardingCompleted: false)
        context.insert(prefs)

        // Default templates (after categories exist)
        let cats = try! context.fetch(FetchDescriptor<Category>())
        let sortedCats = cats.sorted { $0.sortOrder < $1.sortOrder }
        for (index, t) in defaultTemplates.enumerated() {
            guard t.categoryIndex < sortedCats.count else { continue }
            let template = Template(
                name: t.name,
                type: t.type,
                amount: t.amount,
                categoryId: sortedCats[t.categoryIndex].id,
                sortOrder: index
            )
            context.insert(template)
        }

        try? context.save()
    }

    @MainActor
    static func seedPreview(into container: ModelContainer) {
        let context = container.mainContext
        seedDefaults(context: context)

        let cats = try! context.fetch(FetchDescriptor<Category>())
        let sortedCats = cats.sorted { $0.sortOrder < $1.sortOrder }
        let pms = try! context.fetch(FetchDescriptor<PaymentMethod>())
        let prefs = try! context.fetch(FetchDescriptor<Preferences>()).first ?? Preferences()

        // Add sample transactions
        let calendar = Calendar.current
        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            for _ in 0..<(Int.random(in: 1...4)) {
                let isExpense = Bool.random()
                let category = sortedCats[Int.random(in: 0..<min(10, sortedCats.count))]
                let amount: Decimal = isExpense ? Decimal(Int.random(in: 5...150)) : Decimal(Int.random(in: 500...5000))
                let tx = Transaction(
                    type: isExpense ? .expense : .income,
                    amount: amount,
                    currencyCode: prefs.currencyCode,
                    categoryId: category.id,
                    date: date,
                    note: ["Coffee shop", "Grocery run", "Uber", "Salary"][Int.random(in: 0..<4)],
                    paymentMethodId: pms.randomElement()?.id
                )
                context.insert(tx)
            }
        }
        try? context.save()
    }

    static func resetAll(context: ModelContext) throws {
        try context.delete(model: Transaction.self)
        try context.delete(model: Budget.self)
        try context.delete(model: Goal.self)
        try context.delete(model: Template.self)
        try context.delete(model: Category.self)
        try context.delete(model: PaymentMethod.self)
        try context.delete(model: Preferences.self)
        try context.save()
        seedDefaults(context: context)
    }
}
