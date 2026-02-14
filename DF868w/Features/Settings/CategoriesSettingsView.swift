//
//  CategoriesSettingsView.swift
//  DF868w
//
//  Ledgerly - Manage categories
//

import SwiftUI
import SwiftData

struct CategoriesSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showAddCategory = false

    var body: some View {
        List {
            ForEach(categories, id: \.id) { cat in
                HStack {
                    Image(systemName: cat.iconName)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 24)
                    Text(cat.name)
                    Spacer()
                    if cat.isSystem {
                        Text("Default")
                            .font(Theme.caption2)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !cat.isSystem {
                        Button(role: .destructive) {
                            modelContext.delete(cat)
                            try? modelContext.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var iconName = "tag"
    @State private var colorKey = "gray"

    private let icons = ["cart.fill", "car.fill", "cup.and.saucer.fill", "house.fill", "heart.fill", "bag.fill", "ticket.fill", "book.fill", "airplane", "doc.text.fill", "tag", "ellipsis.circle.fill"]
    private let colors = ["green", "blue", "brown", "indigo", "red", "purple", "orange", "teal", "cyan", "gray"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Icon", selection: $iconName) {
                    ForEach(icons, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }
                Picker("Color", selection: $colorKey) {
                    ForEach(colors, id: \.self) { c in
                        Text(c).tag(c)
                    }
                }
            }
            .navigationTitle("New category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let order = (try? modelContext.fetch(FetchDescriptor<Category>()).count) ?? 0
                        let cat = Category(name: name, iconName: iconName, colorKey: colorKey, isSystem: false, sortOrder: order)
                        modelContext.insert(cat)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
