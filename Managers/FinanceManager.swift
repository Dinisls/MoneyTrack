import Foundation
import Combine

class FinanceManager: ObservableObject {
    @Published var financeData = FinanceData()
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let financeKey = "finance_data_v5"
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let data = userDefaults.data(forKey: financeKey),
           let decodedData = try? JSONDecoder().decode(FinanceData.self, from: data) {
            self.financeData = decodedData
        } else {
            // Dados de exemplo com novas categorias
            let sampleTransactions = [
                Transaction(date: Date().addingTimeInterval(-86400), type: .income, category: "Salário", amount: 3000, description: "Salário mensal", assetSymbol: nil, quantity: nil, price: nil),
                Transaction(date: Date().addingTimeInterval(-43200), type: .expense, category: "Alimentação", amount: 50, description: "Supermercado", assetSymbol: nil, quantity: nil, price: nil),
                Transaction(date: Date(), type: .expense, category: "Transporte", amount: 25, description: "Combustível", assetSymbol: nil, quantity: nil, price: nil)
            ]
            
            // Adicionar novas categorias para investimentos
            self.financeData.transactions = sampleTransactions
            self.financeData.monthlyBudget = 2000
            self.financeData.categories = [
                "Alimentação",
                "Transporte",
                "Moradia",
                "Saúde",
                "Entretenimento",
                "Transferências Bancárias",
                "Poupanças",
                "Investimentos Cripto",
                "Investimentos Ações",
                "Investimentos Juros",
                "Outros"
            ]
            self.saveData()
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(financeData) {
            userDefaults.set(encoded, forKey: financeKey)
        }
    }
    
    func addTransaction(_ transaction: Transaction) {
        financeData.transactions.append(transaction)
        saveData()
        
        // Enviar notificação que uma nova transação foi adicionada
        NotificationCenter.default.post(name: .newTransactionAdded, object: transaction)
    }
    
    func removeTransaction(_ transaction: Transaction) {
        financeData.transactions.removeAll { $0.id == transaction.id }
        saveData()
    }
    
    func setBudget(_ amount: Double) {
        financeData.monthlyBudget = amount
        saveData()
    }
    
    // 📊 Nova função para obter despesas de investimentos
    func getInvestmentExpenses() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let investmentTypes: [Transaction.TransactionType] = [
            .bankDeposit, .savingsDeposit, .cryptoBuy, .stockBuy, .interestInvestment
        ]
        
        return financeData.transactions
            .filter { investmentTypes.contains($0.type) && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 📊 Despesas totais incluindo investimentos
    var totalMonthlyExpenses: Double {
        financeData.monthlyExpenses + getInvestmentExpenses()
    }
}
