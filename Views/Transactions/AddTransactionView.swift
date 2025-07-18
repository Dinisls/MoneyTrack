import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    
    @State private var transactionType: Transaction.TransactionType = .expense
    @State private var amount = ""
    @State private var description = ""
    @State private var category = "Outros"
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tipo de Transação")) {
                    Picker("Tipo", selection: $transactionType) {
                        Group {
                            Text("Receita").tag(Transaction.TransactionType.income)
                            Text("Despesa").tag(Transaction.TransactionType.expense)
                        }
                        
                        Group {
                            Text("Depósito Banco").tag(Transaction.TransactionType.bankDeposit)
                            Text("Levantamento Banco").tag(Transaction.TransactionType.bankWithdrawal)
                            Text("Depósito Mealheiro").tag(Transaction.TransactionType.savingsDeposit)
                            Text("Levantamento Mealheiro").tag(Transaction.TransactionType.savingsWithdrawal)
                        }
                        
                        Group {
                            Text("Compra Cripto").tag(Transaction.TransactionType.cryptoBuy)
                            Text("Venda Cripto").tag(Transaction.TransactionType.cryptoSell)
                            Text("Compra Ação").tag(Transaction.TransactionType.stockBuy)
                            Text("Venda Ação").tag(Transaction.TransactionType.stockSell)
                        }
                        
                        Group {
                            Text("Juros Recebidos").tag(Transaction.TransactionType.interestEarned)
                            Text("Investimento Juros").tag(Transaction.TransactionType.interestInvestment)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Informações")) {
                    TextField("Descrição", text: $description)
                    
                    TextField("Valor (€)", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    if transactionType == .income || transactionType == .expense {
                        Picker("Categoria", selection: $category) {
                            ForEach(financeManager.financeData.categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }
                
                // Seção informativa baseada no tipo
                Section(header: Text("Informação")) {
                    Text(transactionTypeInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nova Transação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        saveTransaction()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
    }
    
    private var transactionTypeInfo: String {
        switch transactionType {
        case .income: return "Salário, freelance, vendas, etc."
        case .expense: return "Compras, contas, alimentação, etc."
        case .bankDeposit: return "Dinheiro depositado na conta bancária"
        case .bankWithdrawal: return "Dinheiro levantado da conta bancária"
        case .savingsDeposit: return "Dinheiro colocado no mealheiro/poupança"
        case .savingsWithdrawal: return "Dinheiro retirado do mealheiro/poupança"
        case .cryptoBuy: return "Compra de criptomoedas"
        case .cryptoSell: return "Venda de criptomoedas"
        case .stockBuy: return "Compra de ações"
        case .stockSell: return "Venda de ações"
        case .interestEarned: return "Juros recebidos de investimentos"
        case .interestInvestment: return "Dinheiro investido em produtos com juros"
        }
    }
    
    private var isValidForm: Bool {
        !description.isEmpty && Double(amount) != nil
    }
    
    private func saveTransaction() {
        guard let amt = Double(amount) else { return }
        
        let transaction = Transaction(
            date: date,
            type: transactionType,
            category: category,
            amount: amt,
            description: description,
            assetSymbol: nil,
            quantity: nil,
            price: nil
        )
        
        financeManager.addTransaction(transaction)
        dismiss()
    }
}
