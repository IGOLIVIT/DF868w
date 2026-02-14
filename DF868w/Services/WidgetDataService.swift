//
//  WidgetDataService.swift
//  DF868w
//
//  Ledgerly - Writes summary to App Group for widgets
//

import Foundation
import WidgetKit

let appGroupId = "group.ioi.df868w.ledgerly"

struct WidgetDataService {
    static func updateMonthSummary(income: Double, expense: Double, currencyCode: String) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        defaults.set(income, forKey: "widget_income")
        defaults.set(expense, forKey: "widget_expense")
        defaults.set(currencyCode, forKey: "widget_currency")
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
