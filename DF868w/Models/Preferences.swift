//
//  Preferences.swift
//  DF868w
//
//  Ledgerly - User preferences model
//

import Foundation
import SwiftData

@Model
final class Preferences {
    @Attribute(.unique) var id: UUID
    var currencyCode: String
    var remindersEnabled: Bool
    var reminderTime: Date
    var hapticsEnabled: Bool
    var themeChoiceRaw: String
    var budgetsEnabled: Bool
    var onboardingCompleted: Bool

    var themeChoice: ThemeChoice {
        get { ThemeChoice(rawValue: themeChoiceRaw) ?? .system }
        set { themeChoiceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        currencyCode: String = "USD",
        remindersEnabled: Bool = false,
        reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        hapticsEnabled: Bool = true,
        themeChoice: ThemeChoice = .system,
        budgetsEnabled: Bool = true,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.remindersEnabled = remindersEnabled
        self.reminderTime = reminderTime
        self.hapticsEnabled = hapticsEnabled
        self.themeChoiceRaw = themeChoice.rawValue
        self.budgetsEnabled = budgetsEnabled
        self.onboardingCompleted = onboardingCompleted
    }
}

enum ThemeChoice: String, Codable, CaseIterable {
    case system
    case light
    case dark
}
