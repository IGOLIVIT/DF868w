//
//  TransactionDetailView.swift
//  DF868w
//
//  Ledgerly - Transaction detail with edit/delete/share
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store

    let transaction: Transaction
    @State private var category: Category?
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var receiptImage: UIImage?

    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(transaction.type == .income ? "Income" : "Expense")
                        .font(Theme.headline)
                    Spacer()
                    Text(CurrencyFormatter.format(transaction.amountDecimal, currencyCode: currencyCode))
                        .font(Theme.titleMedium)
                        .foregroundStyle(transaction.type == .income ? Theme.success : Theme.danger)
                }
                if let cat = category {
                    HStack {
                        Label(cat.name, systemImage: cat.iconName)
                        Spacer()
                    }
                }
                HStack {
                    Text("Date")
                    Spacer()
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(Theme.secondaryText)
                }
                if !transaction.note.isEmpty {
                    HStack(alignment: .top) {
                        Text("Note")
                        Spacer()
                        Text(transaction.note)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.trailing)
                    }
                }
                if !transaction.tags.isEmpty {
                    HStack {
                        Text("Tags")
                        Spacer()
                        Text(transaction.tags.joined(separator: ", "))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            Section {
                Button {
                    showEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    duplicateTransaction()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    generateReceiptImage()
                    showShareSheet = true
                } label: {
                    Label("Share as image", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            TransactionFormView(editTransaction: transaction)
        }
        .confirmationDialog("Delete transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = receiptImage {
                ShareSheet(items: [img])
            }
        }
        .onAppear {
            loadCategory()
        }
    }

    private func loadCategory() {
        let catId = transaction.categoryId
        var desc = FetchDescriptor<Category>(predicate: #Predicate<Category> { $0.id == catId })
        desc.fetchLimit = 1
        category = try? modelContext.fetch(desc).first
    }

    private func duplicateTransaction() {
        do {
            _ = try store.transactionService.duplicate(transaction)
            store.showSuccessToast("Transaction duplicated")
            dismiss()
        } catch {
            store.showSuccessToast("Could not duplicate")
        }
    }

    private func deleteTransaction() {
        do {
            try store.transactionService.delete(transaction)
            store.showSuccessToast("Transaction deleted")
            dismiss()
        } catch {}
    }

    @MainActor
    private func generateReceiptImage() {
        let view = ReceiptView(transaction: transaction, category: category, currencyCode: currencyCode)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: 340, height: 400)
        receiptImage = renderer.uiImage
    }
}

struct ReceiptView: View {
    let transaction: Transaction
    let category: Category?
    let currencyCode: String

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Text("Ledgerly")
                .font(Theme.titleSmall)
                .foregroundStyle(Theme.primaryText)
            Text("Receipt")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)

            Divider()

            HStack {
                Text(transaction.type == .income ? "Income" : "Expense")
                Spacer()
                Text(CurrencyFormatter.format(transaction.amountDecimal, currencyCode: currencyCode))
                    .font(Theme.titleMedium)
            }
            if let cat = category {
                HStack {
                    Text("Category")
                    Spacer()
                    Text(cat.name)
                }
            }
            HStack {
                Text("Date")
                Spacer()
                Text(transaction.date.formatted(date: .long, time: .shortened))
            }
            if !transaction.note.isEmpty {
                HStack(alignment: .top) {
                    Text("Note")
                    Spacer()
                    Text(transaction.note)
                }
            }

            Spacer()
        }
        .padding(Theme.spacingXL)
        .frame(width: 340, height: 400)
        .background(Theme.primaryBackground)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
