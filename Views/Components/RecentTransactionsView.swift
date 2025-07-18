//
//  RecentTransactionsView.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct RecentTransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    
    var recentTransactions: [Transaction] {
        Array(financeManager.financeData.transactions
            .sorted { $0.date > $1.date }
            .prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transações Recentes")
                    .font(.headline)
                Spacer()
                NavigationLink("Ver Todas", destination: TransactionsView())
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if recentTransactions.isEmpty {
                Text("Nenhuma transação encontrada")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}