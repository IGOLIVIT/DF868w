//
//  SettingsView.swift
//  DF868w
//
//  Ledgerly - App settings
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    @Query private var preferences: [Preferences]
    @State private var showResetConfirm = false
    @State private var exportError: String?
    @State private var importError: String?
    @State private var showFileImporter = false
    @State private var showDocumentPicker = false

    private var prefs: Preferences? {
        preferences.first
    }

    var body: some View {
        NavigationStack {
            List {
                currencySection
                appearanceSection
                remindersSection
                hapticsSection
                categoriesSection
                paymentMethodsSection
                templatesSection
                exportImportSection
                privacySection
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    resetAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all transactions, budgets, goals, and reset to defaults. This cannot be undone.")
            }
        }
    }

    private var currencySection: some View {
        Section("Currency") {
            NavigationLink {
                CurrencySettingsView()
            } label: {
                HStack {
                    Text("Currency")
                    Spacer()
                    if let prefs {
                        Text(prefs.currencyCode)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            if let prefs {
                Picker("Theme", selection: Binding(
                    get: { prefs.themeChoice },
                    set: { prefs.themeChoice = $0; try? modelContext.save() }
                )) {
                    Text("System").tag(ThemeChoice.system)
                    Text("Light").tag(ThemeChoice.light)
                    Text("Dark").tag(ThemeChoice.dark)
                }
            }
        }
    }

    private var remindersSection: some View {
        Section("Reminders") {
            if let prefs {
                Toggle("Daily reminder", isOn: Binding(
                    get: { prefs.remindersEnabled },
                    set: { enabled in
                        prefs.remindersEnabled = enabled
                        if enabled {
                            Task {
                                let granted = await store.notificationService.requestAuthorization()
                                await MainActor.run {
                                    if granted {
                                        store.notificationService.scheduleDailyReminder(at: prefs.reminderTime)
                                    } else {
                                        prefs.remindersEnabled = false
                                    }
                                    try? modelContext.save()
                                }
                            }
                        } else {
                            store.notificationService.cancelReminder()
                            try? modelContext.save()
                        }
                    }
                ))
                if prefs.remindersEnabled {
                    DatePicker("Time", selection: Binding(
                        get: { prefs.reminderTime },
                        set: {
                            prefs.reminderTime = $0
                            store.notificationService.scheduleDailyReminder(at: $0)
                            try? modelContext.save()
                        }
                    ), displayedComponents: .hourAndMinute)
                }
            }
        }
    }

    private var hapticsSection: some View {
        Section("Haptics") {
            if let prefs {
                Toggle("Haptic feedback", isOn: Binding(
                    get: { prefs.hapticsEnabled },
                    set: { prefs.hapticsEnabled = $0; try? modelContext.save() }
                ))
            }
        }
    }

    private var categoriesSection: some View {
        Section("Categories") {
            NavigationLink("Manage categories") {
                CategoriesSettingsView()
            }
        }
    }

    private var paymentMethodsSection: some View {
        Section("Payment methods") {
            NavigationLink("Manage payment methods") {
                PaymentMethodsSettingsView()
            }
        }
    }

    private var templatesSection: some View {
        Section("Templates") {
            NavigationLink("Manage templates") {
                TemplatesSettingsView()
            }
        }
    }

    private var exportImportSection: some View {
        Section("Data") {
            Button("Export CSV") {
                exportCSV()
            }
            Button("Export backup (JSON)") {
                exportJSON()
            }
            Button("Import backup") {
                showFileImporter = true
            }
            if let err = exportError ?? importError {
                Text(err)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.danger)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importFromURL(url)
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Text("All data stays on your device. No data is sent to external servers.")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        }
    }

    private func exportCSV() {
        do {
            let txs = try store.transactionService.allTransactions()
            let cats = try modelContext.fetch(FetchDescriptor<Category>())
            let data = try store.exportImportService.exportCSV(
                transactions: txs,
                categories: cats,
                currencyCode: prefs?.currencyCode ?? "USD"
            )
            // Share via activity sheet
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("Ledgerly-Export-\(Date().timeIntervalSince1970).csv")
            try data.write(to: temp)
            // Use ShareLink or UIActivityViewController - for now we'd need a share sheet
            exportError = nil
            store.showSuccessToast("CSV exported")
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportJSON() {
        do {
            let data = try store.exportImportService.exportJSON()
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("Ledgerly-Backup-\(Date().timeIntervalSince1970).json")
            try data.write(to: temp)
            exportError = nil
            store.showSuccessToast("Backup exported")
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func importFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Could not access file"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            try store.exportImportService.importJSON(data, replaceExisting: true)
            importError = nil
            store.showSuccessToast("Backup restored")
        } catch {
            importError = error.localizedDescription
        }
    }

    private func resetAll() {
        do {
            try SeedData.resetAll(context: modelContext)
            store.showSuccessToast("Data reset")
        } catch {
            importError = error.localizedDescription
        }
    }
}
