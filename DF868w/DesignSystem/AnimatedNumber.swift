//
//  AnimatedNumber.swift
//  DF868w
//
//  Ledgerly - Animated number transitions
//

import SwiftUI

struct AnimatedNumber: View {
    let value: Decimal
    let formatter: NumberFormatter
    @State private var displayedValue: Decimal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(value: Decimal, formatter: NumberFormatter) {
        self.value = value
        self.formatter = formatter
        _displayedValue = State(initialValue: value)
    }

    var body: some View {
        Text(formatter.string(from: value as NSDecimalNumber) ?? "0")
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: value)
    }
}

struct AnimatedCurrencyAmount: View {
    let amount: Decimal
    let currencyCode: String
    let isPositive: Bool
    @State private var appeared = false

    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }

    var body: some View {
        Text(formatter.string(from: abs(amount) as NSDecimalNumber) ?? "0")
            .contentTransition(.numericText())
            .foregroundStyle(isPositive ? Theme.success : Theme.danger)
            .animation(.easeInOut(duration: 0.3), value: amount)
    }
}
