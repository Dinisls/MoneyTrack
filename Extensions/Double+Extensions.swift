import Foundation

extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "€0,00"
    }
    
    func toPercentage() -> String {
        return String(format: "%.1f%%", self)
    }
    
    // ✅ NOVA FUNÇÃO: Para percentagens sem o símbolo %
    func toPercentageString() -> String {
        return String(format: "%.1f", self)
    }
    
    func toQuantityString() -> String {
        if self < 1 {
            return String(format: "%.4f", self)
        } else if self < 100 {
            return String(format: "%.2f", self)
        } else {
            return String(format: "%.0f", self)
        }
    }
    
    func toCryptoQuantity() -> String {
        if self >= 1 {
            return String(format: "%.2f", self)
        } else if self >= 0.01 {
            return String(format: "%.4f", self)
        } else {
            return String(format: "%.8f", self)
        }
    }
}
