//
//  Goal.swift
//  DF868w
//
//  Ledgerly - Savings goal model
//

import Foundation
import SwiftData

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetAmount: Decimal
    var targetDate: Date
    var currentAmount: Decimal
    var sortOrder: Int

    var progress: Decimal {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1)
    }

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        targetDate: Date,
        currentAmount: Decimal = 0,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.currentAmount = currentAmount
        self.sortOrder = sortOrder
    }
}
