//
//  TemplatesSettingsView.swift
//  DF868w
//
//  Ledgerly - Manage one-tap templates
//

import SwiftUI
import SwiftData

struct TemplatesSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStore.self) private var store
    @Query(sort: \Template.sortOrder) private var templates: [Template]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var preferences: [Preferences]
    @State private var showAdd = false
    @State private var editTemplate: Template?

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    var body: some View {
        List {
            ForEach(templates, id: \.id) { t in
                Button {
                    editTemplate = t
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.name)
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            Text("\(t.type.rawValue.capitalized) • \(categoryMap[t.categoryId]?.name ?? "?") • \(CurrencyFormatter.format(t.amountDecimal, currencyCode: currencyCode))")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(t)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editTemplate = nil
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            TemplateFormView(template: nil)
        }
        .sheet(isPresented: Binding(
            get: { editTemplate != nil },
            set: { if !$0 { editTemplate = nil } }
        )) {
            if let t = editTemplate {
                TemplateFormView(template: t)
            }
        }
    }
}


struct TemplateFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let template: Template?

    @State private var name = ""
    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var categoryId: UUID?
    @State private var paymentMethodId: UUID?

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]
    @Query private var preferences: [Preferences]

    private var currencyCode: String {
        preferences.first?.currencyCode ?? "USD"
    }

    private var amount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Type", selection: $type) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: Binding(
                    get: { categoryId ?? categories.first?.id },
                    set: { categoryId = $0 }
                )) {
                    ForEach(categories.filter { cat in
                        type == .expense ? !["Salary", "Freelance"].contains(cat.name) : true
                    }, id: \.id) { cat in
                        Label(cat.name, systemImage: cat.iconName).tag(cat.id)
                    }
                }
                Picker("Payment method", selection: $paymentMethodId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(paymentMethods, id: \.id) { pm in
                        Label(pm.name, systemImage: pm.iconName).tag(pm.id as UUID?)
                    }
                }
            }
            .navigationTitle(template == nil ? "New template" : "Edit template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty || amount == nil || (amount ?? 0) <= 0 || categoryId == nil)
                }
            }
            .onAppear {
                if let t = template {
                    name = t.name
                    type = t.type
                    amountText = "\(t.amountDecimal)"
                    categoryId = t.categoryId
                    paymentMethodId = t.paymentMethodId
                } else {
                    categoryId = categories.first { !["Salary", "Freelance"].contains($0.name) }?.id
                }
            }
        }
    }

    private func save() {
        guard let amt = amount, amt > 0, let catId = categoryId else { return }
        if let t = template {
            t.name = name
            t.type = type
            t.amountDecimal = amt
            t.categoryId = catId
            t.paymentMethodId = paymentMethodId
        } else {
            let order = (try? modelContext.fetch(FetchDescriptor<Template>()).count) ?? 0
            let newTemplate = Template(name: name, type: type, amount: amt, categoryId: catId, paymentMethodId: paymentMethodId, sortOrder: order)
            modelContext.insert(newTemplate)
        }
        try? modelContext.save()
        dismiss()
    }
}
