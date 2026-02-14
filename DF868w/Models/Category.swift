//
//  Category.swift
//  DF868w
//
//  Ledgerly - Category model
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorKey: String
    var isSystem: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorKey: String,
        isSystem: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorKey = colorKey
        self.isSystem = isSystem
        self.sortOrder = sortOrder
    }
}
