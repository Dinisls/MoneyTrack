import Foundation

struct Transaction: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let type: TransactionType
    let category: String
    let amount: Double
    let description: String
    let assetSymbol: String?
    let quantity: Double?
    let price: Double?
    
    enum TransactionType: String, CaseIterable, Codable {
        case income = "Receita"
        case expense = "Despesa"
        case bankDeposit = "Depósito Banco"
        case bankWithdrawal = "Levantamento Banco"
        case savingsDeposit = "Depósito Mealheiro"
        case savingsWithdrawal = "Levantamento Mealheiro"
        case cryptoBuy = "Compra Cripto"
        case cryptoSell = "Venda Cripto"
        case stockBuy = "Compra Ação"
        case stockSell = "Venda Ação"
        case interestEarned = "Juros Recebidos"
        case interestInvestment = "Investimento Juros"
    }
}
