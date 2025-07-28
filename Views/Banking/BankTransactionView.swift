import SwiftUI

struct BankTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioManager: PortfolioManager
    @EnvironmentObject var financeManager: FinanceManager
    
    // ✅ Parâmetro para pré-selecionar tipo de transação
    let preselectedType: BankTransactionType?
    
    @State private var transactionType: BankTransactionType = .deposit
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedBankAccount: Asset?
    @State private var destinationAccount: Asset?
    @State private var date = Date()
    @State private var showingAccountPicker = false
    @State private var accountPickerType: AccountPickerType = .source
    
    enum BankTransactionType: String, CaseIterable {
        case deposit = "Entrada de Dinheiro"
        case withdrawal = "Saída de Dinheiro"
        case transferToSavings = "Transferir para Mealheiro"
        case transferToInterest = "Transferir para Dinheiro em Juros"
        case transferFromSavings = "Transferir do Mealheiro"
        case transferFromInterest = "Transferir do Dinheiro em Juros"
    }
    
    enum AccountPickerType {
        case source
        case destination
    }
    
    // ✅ Inicializador com tipo pré-selecionado
    init(preselectedType: BankTransactionType? = nil) {
        self.preselectedType = preselectedType
    }
    
    var bankAccounts: [Asset] {
        portfolioManager.portfolio.assets.filter { $0.type == .bank }
    }
    
    var savingsAccounts: [Asset] {
        portfolioManager.portfolio.assets.filter { $0.type == .savings }
    }
    
    var interestAccounts: [Asset] {
        portfolioManager.portfolio.assets.filter { $0.type == .interest }
    }
    
    var availableDestinations: [Asset] {
        switch transactionType {
        case .transferToSavings:
            return savingsAccounts
        case .transferToInterest:
            return interestAccounts
        case .transferFromSavings, .transferFromInterest:
            return bankAccounts
        default:
            return []
        }
    }
    
    var needsDestination: Bool {
        [.transferToSavings, .transferToInterest, .transferFromSavings, .transferFromInterest].contains(transactionType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Tipo de Transação
                Section(header: Text("Tipo de Operação")) {
                    Picker("Tipo", selection: $transactionType) {
                        ForEach(BankTransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: transactionType) { _, _ in
                        destinationAccount = nil
                        selectedBankAccount = nil
                    }
                    
                    // Explicação do tipo selecionado
                    Text(getTransactionTypeDescription())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
                
                // MARK: - Conta de Origem
                Section(header: Text(getSourceAccountTitle())) {
                    if let account = selectedBankAccount {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(.body)
                                Text("Saldo atual: \(account.totalValue.toCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Alterar") {
                                accountPickerType = .source
                                showingAccountPicker = true
                            }
                            .font(.caption)
                        }
                    } else {
                        Button("Selecionar Conta") {
                            accountPickerType = .source
                            showingAccountPicker = true
                        }
                    }
                    
                    // Validar saldo para saídas e transferências
                    if isWithdrawalType() && selectedBankAccount != nil {
                        let currentBalance = getSourceBalance()
                        if let amt = Double(amount), amt > currentBalance {
                            Label("Saldo insuficiente", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // MARK: - Conta de Destino (para transferências)
                if needsDestination {
                    Section(header: Text("Conta de Destino")) {
                        if let destination = destinationAccount {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(destination.name)
                                        .font(.body)
                                    Text("Saldo atual: \(destination.totalValue.toCurrency())")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Alterar") {
                                    accountPickerType = .destination
                                    showingAccountPicker = true
                                }
                                .font(.caption)
                            }
                        } else {
                            Button("Selecionar Destino") {
                                accountPickerType = .destination
                                showingAccountPicker = true
                            }
                        }
                        
                        if availableDestinations.isEmpty {
                            Text("Nenhuma conta de destino disponível. Crie primeiro uma conta do tipo necessário no Portfolio.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        }
                    }
                }
                
                // MARK: - Detalhes da Transação
                Section(header: Text("Detalhes")) {
                    TextField("Valor (€)", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Descrição", text: $description)
                    
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }
                
                // MARK: - Resumo da Operação
                if isValidForm {
                    Section(header: Text("Resumo da Operação")) {
                        TransactionSummaryView(
                            transactionType: transactionType,
                            amount: Double(amount) ?? 0,
                            sourceAccount: selectedBankAccount,
                            destinationAccount: destinationAccount,
                            description: description
                        )
                    }
                }
                
                // MARK: - Avisos e Dicas
                Section(header: Text("💡 Informação")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(getTransactionTips())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if transactionType == .deposit {
                            Text("💰 Esta entrada será contabilizada como receita no dashboard.")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if transactionType == .withdrawal {
                            Text("💸 Esta saída será contabilizada como despesa no dashboard.")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if needsDestination {
                            Text("🔄 Esta transferência moverá dinheiro entre contas sem afetar o total geral.")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Transação Bancária")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Executar") {
                        executeTransaction()
                    }
                    .disabled(!isValidForm)
                }
            }
            .sheet(isPresented: $showingAccountPicker) {
                AccountPickerView(
                    title: accountPickerType == .source ? "Selecionar Conta" : "Selecionar Destino",
                    accounts: accountPickerType == .source ? getSourceAccounts() : availableDestinations,
                    selectedAccount: accountPickerType == .source ? $selectedBankAccount : $destinationAccount
                )
            }
            .onAppear {
                // ✅ Pré-selecionar tipo se fornecido
                if let preselected = preselectedType {
                    transactionType = preselected
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getSourceAccounts() -> [Asset] {
        switch transactionType {
        case .deposit, .withdrawal, .transferToSavings, .transferToInterest:
            return bankAccounts
        case .transferFromSavings:
            return savingsAccounts
        case .transferFromInterest:
            return interestAccounts
        }
    }
    
    private func getSourceAccountTitle() -> String {
        switch transactionType {
        case .deposit, .withdrawal, .transferToSavings, .transferToInterest:
            return "Conta Bancária"
        case .transferFromSavings:
            return "Conta Poupança (Origem)"
        case .transferFromInterest:
            return "Conta de Juros (Origem)"
        }
    }
    
    private func getSourceBalance() -> Double {
        selectedBankAccount?.totalValue ?? 0
    }
    
    private func isWithdrawalType() -> Bool {
        [.withdrawal, .transferToSavings, .transferToInterest, .transferFromSavings, .transferFromInterest].contains(transactionType)
    }
    
    private func getTransactionTypeDescription() -> String {
        switch transactionType {
        case .deposit:
            return "Adicionar dinheiro à conta bancária (salário, transferência recebida, etc.)"
        case .withdrawal:
            return "Retirar dinheiro da conta bancária (levantamento, pagamento, etc.)"
        case .transferToSavings:
            return "Mover dinheiro da conta bancária para o mealheiro/poupança"
        case .transferToInterest:
            return "Mover dinheiro da conta bancária para investimento em juros"
        case .transferFromSavings:
            return "Mover dinheiro do mealheiro/poupança para a conta bancária"
        case .transferFromInterest:
            return "Mover dinheiro do investimento em juros para a conta bancária"
        }
    }
    
    private func getTransactionTips() -> String {
        switch transactionType {
        case .deposit:
            return "Use para registrar salários, transferências recebidas, ou qualquer dinheiro que entra na sua conta."
        case .withdrawal:
            return "Use para registrar levantamentos, pagamentos diretos da conta, ou gastos feitos com cartão de débito."
        case .transferToSavings:
            return "Use quando põe dinheiro de parte numa poupança ou mealheiro."
        case .transferToInterest:
            return "Use quando investe em produtos bancários que geram juros (certificados, depósitos a prazo, etc.)."
        case .transferFromSavings:
            return "Use quando precisa de usar dinheiro que tinha na poupança."
        case .transferFromInterest:
            return "Use quando resgata investimentos em juros para a conta corrente."
        }
    }
    
    private var isValidForm: Bool {
        guard !amount.isEmpty,
              let amt = Double(amount),
              amt > 0,
              !description.isEmpty,
              selectedBankAccount != nil else { return false }
        
        // Verificar se precisa de destino
        if needsDestination && destinationAccount == nil {
            return false
        }
        
        // Verificar saldo para saídas
        if isWithdrawalType() {
            let sourceBalance = getSourceBalance()
            return amt <= sourceBalance
        }
        
        return true
    }
    
    private func executeTransaction() {
        guard let amt = Double(amount),
              let sourceAccount = selectedBankAccount else { return }
        
        switch transactionType {
        case .deposit:
            executeDeposit(amount: amt, account: sourceAccount)
        case .withdrawal:
            executeWithdrawal(amount: amt, account: sourceAccount)
        case .transferToSavings:
            executeTransfer(amount: amt, from: sourceAccount, to: destinationAccount, type: .savings)
        case .transferToInterest:
            executeTransfer(amount: amt, from: sourceAccount, to: destinationAccount, type: .interest)
        case .transferFromSavings:
            executeTransfer(amount: amt, from: sourceAccount, to: destinationAccount, type: .bank)
        case .transferFromInterest:
            executeTransfer(amount: amt, from: sourceAccount, to: destinationAccount, type: .bank)
        }
        
        dismiss()
    }
    
    private func executeDeposit(amount: Double, account: Asset) {
        // Atualizar saldo da conta
        portfolioManager.updateAccountBalance(account, newBalance: account.totalValue + amount)
        
        // Registrar como receita
        let transaction = Transaction(
            date: date,
            type: .income,
            category: "Depósito Bancário",
            amount: amount,
            description: description,
            assetSymbol: account.symbol,
            quantity: nil,
            price: nil
        )
        financeManager.addTransaction(transaction)
    }
    
    private func executeWithdrawal(amount: Double, account: Asset) {
        // Atualizar saldo da conta
        portfolioManager.updateAccountBalance(account, newBalance: account.totalValue - amount)
        
        // Registrar como despesa
        let transaction = Transaction(
            date: date,
            type: .expense,
            category: "Levantamento Bancário",
            amount: amount,
            description: description,
            assetSymbol: account.symbol,
            quantity: nil,
            price: nil
        )
        financeManager.addTransaction(transaction)
    }
    
    private func executeTransfer(amount: Double, from sourceAccount: Asset, to destinationAccount: Asset?, type: Asset.AssetType) {
        guard let destAccount = destinationAccount else { return }
        
        // Atualizar saldo da conta origem
        portfolioManager.updateAccountBalance(sourceAccount, newBalance: sourceAccount.totalValue - amount)
        
        // Atualizar saldo da conta destino
        portfolioManager.updateAccountBalance(destAccount, newBalance: destAccount.totalValue + amount)
        
        // Registrar transferência (duas transações para rastreamento completo)
        let withdrawalTransaction = Transaction(
            date: date,
            type: .bankWithdrawal,
            category: "Transferência",
            amount: amount,
            description: "Transferência para \(destAccount.name): \(description)",
            assetSymbol: sourceAccount.symbol,
            quantity: nil,
            price: nil
        )
        
        let depositTransaction = Transaction(
            date: date,
            type: getDepositTransactionType(for: type),
            category: getTransferCategory(for: type),
            amount: amount,
            description: "Transferência de \(sourceAccount.name): \(description)",
            assetSymbol: destAccount.symbol,
            quantity: nil,
            price: nil
        )
        
        financeManager.addTransaction(withdrawalTransaction)
        financeManager.addTransaction(depositTransaction)
    }
    
    private func getDepositTransactionType(for assetType: Asset.AssetType) -> Transaction.TransactionType {
        switch assetType {
        case .bank: return .bankDeposit
        case .savings: return .savingsDeposit
        case .interest: return .interestInvestment
        default: return .bankDeposit
        }
    }
    
    private func getTransferCategory(for assetType: Asset.AssetType) -> String {
        switch assetType {
        case .bank: return "Transferência Bancária"
        case .savings: return "Transferência para Poupança"
        case .interest: return "Transferência para Juros"
        default: return "Transferência"
        }
    }
}

// MARK: - Transaction Summary View
struct TransactionSummaryView: View {
    let transactionType: BankTransactionView.BankTransactionType
    let amount: Double
    let sourceAccount: Asset?
    let destinationAccount: Asset?
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Operação:")
                Spacer()
                Text(transactionType.rawValue)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Valor:")
                Spacer()
                Text(amount.toCurrency())
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if let source = sourceAccount {
                HStack {
                    Text(getSourceLabel())
                    Spacer()
                    Text(source.name)
                        .foregroundColor(.secondary)
                }
            }
            
            if let destination = destinationAccount {
                HStack {
                    Text("Destino:")
                    Spacer()
                    Text(destination.name)
                        .foregroundColor(.secondary)
                }
            }
            
            if !description.isEmpty {
                HStack {
                    Text("Descrição:")
                    Spacer()
                    Text(description)
                        .foregroundColor(.secondary)
                }
            }
            
            // Mostrar impacto no saldo
            if let source = sourceAccount {
                Divider()
                
                VStack(spacing: 4) {
                    HStack {
                        Text("Saldo atual de \(source.name):")
                        Spacer()
                        Text(source.totalValue.toCurrency())
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Saldo após operação:")
                        Spacer()
                        let newBalance = calculateNewBalance()
                        Text(newBalance.toCurrency())
                            .fontWeight(.medium)
                            .foregroundColor(newBalance >= 0 ? .primary : .red)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getSourceLabel() -> String {
        switch transactionType {
        case .deposit, .withdrawal, .transferToSavings, .transferToInterest:
            return "Conta:"
        case .transferFromSavings:
            return "Origem:"
        case .transferFromInterest:
            return "Origem:"
        }
    }
    
    private func calculateNewBalance() -> Double {
        guard let source = sourceAccount else { return 0 }
        
        switch transactionType {
        case .deposit:
            return source.totalValue + amount
        case .withdrawal, .transferToSavings, .transferToInterest, .transferFromSavings, .transferFromInterest:
            return source.totalValue - amount
        }
    }
}

// MARK: - Account Picker View
struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let accounts: [Asset]
    @Binding var selectedAccount: Asset?
    
    var body: some View {
        NavigationView {
            List {
                if accounts.isEmpty {
                    Text("Nenhuma conta disponível")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(accounts) { account in
                        Button(action: {
                            selectedAccount = account
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("Saldo: \(account.totalValue.toCurrency())")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(account.symbol)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if selectedAccount?.id == account.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    BankTransactionView()
        .environmentObject(PortfolioManager())
        .environmentObject(FinanceManager())
}
