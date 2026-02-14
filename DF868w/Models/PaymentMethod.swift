//
//  PaymentMethod.swift
//  DF868w
//
//  Ledgerly - Payment method model
//

import Foundation
import SwiftData

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}
