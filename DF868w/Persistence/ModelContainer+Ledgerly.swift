//
//  ModelContainer+Ledgerly.swift
//  DF868w
//
//  Ledgerly - SwiftData container configuration
//

import SwiftData
import SwiftUI

extension ModelContainer {
    static func ledgerlyContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Budget.self,
            Goal.self,
            Template.self,
            Preferences.self,
            PaymentMethod.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    static var preview: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Schema([
            Transaction.self,
            Category.self,
            Budget.self,
            Goal.self,
            Template.self,
            Preferences.self,
            PaymentMethod.self
        ]), configurations: [config])
        SeedData.seedPreview(into: container)
        return container
    }
}
