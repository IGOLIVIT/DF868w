//
//  InsightsView.swift
//  DF868w
//
//  Ledgerly - Charts, budgets, goals
//

import SwiftUI
import SwiftData
import Charts

enum InsightsTab: String, CaseIterable {
    case charts = "Charts"
    case budgets = "Budgets"
    case goals = "Goals"
}

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    @State var initialTab: InsightsTab = .charts
    @State private var selectedTab: InsightsTab = .charts

    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var monthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(InsightsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    ChartsSection(currencyCode: currencyCode)
                        .tag(InsightsTab.charts)
                    BudgetsSection(currencyCode: currencyCode, monthKey: monthKey)
                        .tag(InsightsTab.budgets)
                    GoalsSection(currencyCode: currencyCode)
                        .tag(InsightsTab.goals)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Theme.primaryBackground)
            .navigationTitle("Insights")
            .onAppear {
                selectedTab = initialTab
            }
        }
    }
}

struct ChartsSection: View {
    @Environment(AppStore.self) private var store
    let currencyCode: String

    private var monthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                monthlyExpenseChart
                categoryDonutChart
                categoryAnalyticsSection
                incomeVsExpenseChart
            }
            .padding()
        }
    }

    private var categoryAnalyticsSection: some View {
        let data = store.chartDataBuilder.categoryBreakdown(monthKey: monthKey)
        let prevMonthKey: String = {
            let cal = Calendar.current
            guard let d = cal.date(byAdding: .month, value: -1, to: Date()) else { return "" }
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM"
            return f.string(from: d)
        }()
        let prevData = store.chartDataBuilder.categoryBreakdown(monthKey: prevMonthKey)
        let prevMap = Dictionary(uniqueKeysWithValues: prevData.map { ($0.id, $0.amount) })

        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Top categories")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                if data.isEmpty {
                    Text("No expense data.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    ForEach(data.prefix(5)) { item in
                        let prevAmount = prevMap[item.id] ?? 0
                        let trend = prevAmount > 0 ? (item.amount - prevAmount) / prevAmount : Decimal(0)
                        NavigationLink {
                            CategoryDetailView(categoryId: item.id, categoryName: item.name, currencyCode: currencyCode, monthKey: monthKey)
                        } label: {
                            HStack {
                                Text(item.name)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                Spacer()
                                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                                    .font(Theme.callout)
                                    .foregroundStyle(Theme.secondaryText)
                                if trend != 0 {
                                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.caption2)
                                        .foregroundStyle(trend > 0 ? Theme.danger : Theme.success)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var monthlyExpenseChart: some View {
        let data = store.chartDataBuilder.monthlyExpenseLineData(monthKey: monthKey)
        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Daily expenses")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                if data.isEmpty {
                    Text("No expense data this month.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(height: 120)
                } else {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                        )
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 160)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly expense chart. Total of \(data.count) days of data.")
    }

    private var categoryDonutChart: some View {
        let data = store.chartDataBuilder.categoryBreakdown(monthKey: monthKey)
        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Category breakdown")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                if data.isEmpty {
                    Text("No expense data this month.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(height: 160)
                } else {
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Amount", NSDecimalNumber(decimal: item.amount).doubleValue),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("Category", item.name))
                    }
                    .frame(height: 200)
                    .chartLegend(.hidden)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(data.prefix(5)) { item in
                            HStack {
                                Text(item.name)
                                    .font(Theme.caption)
                                Spacer()
                                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category breakdown. Top category: \(data.first?.name ?? "none")")
    }

    private var incomeVsExpenseChart: some View {
        let data = store.chartDataBuilder.incomeVsExpenseBarData(months: 6)
        struct ChartPoint: Identifiable {
            let id = UUID()
            let month: String
            let type: String
            let value: Double
        }
        let points = data.flatMap { item -> [ChartPoint] in
            [
                ChartPoint(month: item.label, type: "Income", value: NSDecimalNumber(decimal: item.income).doubleValue),
                ChartPoint(month: item.label, type: "Expense", value: NSDecimalNumber(decimal: item.expense).doubleValue)
            ]
        }
        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                Text("Income vs expense")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                if data.isEmpty {
                    Text("No data.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(height: 120)
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Month", point.month),
                            y: .value("Amount", point.value)
                        )
                        .foregroundStyle(by: .value("Type", point.type))
                    }
                    .chartForegroundStyleScale([
                        "Income": Theme.success,
                        "Expense": Theme.danger
                    ])
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Income vs expense bar chart for last 6 months")
    }
}

struct BudgetsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    let currencyCode: String
    let monthKey: String

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    private var summaries: [BudgetSummary] {
        (try? store.budgetService.budgetSummaries(for: monthKey)) ?? []
    }

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                if summaries.isEmpty {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: "No budgets",
                        message: "Set up budgets in onboarding or add them here."
                    )
                } else {
                    ForEach(summaries, id: \.categoryId) { s in
                        BudgetRowView(
                            summary: s,
                            categoryName: categoryMap[s.categoryId]?.name ?? "Unknown",
                            currencyCode: currencyCode
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct BudgetRowView: View {
    let summary: BudgetSummary
    let categoryName: String
    let currencyCode: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Text(categoryName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text("\(Int(truncating: min(summary.percentage, 1) * 100 as NSDecimalNumber))%")
                        .font(Theme.caption)
                        .foregroundStyle(summary.isOver ? Theme.danger : Theme.secondaryText)
                }
                ProgressView(value: min(Double(truncating: summary.percentage as NSDecimalNumber), 1.2))
                    .tint(summary.isOver ? Theme.danger : (summary.isNear ? Theme.warning : Theme.accent))
                HStack {
                    Text(CurrencyFormatter.format(summary.spent, currencyCode: currencyCode))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text("of")
                        .font(Theme.caption2)
                        .foregroundStyle(Theme.secondaryText)
                    Text(CurrencyFormatter.format(summary.limit, currencyCode: currencyCode))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                if summary.isNear {
                    Text("You're near limit")
                        .font(Theme.caption2)
                        .foregroundStyle(Theme.warning)
                }
                if summary.isOver {
                    Text("Over budget")
                        .font(Theme.caption2)
                        .foregroundStyle(Theme.danger)
                }
            }
        }
    }
}

struct GoalsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    let currencyCode: String

    @Query(sort: \Goal.sortOrder) private var goals: [Goal]
    @State private var showAddGoal = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                if goals.isEmpty {
                    EmptyStateView(
                        icon: "flag.checkered",
                        title: "No goals yet",
                        message: "Set savings goals and track your progress.",
                        actionTitle: "Add goal",
                        action: { showAddGoal = true }
                    )
                } else {
                    ForEach(goals.prefix(3), id: \.id) { goal in
                        GoalRowView(goal: goal, currencyCode: currencyCode)
                    }
                    if goals.count < 3 {
                        Button {
                            showAddGoal = true
                        } label: {
                            Label("Add goal", systemImage: "plus.circle")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddGoal) {
            GoalFormView()
        }
    }
}

struct GoalRowView: View {
    let goal: Goal
    let currencyCode: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Text(goal.name)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text("\(Int(truncating: goal.progress * 100 as NSDecimalNumber))%")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                ProgressView(value: Double(truncating: goal.progress as NSDecimalNumber))
                    .tint(Theme.success)
                HStack {
                    Text(CurrencyFormatter.format(goal.currentAmount, currencyCode: currencyCode))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.success)
                    Text("of")
                        .font(Theme.caption2)
                        .foregroundStyle(Theme.secondaryText)
                    Text(CurrencyFormatter.format(goal.targetAmount, currencyCode: currencyCode))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Text("Target: \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.caption2)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
