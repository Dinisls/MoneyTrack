import Foundation

struct Asset: Identifiable, Codable, Hashable {
    let id = UUID()
    let symbol: String
    let name: String
    let type: AssetType
    var quantity: Double
    var averagePrice: Double
    var currentPrice: Double
    var lastUpdated: Date
    
    // 🆕 Taxa de juros anual (apenas para tipo .interest)
    var annualInterestRate: Double?
    // 🆕 Data do último pagamento de juros
    var lastInterestPayment: Date?
    
    enum AssetType: String, CaseIterable, Codable {
        case bank = "Banco"
        case savings = "Mealheiro"
        case crypto = "Criptomoedas"
        case stock = "Ações"
        case interest = "Dinheiro emllll Juros"
    }
    
    var totalValue: Double {
        quantity * currentPrice
    }
    
    var totalCost: Double {
        quantity * averagePrice
    }
    
    var profitLoss: Double {
        totalValue - totalCost
    }
    
    var profitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return ((totalValue - totalCost) / totalCost) * 100
    }
    
    // 🆕 Calcular juros mensais
    var monthlyInterestRate: Double {
        guard let rate = annualInterestRate else { return 0 }
        return rate / 12 / 100  // Converter de % anual para decimal mensal
    }
    
    // 🆕 Calcular valor dos juros mensais
    func calculateMonthlyInterest() -> Double {
        guard type == .interest, let _ = annualInterestRate else { return 0 }
        return totalValue * monthlyInterestRate
    }
    
    // 🆕 Verificar se deve receber juros este mês
    func shouldReceiveInterest() -> Bool {
        guard type == .interest, let _ = annualInterestRate else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Se nunca recebeu juros, pode receber agora
        guard let lastPayment = lastInterestPayment else { return true }
        
        // Verificar se já passou um mês desde o último pagamento
        let lastPaymentMonth = calendar.component(.month, from: lastPayment)
        let currentMonth = calendar.component(.month, from: now)
        let lastPaymentYear = calendar.component(.year, from: lastPayment)
        let currentYear = calendar.component(.year, from: now)
        
        return (currentYear > lastPaymentYear) || (currentYear == lastPaymentYear && currentMonth > lastPaymentMonth)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
}
