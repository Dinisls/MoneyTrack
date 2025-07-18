//
//  FinanceData.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import Foundation

struct FinanceData: Codable {
    var transactions: [Transaction] = []
    var monthlyBudget: Double = 0
    var categories: [String] = ["Alimentação", "Transporte", "Moradia", "Saúde", "Entretenimento", "Outros"]
    
    var monthlyIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return transactions
            .filter { $0.type == .income && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyExpenses: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return transactions
            .filter { $0.type == .expense && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var availableBalance: Double {
        monthlyIncome - monthlyExpenses
    }
}
