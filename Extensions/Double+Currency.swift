import Foundation

extension Double {
    // MARK: - Formatação Original (mantida para compatibilidade)
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "€0,00"
    }
    
    // MARK: - Novas Funções Multi-moeda
    
    /// Formatar valor na moeda selecionada pelo utilizador
    func toCurrency(using currencyManager: CurrencyManager) -> String {
        return currencyManager.getDisplayPrice(self)
    }
    
    /// Formatar valor numa moeda específica
    func toCurrency(in currency: Currency, using currencyManager: CurrencyManager) -> String {
        switch currency {
        case .EUR:
            return currencyManager.formatPrice(self, in: .EUR)
        case .USD:
            let usdAmount = currencyManager.convert(self, from: .EUR, to: .USD)
            return currencyManager.formatPrice(usdAmount, in: .USD)
        }
    }
    
    /// Obter valor formatado em ambas as moedas
    func toBothCurrencies(using currencyManager: CurrencyManager) -> (eur: String, usd: String) {
        return currencyManager.getBothCurrencies(self)
    }
    
    // MARK: - Funções Existentes (mantidas)
    
    func toPercentage() -> String {
        return String(format: "%.1f%%", self)
    }
    
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
