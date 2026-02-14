//
//  TransactionsView.swift
//  DF868w
//
//  Ledgerly - Transactions list with search and filters
//

import SwiftUI
import SwiftData

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case expenses = "Expenses"
    case income = "Income"
}

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    @State private var searchText = ""
    @State private var filter: TransactionFilter = .all
    @State private var selectedCategoryId: UUID?
    @State private var selectedPaymentMethodId: UUID?
    @State private var showAddTransaction = false
    @State private var transactionToEdit: Transaction?
    @State private var deletedTransactionCopy: Transaction?
    @State private var showUndoSnackbar = false

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]
    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var filteredTransactions: [Transaction] {
        (try? store.transactionService.transactions(
            type: filter == .all ? nil : (filter == .income ? .income : .expense),
            categoryId: selectedCategoryId,
            paymentMethodId: selectedPaymentMethodId,
            searchText: searchText.isEmpty ? nil : searchText
        )) ?? []
    }

    private var groupedByDay: [(date: Date, items: [Transaction])] {
        store.transactionService.transactionsGroupedByDay(filteredTransactions)
    }

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingS) {
                        ForEach(TransactionFilter.allCases, id: \.self) { f in
                            FilterChip(title: f.rawValue, isSelected: filter == f) {
                                filter = f
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, Theme.spacingS)

                if filteredTransactions.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No transactions",
                        message: searchText.isEmpty ? "Add your first transaction to get started." : "No transactions match your search.",
                        actionTitle: searchText.isEmpty ? "Add Transaction" : nil,
                        action: searchText.isEmpty ? { showAddTransaction = true } : nil
                    )
                } else {
                    List {
                        ForEach(groupedByDay, id: \.date) { group in
                            Section {
                                ForEach(group.items, id: \.id) { tx in
                                    NavigationLink(value: tx) {
                                        TransactionRowView(
                                            transaction: tx,
                                            categoryName: categoryMap[tx.categoryId]?.name ?? "Unknown",
                                            currencyCode: currencyCode
                                        )
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteWithUndo(tx)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            duplicateTransaction(tx)
                                        } label: {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }
                                        .tint(Theme.accent)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            transactionToEdit = tx
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Theme.accent)
                                    }
                                }
                            } header: {
                                Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                    .listStyle(.plain)
    #if os(iOS)
                    .searchable(text: $searchText, prompt: "Search by note or tag")
    #endif
                }
            }
            .navigationTitle("Transactions")
            .navigationDestination(for: Transaction.self) { tx in
                TransactionDetailView(transaction: tx)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        transactionToEdit = nil
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { showAddTransaction || transactionToEdit != nil },
                set: { if !$0 { showAddTransaction = false; transactionToEdit = nil } }
            )) {
                TransactionFormView(editTransaction: transactionToEdit)
                    .onDisappear { transactionToEdit = nil }
            }
            .overlay(alignment: .bottom) {
                if showUndoSnackbar, deletedTransactionCopy != nil {
                    UndoSnackbar(message: "Transaction deleted") {
                        undoDelete()
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }

    private func deleteWithUndo(_ tx: Transaction) {
        let copy = Transaction(
            type: tx.type,
            amount: tx.amountDecimal,
            currencyCode: tx.currencyCode,
            categoryId: tx.categoryId,
            date: tx.date,
            note: tx.note,
            paymentMethodId: tx.paymentMethodId,
            tags: tx.tags
        )
        deletedTransactionCopy = copy
        do {
            try store.transactionService.delete(tx)
            withAnimation { showUndoSnackbar = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showUndoSnackbar = false }
                deletedTransactionCopy = nil
            }
        } catch {
            deletedTransactionCopy = nil
        }
    }

    private func undoDelete() {
        guard let copy = deletedTransactionCopy else { return }
        do {
            try store.transactionService.create(copy)
            store.showSuccessToast("Transaction restored")
        } catch {}
        withAnimation { showUndoSnackbar = false }
        deletedTransactionCopy = nil
    }

    private func duplicateTransaction(_ tx: Transaction) {
        do {
            _ = try store.transactionService.duplicate(tx)
            store.showSuccessToast("Transaction duplicated")
        } catch {}
    }
}

struct UndoSnackbar: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(Theme.callout)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Button("Undo", action: onUndo)
                .font(Theme.headline)
                .foregroundStyle(Theme.accent)
        }
        .padding(Theme.spacingL)
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
        .shadow(radius: 8)
    }
}
