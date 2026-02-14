//
//  WeeklyReviewCard.swift
//  DF868w
//
//  Ledgerly - Weekly money review
//

import SwiftUI
import SwiftData

struct WeeklyReviewCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    let currencyCode: String

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    private var calendar: Calendar { Calendar.current }

    private var weekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
    }

    private var weekTransactions: [Transaction] {
        (try? store.transactionService.transactions(from: weekStart, to: weekEnd, type: .expense)) ?? []
    }

    private var totalSpent: Decimal {
        weekTransactions.reduce(Decimal(0)) { $0 + $1.amountDecimal }
    }

    private var avgDailySpend: Decimal {
        let days = max(1, calendar.dateComponents([.day], from: weekStart, to: min(Date(), weekEnd)).day ?? 1)
        return totalSpent / Decimal(days)
    }

    private var biggestCategory: (name: String, amount: Decimal)? {
        let cats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        let map = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        let byCat = Dictionary(grouping: weekTransactions, by: \.categoryId)
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amountDecimal } }
        return byCat.max(by: { $0.value < $1.value }).map { (map[$0.key] ?? "Other", $0.value) }
    }

    private var bestDay: (date: Date, amount: Decimal)? {
        let byDay = Dictionary(grouping: weekTransactions) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amountDecimal } }
        return byDay.min(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.spacingM) {
                HStack {
                    Text("Weekly money review")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Button {
                        saveAsImage()
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.accent)
                    }
                }

                Text("\(weekStart.formatted(date: .abbreviated, time: .omitted)) – \(weekEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)

                if weekTransactions.isEmpty {
                    Text("No expenses this week yet.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        if let biggest = biggestCategory {
                            HStack {
                                Text("Biggest category:")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Spacer()
                                Text("\(biggest.name) – \(CurrencyFormatter.format(biggest.amount, currencyCode: currencyCode))")
                                    .font(Theme.callout)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                        HStack {
                            Text("Avg daily spend:")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Spacer()
                            Text(CurrencyFormatter.format(avgDailySpend, currencyCode: currencyCode))
                                .font(Theme.callout)
                                .foregroundStyle(Theme.primaryText)
                        }
                        if let best = bestDay, totalSpent > 0 {
                            HStack {
                                Text("Lowest spend day:")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Spacer()
                                Text("\(best.date.formatted(date: .abbreviated, time: .omitted)) – \(CurrencyFormatter.format(best.amount, currencyCode: currencyCode))")
                                    .font(Theme.callout)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    private func saveAsImage() {
        let view = WeeklyReviewShareView(
            weekStart: weekStart,
            weekEnd: weekEnd,
            totalSpent: totalSpent,
            avgDailySpend: avgDailySpend,
            biggestCategory: biggestCategory,
            bestDay: bestDay,
            currencyCode: currencyCode
        )
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: 340, height: 280)
        shareImage = renderer.uiImage
    }
}

struct WeeklyReviewShareView: View {
    let weekStart: Date
    let weekEnd: Date
    let totalSpent: Decimal
    let avgDailySpend: Decimal
    let biggestCategory: (name: String, amount: Decimal)?
    let bestDay: (date: Date, amount: Decimal)?
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Ledgerly – Weekly Review")
                .font(Theme.titleSmall)
                .foregroundStyle(Theme.primaryText)
            Text("\(weekStart.formatted(date: .abbreviated, time: .omitted)) – \(weekEnd.formatted(date: .abbreviated, time: .omitted))")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
            Divider()
            Text("Total spent: \(CurrencyFormatter.format(totalSpent, currencyCode: currencyCode))")
                .font(Theme.headline)
            Text("Avg daily: \(CurrencyFormatter.format(avgDailySpend, currencyCode: currencyCode))")
                .font(Theme.body)
            if let b = biggestCategory {
                Text("Biggest: \(b.name) (\(CurrencyFormatter.format(b.amount, currencyCode: currencyCode)))")
                    .font(Theme.body)
            }
        }
        .padding(Theme.spacingXL)
        .frame(width: 340, height: 280)
        .background(Theme.primaryBackground)
    }
}
