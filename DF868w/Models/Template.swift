//
//  Template.swift
//  DF868w
//
//  Ledgerly - One-tap transaction template
//

import Foundation
import SwiftData

@Model
final class Template {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var amountDecimal: Decimal
    var categoryId: UUID
    var paymentMethodId: UUID?
    var sortOrder: Int

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: TransactionType,
        amount: Decimal,
        categoryId: UUID,
        paymentMethodId: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.amountDecimal = amount
        self.categoryId = categoryId
        self.paymentMethodId = paymentMethodId
        self.sortOrder = sortOrder
    }
}
