//
//  OnboardingView.swift
//  DF868w
//
//  Ledgerly - 4-screen onboarding flow
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    @State private var currentPage = 0
    @State private var selectedCurrency = "USD"
    @State private var budgetsEnabled = true
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationPermissionGranted = false

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            currencyPage.tag(1)
            budgetsPage.tag(2)
            reminderPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .background(Theme.primaryBackground)
    }

    private var welcomePage: some View {
        VStack(spacing: Theme.spacingXL) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)
            Text("Ledgerly")
                .font(Theme.titleLarge)
                .foregroundStyle(Theme.primaryText)
            Text("Track money in 10 seconds a day.")
                .font(Theme.title3)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton("Get Started") {
                withAnimation { currentPage = 1 }
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
    }

    private var currencyPage: some View {
        VStack(spacing: Theme.spacingXL) {
            Text("Choose currency")
                .font(Theme.titleMedium)
                .foregroundStyle(Theme.primaryText)
            Text("We'll use this for all amounts.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)

            ForEach(CurrencyFormatter.supportedCurrencies, id: \.code) { item in
                Button {
                    selectedCurrency = item.code
                } label: {
                    HStack {
                        Text(item.code)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        Text(item.name)
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                        Spacer()
                        if selectedCurrency == item.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(Theme.spacingL)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            Spacer()
            PrimaryButton("Continue") {
                savePreferences()
                withAnimation { currentPage = 2 }
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .padding(.top, Theme.spacingXL)
    }

    private var budgetsPage: some View {
        VStack(spacing: Theme.spacingXL) {
            Text("Set up budgets")
                .font(Theme.titleMedium)
                .foregroundStyle(Theme.primaryText)
            Text("Get gentle alerts when you're near your limits.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Toggle("I want budgets", isOn: $budgetsEnabled)
                .padding(Theme.spacingL)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))

            if budgetsEnabled {
                Text("We'll create default budgets for your top categories. You can customize them later.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer()
            PrimaryButton("Continue") {
                savePreferences()
                if budgetsEnabled {
                    createDefaultBudgets()
                }
                withAnimation { currentPage = 3 }
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .padding(.horizontal, Theme.spacingXL)
        .padding(.top, Theme.spacingXL)
    }

    private var reminderPage: some View {
        VStack(spacing: Theme.spacingXL) {
            Text("Daily reminder")
                .font(Theme.titleMedium)
                .foregroundStyle(Theme.primaryText)
            Text("Optional: get a daily nudge to log your spending.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Toggle("Enable reminder", isOn: $reminderEnabled)
                .padding(Theme.spacingL)
                .background(Theme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))

            if reminderEnabled {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .padding(Theme.spacingL)
                    .background(Theme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
            }

            Spacer()
            PrimaryButton("Start Using Ledgerly") {
                completeOnboarding()
            }
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingXXL)
        }
        .padding(.horizontal, Theme.spacingXL)
        .padding(.top, Theme.spacingXL)
    }

    private func savePreferences() {
        var prefs = try? modelContext.fetch(FetchDescriptor<Preferences>()).first
        if prefs == nil {
            prefs = Preferences(currencyCode: selectedCurrency, budgetsEnabled: budgetsEnabled)
            modelContext.insert(prefs!)
        } else {
            prefs?.currencyCode = selectedCurrency
            prefs?.budgetsEnabled = budgetsEnabled
        }
        try? modelContext.save()
    }

    private func createDefaultBudgets() {
        let cats = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        let sorted = cats.filter { !$0.name.contains("Salary") && !$0.name.contains("Freelance") }.prefix(5)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: Date())

        for (index, cat) in sorted.enumerated() {
            let limit: Decimal = [200, 150, 100, 80, 50][min(index, 4)] * 10
            let budget = Budget(categoryId: cat.id, monthKey: monthKey, limit: limit)
            modelContext.insert(budget)
        }
        try? modelContext.save()
    }

    private func completeOnboarding() {
        savePreferences()

        if reminderEnabled {
            Task {
                let granted = await store.notificationService.requestAuthorization()
                await MainActor.run {
                    if granted {
                        store.notificationService.scheduleDailyReminder(at: reminderTime)
                        let prefs = try? modelContext.fetch(FetchDescriptor<Preferences>()).first
                        prefs?.remindersEnabled = true
                        prefs?.reminderTime = reminderTime
                        try? modelContext.save()
                    }
                }
            }
        }

        if let prefs = try? modelContext.fetch(FetchDescriptor<Preferences>()).first {
            prefs.onboardingCompleted = true
            prefs.budgetsEnabled = budgetsEnabled
        }
        try? modelContext.save()

        store.isOnboardingComplete = true
    }
}

#Preview {
    OnboardingView()
        .environment(AppStore(modelContext: ModelContainer.preview.mainContext))
}
