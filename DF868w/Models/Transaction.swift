//
//  Transaction.swift
//  DF868w
//
//  Ledgerly - Transaction model
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var typeRaw: String
    var amountDecimal: Decimal
    var currencyCode: String
    var categoryId: UUID
    var date: Date
    var note: String
    var paymentMethodId: UUID?
    var tags: [String]
    var templateId: UUID?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        type: TransactionType,
        amount: Decimal,
        currencyCode: String,
        categoryId: UUID,
        date: Date = Date(),
        note: String = "",
        paymentMethodId: UUID? = nil,
        tags: [String] = [],
        templateId: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.typeRaw = type.rawValue
        self.amountDecimal = amount
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.date = date
        self.note = note
        self.paymentMethodId = paymentMethodId
        self.tags = tags
        self.templateId = templateId
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}
