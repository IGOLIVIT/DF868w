//
//  LedgerlyUnitTests.swift
//  DF868wTests
//
//  Ledgerly - Unit tests
//

import XCTest
import SwiftData
@testable import DF868w

final class LedgerlyUnitTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var transactionService: TransactionService!
    var budgetService: BudgetService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Schema([
            Transaction.self, Category.self, Budget.self, Goal.self,
            Template.self, Preferences.self, PaymentMethod.self
        ]), configurations: [config])
        context = container.mainContext
        let txService = TransactionService(modelContext: context)
        transactionService = txService
        budgetService = BudgetService(modelContext: context, transactionService: txService)
        SeedData.seedDefaults(context: context)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    func testBudgetCalculations() throws {
        let cats = try context.fetch(FetchDescriptor<Category>())
        guard let cat = cats.first else { XCTFail("No categories"); return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: Date())

        let budget = Budget(categoryId: cat.id, monthKey: monthKey, limit: 100)
        context.insert(budget)
        try context.save()

        let tx1 = Transaction(type: .expense, amount: 30, currencyCode: "USD", categoryId: cat.id, date: Date())
        let tx2 = Transaction(type: .expense, amount: 50, currencyCode: "USD", categoryId: cat.id, date: Date())
        context.insert(tx1)
        context.insert(tx2)
        try context.save()

        let summaries = try budgetService.budgetSummaries(for: monthKey)
        let s = summaries.first { $0.categoryId == cat.id }
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.spent, 80)
        XCTAssertEqual(s?.limit, 100)
        XCTAssertFalse(s!.isOver)
        XCTAssertTrue(s!.isNear)
    }

    func testMonthGrouping() throws {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: Date())

        let cats = try context.fetch(FetchDescriptor<Category>())
        guard let cat = cats.first else { XCTFail("No categories"); return }

        let d1 = calendar.date(byAdding: .day, value: -1, to: Date())!
        let d2 = calendar.date(byAdding: .day, value: -2, to: Date())!
        let tx1 = Transaction(type: .expense, amount: 10, currencyCode: "USD", categoryId: cat.id, date: d1)
        let tx2 = Transaction(type: .expense, amount: 20, currencyCode: "USD", categoryId: cat.id, date: d1)
        let tx3 = Transaction(type: .expense, amount: 30, currencyCode: "USD", categoryId: cat.id, date: d2)
        context.insert(tx1)
        context.insert(tx2)
        context.insert(tx3)
        try context.save()

        let txs = try transactionService.transactionsInMonth(monthKey, type: .expense)
        let grouped = transactionService.transactionsGroupedByDay(txs)
        XCTAssertEqual(grouped.count, 2)
        let day1 = grouped.first { calendar.isDate($0.date, inSameDayAs: d1) }
        XCTAssertEqual(day1?.items.count, 2)
    }

    func testCSVExportFormatting() throws {
        let cats = try context.fetch(FetchDescriptor<Category>())
        guard let cat = cats.first else { XCTFail("No categories"); return }
        let tx = Transaction(type: .expense, amount: 99.99, currencyCode: "USD", categoryId: cat.id, date: Date(), note: "Test")
        context.insert(tx)
        try context.save()

        let txs = try transactionService.allTransactions()
        let service = ExportImportService(modelContext: context)
        let data = try service.exportCSV(transactions: txs, categories: cats, currencyCode: "USD")
        let csv = String(data: data, encoding: .utf8)!
        XCTAssertTrue(csv.contains("Date,Type,Category,Amount,Note"))
        XCTAssertTrue(csv.contains("expense"))
        XCTAssertTrue(csv.contains("99.99"))
    }

    func testJSONBackupRestore() throws {
        let cats = try context.fetch(FetchDescriptor<Category>())
        guard let cat = cats.first else { XCTFail("No categories"); return }
        let tx = Transaction(type: .income, amount: 100, currencyCode: "USD", categoryId: cat.id, date: Date(), note: "Round trip")
        context.insert(tx)
        try context.save()

        let service = ExportImportService(modelContext: context)
        let data = try service.exportJSON()
        XCTAssertFalse(data.isEmpty)

        try context.delete(model: Transaction.self)
        try context.save()

        try service.importJSON(data, replaceExisting: false)
        let restored = try context.fetch(FetchDescriptor<Transaction>())
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored.first?.note, "Round trip")
    }

    func testCurrencyFormatting() {
        XCTAssertEqual(CurrencyFormatter.format(1234.56, currencyCode: "USD").contains("1"), true)
        XCTAssertEqual(CurrencyFormatter.symbol(for: "USD"), "$")
    }
}
