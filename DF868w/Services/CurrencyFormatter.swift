//
//  CurrencyFormatter.swift
//  DF868w
//
//  Ledgerly - Currency formatting service
//

import Foundation

struct CurrencyFormatter {

    static func format(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    static func formatCompact(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }

    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }

    static var supportedCurrencies: [(code: String, name: String)] {
        [
            ("USD", "US Dollar"),
            ("EUR", "Euro"),
            ("GBP", "British Pound"),
            ("AED", "UAE Dirham"),
            ("RUB", "Russian Ruble")
        ]
    }

    static func formatter(for currencyCode: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }
}
