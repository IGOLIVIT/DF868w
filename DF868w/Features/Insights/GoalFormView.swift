//
//  GoalFormView.swift
//  DF868w
//
//  Ledgerly - Add/Edit savings goal
//

import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    var editGoal: Goal?

    @State private var name = ""
    @State private var targetAmountText = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var addAmountText = ""
    @State private var validationError: String?

    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var targetAmount: Decimal? {
        Decimal(string: targetAmountText.replacingOccurrences(of: ",", with: ""))
    }

    private var addAmount: Decimal? {
        Decimal(string: addAmountText.replacingOccurrences(of: ",", with: ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                    TextField("Target amount", text: $targetAmountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                }

                if let goal = editGoal {
                    Section("Add to goal") {
                        TextField("Amount to add", text: $addAmountText)
                            .keyboardType(.decimalPad)
                        Button("Add") {
                            addToGoal(goal)
                        }
                        .disabled(addAmount == nil || (addAmount ?? 0) <= 0)
                    }
                }

                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(Theme.danger)
                            .font(Theme.caption)
                    }
                }
            }
            .navigationTitle(editGoal == nil ? "New goal" : "Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let g = editGoal {
                    name = g.name
                    targetAmountText = "\(g.targetAmount)"
                    targetDate = g.targetDate
                }
            }
        }
    }

    private func saveGoal() {
        validationError = nil
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Enter a goal name"
            return
        }
        guard let amt = targetAmount, amt > 0 else {
            validationError = "Enter a valid target amount"
            return
        }

        if let g = editGoal {
            g.name = name
            g.targetAmount = amt
            g.targetDate = targetDate
        } else {
            let goal = Goal(name: name, targetAmount: amt, targetDate: targetDate, currentAmount: 0)
            modelContext.insert(goal)
        }
        try? modelContext.save()
        store.showSuccessToast("Goal saved")
        dismiss()
    }

    private func addToGoal(_ goal: Goal) {
        guard let amt = addAmount, amt > 0 else { return }
        goal.currentAmount += amt
        try? modelContext.save()
        addAmountText = ""
        store.showSuccessToast("Added to goal")
    }
}
