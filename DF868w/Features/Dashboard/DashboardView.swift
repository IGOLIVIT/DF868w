//
//  DashboardView.swift
//  DF868w
//
//  Ledgerly - Home dashboard
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    @State private var showAddTransaction = false
    @State private var quickAddType: TransactionType = .expense

    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var monthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: Date())
    }

    private var monthTransactions: [Transaction] {
        (try? store.transactionService.transactionsInMonth(monthKey)) ?? []
    }

    private var income: Decimal {
        store.transactionService.totalIncome(for: monthTransactions)
    }

    private var expense: Decimal {
        store.transactionService.totalExpense(for: monthTransactions)
    }

    private var net: Decimal {
        store.transactionService.net(for: monthTransactions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    balanceCard
                    budgetOverviewCard
                    quickAddSection
                    weeklyReviewCard
                }
                .padding()
            }
            .background(Theme.primaryBackground)
            .navigationTitle("Ledgerly")
            .sheet(isPresented: $showAddTransaction) {
                TransactionFormView()
            }
            .onAppear {
                updateWidgetData()
            }
            .onChange(of: showAddTransaction) { _, isShowing in
                if !isShowing { updateWidgetData() }
            }
        }
    }

    private func updateWidgetData() {
        let income = NSDecimalNumber(decimal: self.income).doubleValue
        let expense = NSDecimalNumber(decimal: self.expense).doubleValue
        WidgetDataService.updateMonthSummary(income: income, expense: expense, currencyCode: currencyCode)
    }

    private var balanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("This month")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.secondaryText)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(CurrencyFormatter.format(income, currencyCode: currencyCode))
                            .font(Theme.titleSmall)
                            .foregroundStyle(Theme.success)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Expense")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(CurrencyFormatter.format(expense, currencyCode: currencyCode))
                            .font(Theme.titleSmall)
                            .foregroundStyle(Theme.danger)
                    }
                }

                Divider()
                    .background(Theme.divider)

                HStack {
                    Text("Net")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(CurrencyFormatter.format(net, currencyCode: currencyCode))
                        .font(Theme.titleMedium)
                        .foregroundStyle(net >= 0 ? Theme.success : Theme.danger)
                        .contentTransition(.numericText())
                }

                PrimaryButton("Add transaction", icon: "plus") {
                    showAddTransaction = true
                }
                .padding(.top, Theme.spacingS)
            }
        }
    }

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    private var budgetOverviewCard: some View {
        Group {
            if preferences.first?.budgetsEnabled ?? true {
                let summaries = (try? store.budgetService.budgetSummaries(for: monthKey)) ?? []
                let totalPercent = store.budgetService.totalBudgetSpentPercent(for: monthKey)
                let overspent = store.budgetService.topOverspentCategories(for: monthKey, limit: 3)

                if !summaries.isEmpty {
                    NavigationLink {
                        InsightsView(initialTab: .budgets)
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Theme.spacingM) {
                                HStack {
                                    Text("Budget overview")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    Spacer()
                                    Text("\(Int(truncating: totalPercent as NSNumber) * 100)%")
                                        .font(Theme.titleSmall)
                                        .foregroundStyle(totalPercent > 1 ? Theme.danger : Theme.primaryText)
                                }
                                ProgressView(value: min(Double(truncating: totalPercent as NSNumber), 1))
                                    .tint(totalPercent > 1 ? Theme.danger : Theme.accent)

                                if !overspent.isEmpty {
                                    Text("Near or over budget:")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                    ForEach(overspent.prefix(3), id: \.categoryId) { s in
                                        HStack {
                                            Text(categoryMap[s.categoryId]?.name ?? "Category")
                                                .font(Theme.caption2)
                                            Spacer()
                                            Text(CurrencyFormatter.format(s.spent - s.limit, currencyCode: currencyCode))
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.danger)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Quick add")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)

            HStack(spacing: Theme.spacingM) {
                Button {
                    quickAddType = .expense
                    showAddTransaction = true
                } label: {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.danger)
                        Text("Expense")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingL)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
                }
                .buttonStyle(.plain)

                Button {
                    quickAddType = .income
                    showAddTransaction = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.success)
                        Text("Income")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingL)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
                }
                .buttonStyle(.plain)
            }

            QuickAddTemplatesView()
        }
    }

    private var weeklyReviewCard: some View {
        WeeklyReviewCard(currencyCode: currencyCode)
    }
}

struct QuickAddTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    var onSelectTemplate: (() -> Void)?

    @Query(sort: \Template.sortOrder) private var templates: [Template]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    var body: some View {
        if !templates.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(templates.prefix(6), id: \.id) { t in
                    Button {
                        applyTemplate(t)
                    } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t.name)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.primaryText)
                                    .lineLimit(1)
                                Text(CurrencyFormatter.format(t.amountDecimal, currencyCode: currencyCode))
                                    .font(Theme.caption2)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.horizontal, Theme.spacingM)
                            .padding(.vertical, Theme.spacingS)
                            .background(Theme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func applyTemplate(_ t: Template) {
        let tx = Transaction(
            type: t.type,
            amount: t.amountDecimal,
            currencyCode: currencyCode,
            categoryId: t.categoryId,
            date: Date(),
            note: t.name,
            paymentMethodId: t.paymentMethodId,
            templateId: t.id
        )
        try? store.transactionService.create(tx)
        if preferences.first?.hapticsEnabled ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        store.showSuccessToast("\(t.name) added")
    }
}
