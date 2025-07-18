//
//  TransactionsView.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingAddTransaction = false
    @State private var selectedFilter: Transaction.TransactionType?
    
    var body: some View {
        NavigationView {
            VStack {
                if !financeManager.financeData.transactions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterButtonView(title: "Todas", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            
                            ForEach(Transaction.TransactionType.allCases, id: \.self) { type in
                                FilterButtonView(title: type.rawValue, isSelected: selectedFilter == type) {
                                    selectedFilter = type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                List {
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                    .onDelete(perform: deleteTransactions)
                }
                .listStyle(PlainListStyle())
                
                if filteredTransactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Nenhuma transação encontrada")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Adicione suas primeiras transações para começar a acompanhar suas finanças")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Transações")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let transactions = financeManager.financeData.transactions.sorted { $0.date > $1.date }
        
        if let filter = selectedFilter {
            return transactions.filter { $0.type == filter }
        }
        return transactions
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        for index in offsets {
            let transaction = filteredTransactions[index]
            financeManager.removeTransaction(transaction)
        }
    }
}