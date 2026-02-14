//
//  LedgerlyWidgets.swift
//  LedgerlyWidgets
//
//  Ledgerly - Widget extension
//

import WidgetKit
import SwiftUI

// App Group for sharing data with main app
let appGroupId = "group.ioi.df868w.ledgerly"

struct MonthSummaryEntry: TimelineEntry {
    let date: Date
    let income: Double
    let expense: Double
    let net: Double
    let currencyCode: String
}

struct MonthSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthSummaryEntry {
        MonthSummaryEntry(date: Date(), income: 0, expense: 0, net: 0, currencyCode: "USD")
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthSummaryEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthSummaryEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> MonthSummaryEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let income = defaults?.double(forKey: "widget_income") ?? 0
        let expense = defaults?.double(forKey: "widget_expense") ?? 0
        let currencyCode = defaults?.string(forKey: "widget_currency") ?? "USD"
        return MonthSummaryEntry(
            date: Date(),
            income: income,
            expense: expense,
            net: income - expense,
            currencyCode: currencyCode
        )
    }
}

struct MonthSummaryWidgetView: View {
    var entry: MonthSummaryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This month")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(format(entry.income))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expense")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(format(entry.expense))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            Divider()
            HStack {
                Text("Net")
                    .font(.caption)
                Spacer()
                Text(format(entry.net))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.net >= 0 ? .green : .red)
            }
        }
        .padding()
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

struct QuickAddWidgetView: View {
    var body: some View {
        Link(destination: URL(string: "ledgerly://add-expense")!) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                Text("Add expense")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct LedgerlyWidgets: Widget {
    let kind: String = "LedgerlyWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthSummaryProvider()) { entry in
            MonthSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Month Summary")
        .description("See your income, expense, and net for this month.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { _ in
            QuickAddWidgetView()
        }
        .configurationDisplayName("Quick Add")
        .description("Tap to add an expense quickly.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthSummaryEntry {
        MonthSummaryEntry(date: Date(), income: 0, expense: 0, net: 0, currencyCode: "USD")
    }
    func getSnapshot(in context: Context, completion: @escaping (MonthSummaryEntry) -> Void) {
        completion(MonthSummaryEntry(date: Date(), income: 0, expense: 0, net: 0, currencyCode: "USD"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthSummaryEntry>) -> Void) {
        completion(Timeline(entries: [MonthSummaryEntry(date: Date(), income: 0, expense: 0, net: 0, currencyCode: "USD")], policy: .never))
    }
}

@main
struct LedgerlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LedgerlyWidgets()
        QuickAddWidget()
    }
}
