//
//  Budget.swift
//  DF868w
//
//  Ledgerly - Budget model
//

import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var categoryId: UUID
    var monthKey: String
    var limitDecimal: Decimal

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        monthKey: String,
        limit: Decimal
    ) {
        self.id = id
        self.categoryId = categoryId
        self.monthKey = monthKey
        self.limitDecimal = limit
    }
}
