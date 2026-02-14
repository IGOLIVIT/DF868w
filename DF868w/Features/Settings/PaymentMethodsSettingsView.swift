//
//  PaymentMethodsSettingsView.swift
//  DF868w
//
//  Ledgerly - Manage payment methods
//

import SwiftUI
import SwiftData

struct PaymentMethodsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PaymentMethod.sortOrder) private var methods: [PaymentMethod]
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(methods, id: \.id) { pm in
                HStack {
                    Image(systemName: pm.iconName)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 24)
                    Text(pm.name)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(pm)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Payment methods")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPaymentMethodView()
        }
    }
}

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var iconName = "creditcard"

    private let icons = ["banknote", "creditcard", "arrow.left.arrow.right", "dollarsign", "building.columns"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Icon", selection: $iconName) {
                    ForEach(icons, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }
            }
            .navigationTitle("New payment method")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let order = (try? modelContext.fetch(FetchDescriptor<PaymentMethod>()).count) ?? 0
                        let pm = PaymentMethod(name: name, iconName: iconName, sortOrder: order)
                        modelContext.insert(pm)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
