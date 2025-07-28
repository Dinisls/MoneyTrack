import Foundation

struct FinanceData: Codable {
    var transactions: [Transaction] = []
    var monthlyBudget: Double = 0
    var categories: [String] = [
        "Alimentação",
        "Transporte",
        "Moradia",
        "Saúde",
        "Entretenimento",
        "Depósito Bancário",
        "Poupanças",
        "Poupanças com Juros",
        "Investimentos Cripto",
        "Investimentos Ações",
        "Investimentos Juros",
        "Juros Recebidos",
        "Salário",
        "Freelance",
        "Outros"
    ]
    
    // ✅ ATUALIZADA: Receita mensal incluindo todas as fontes de receita
    var monthlyIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Incluir todas as transações que representam entrada de dinheiro
        let incomeTypes: [Transaction.TransactionType] = [
            .income,           // Salário, freelance, etc.
            .interestEarned    // Juros recebidos
        ]
        
        return transactions
            .filter { incomeTypes.contains($0.type) && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // ✅ MANTIDA: Despesas mensais (apenas gastos reais)
    var monthlyExpenses: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return transactions
            .filter { $0.type == .expense && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // ✅ NOVA: Balanço disponível (receitas - despesas reais)
    var availableBalance: Double {
        monthlyIncome - monthlyExpenses
    }
    
    // ✅ NOVA: Total de investimentos este mês
    var monthlyInvestments: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let investmentTypes: [Transaction.TransactionType] = [
            .cryptoBuy,
            .stockBuy,
            .interestInvestment
        ]
        
        return transactions
            .filter { investmentTypes.contains($0.type) && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // ✅ NOVA: Total de depósitos bancários/poupanças este mês
    var monthlyDeposits: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Contar depósitos como receitas (são dinheiro que entra nas contas)
        let depositCategories = ["Depósito Bancário", "Poupanças", "Poupanças com Juros"]
        
        return transactions
            .filter { $0.type == .income && depositCategories.contains($0.category) && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // ✅ NOVA: Total geral de receitas (incluindo depósitos)
    var totalMonthlyIncome: Double {
        monthlyIncome
    }
    
    // ✅ NOVA: Total geral de saídas (despesas + investimentos)
    var totalMonthlyOutflow: Double {
        monthlyExpenses + monthlyInvestments
    }
    
    // ✅ NOVA: Balanço final (receitas - despesas - investimentos)
    var finalBalance: Double {
        totalMonthlyIncome - totalMonthlyOutflow
    }
}
