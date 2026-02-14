//
//  TransactionFormView.swift
//  DF868w
//
//  Ledgerly - Add/Edit transaction form
//

import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    var editTransaction: Transaction?

    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategoryId: UUID?
    @State private var date = Date()
    @State private var note = ""
    @State private var selectedPaymentMethodId: UUID?
    @State private var tagsText = ""
    @State private var validationError: String?

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]
    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var amount: Decimal? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: currencySymbol, with: "").trimmingCharacters(in: .whitespaces)
        return Decimal(string: cleaned)
    }

    private var currencySymbol: String {
        CurrencyFormatter.symbol(for: currencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Amount") {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(Theme.secondaryText)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(Theme.titleMedium)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { selectedCategoryId ?? categories.first?.id },
                        set: { selectedCategoryId = $0 }
                    )) {
                        ForEach(categories.filter { cat in
                            type == .expense ? !["Salary", "Freelance"].contains(cat.name) : true
                        }, id: \.id) { cat in
                            Label(cat.name, systemImage: cat.iconName)
                                .tag(cat.id as UUID?)
                        }
                    }
                }

                Section("Date & time") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Payment method") {
                    Picker("Payment", selection: $selectedPaymentMethodId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(paymentMethods, id: \.id) { pm in
                            Label(pm.name, systemImage: pm.iconName)
                                .tag(pm.id as UUID?)
                        }
                    }
                }

                Section("Tags") {
                    TextField("e.g. work, personal", text: $tagsText)
                }

                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(Theme.danger)
                            .font(Theme.caption)
                    }
                }
            }
            .navigationTitle(editTransaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let tx = editTransaction {
                    type = tx.type
                    amountText = "\(tx.amountDecimal)"
                    selectedCategoryId = tx.categoryId
                    date = tx.date
                    note = tx.note
                    selectedPaymentMethodId = tx.paymentMethodId
                    tagsText = tx.tags.joined(separator: ", ")
                } else {
                    selectedCategoryId = store.transactionService.lastUsedCategory(for: type) ?? categories.first { type == .expense ? !["Salary", "Freelance"].contains($0.name) : true }?.id
                }
            }
        }
    }

    private func saveTransaction() {
        validationError = nil

        guard let amt = amount, amt > 0 else {
            validationError = "Please enter a valid amount"
            return
        }
        guard let catId = selectedCategoryId else {
            validationError = "Please select a category"
            return
        }

        if let tx = editTransaction {
            tx.type = type
            tx.amountDecimal = amt
            tx.categoryId = catId
            tx.date = date
            tx.note = note
            tx.paymentMethodId = selectedPaymentMethodId
            tx.tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            do {
                try store.transactionService.update(tx)
            } catch {
                validationError = "Could not save: \(error.localizedDescription)"
                return
            }
        } else {
            let tx = Transaction(
                type: type,
                amount: amt,
                currencyCode: currencyCode,
                categoryId: catId,
                date: date,
                note: note,
                paymentMethodId: selectedPaymentMethodId,
                tags: tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            )
            do {
                try store.transactionService.create(tx)
            } catch {
                validationError = "Could not save: \(error.localizedDescription)"
                return
            }
        }

        if preferences.first?.hapticsEnabled ?? true {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        store.showSuccessToast(editTransaction == nil ? "Transaction added" : "Transaction updated")
        dismiss()
    }
}
