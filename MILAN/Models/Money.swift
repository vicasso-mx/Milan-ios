import Foundation

enum Money {
    static func rounded(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .bankers)
        return result
    }

    static func formatted(_ value: Decimal) -> String {
        value.formatted(
            .currency(code: "MXN")
                .locale(Locale(identifier: "es_MX"))
                .precision(.fractionLength(2))
        )
    }
}
