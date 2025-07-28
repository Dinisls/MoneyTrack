import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    // Variáveis de estado simplificadas
    @State private var symbol = ""
    @State private var name = ""
    @State private var assetType: Asset.AssetType = .bank
    @State private var currentPrice = "" // Valor a adicionar
    @State private var recordAsExpense = true
    @State private var annualInterestRate = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações do Ativo")) {
                    TextField(symbolPlaceholder, text: $symbol)
                        .textInputAutocapitalization(.characters)
                    
                    TextField(namePlaceholder, text: $name)
                    
                    Picker("Tipo", selection: $assetType) {
                        // ✅ APENAS tipos que são adicionados manualmente
                        Text(Asset.AssetType.bank.rawValue).tag(Asset.AssetType.bank)
                        Text(Asset.AssetType.savings.rawValue).tag(Asset.AssetType.savings)
                        Text(Asset.AssetType.interest.rawValue).tag(Asset.AssetType.interest)
                    }
                    .onChange(of: assetType) { _, _ in
                        // Limpar campos quando muda tipo
                        symbol = ""
                        name = ""
                        currentPrice = ""
                        annualInterestRate = ""
                    }
                }
                
                Section(header: Text("Valores")) {
                    // ✅ SIMPLIFICADO: Apenas valor a adicionar (quantidade sempre será 1)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Valor a Adicionar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Valor (€)", text: $currentPrice)
                            .keyboardType(.decimalPad)
                        
                        Text(getValueDescription())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ✅ Seção de configuração de juros (apenas para tipo .interest)
                if assetType == .interest {
                    Section(header: Text("Configuração de Juros")) {
                        HStack {
                            TextField("Taxa de juros anual", text: $annualInterestRate)
                                .keyboardType(.decimalPad)
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        
                        if let rate = Double(annualInterestRate), let amount = Double(currentPrice) {
                            let monthlyInterest = (amount * rate / 12 / 100)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Juros mensais estimados: \(monthlyInterest.toCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Text("Juros anuais estimados: \((amount * rate / 100).toCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Os juros serão calculados e adicionados automaticamente ao final de cada mês.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Contabilidade")) {
                    Toggle("Registrar como despesa automaticamente", isOn: $recordAsExpense)
                    
                    if recordAsExpense {
                        Text("Esta compra será automaticamente registrada como despesa nas suas transações.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ✅ Resumo melhorado
                if let amount = Double(currentPrice) {
                    Section(header: Text("Resumo")) {
                        HStack {
                            Text("Valor Total:")
                            Spacer()
                            Text(amount.toCurrency())
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        if recordAsExpense {
                            HStack {
                                Text("Será registrado como:")
                                Spacer()
                                Text(getCategoryForAssetType(assetType))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Section(header: Text("Dicas")) {
                    Text(getTipsForAssetType())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Adicionar \(assetType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        saveAsset()
                    }
                    .disabled(!isValidForm)
                }
            }
            .alert("MoneyTrack", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func getValueDescription() -> String {
        switch assetType {
        case .bank:
            return "Valor a depositar na conta bancária"
        case .savings:
            return "Valor a colocar no mealheiro/poupança"
        case .interest:
            return "Valor a investir em produto com juros"
        case .crypto, .stock:
            return "Valor do investimento"
        }
    }
    
    private func getCategoryForAssetType(_ type: Asset.AssetType) -> String {
        switch type {
        case .bank: return "Transferências Bancárias"
        case .savings: return "Poupanças"
        case .crypto: return "Investimentos Cripto"
        case .stock: return "Investimentos Ações"
        case .interest: return "Investimentos Juros"
        }
    }
    
    private var symbolPlaceholder: String {
        switch assetType {
        case .bank: return "Ex: CONTA, CARTAO"
        case .savings: return "Ex: POUPANCA, COFRE"
        case .interest: return "Ex: CA, OT, DP"
        case .crypto, .stock: return "N/A"
        }
    }
    
    private var namePlaceholder: String {
        switch assetType {
        case .bank: return "Ex: Conta CGD, Cartão Millennium"
        case .savings: return "Ex: Conta Poupança, Mealheiro Casa"
        case .interest: return "Ex: Certificados Aforro, Obrigações Tesouro"
        case .crypto, .stock: return "N/A"
        }
    }
    
    private func getTipsForAssetType() -> String {
        switch assetType {
        case .bank:
            return "💡 Para contas bancárias, use o saldo atual como valor. O valor de compra pode ser o depósito inicial."
        case .savings:
            return "💡 Para poupanças, use o valor atual como saldo. O valor de compra é quanto depositou inicialmente."
        case .interest:
            return "💡 Para obrigações, o valor nominal é usado. Ajuste o valor de compra se pagou prémio ou desconto."
        case .crypto:
            return "💡 Use a busca de ativos para adicionar criptomoedas com preços reais."
        case .stock:
            return "💡 Use a busca de ativos para adicionar ações com preços do mercado."
        }
    }
    
    private var isValidForm: Bool {
        let basicValidation = !symbol.isEmpty && !name.isEmpty && Double(currentPrice) != nil
        
        if assetType == .interest {
            return basicValidation && Double(annualInterestRate) != nil
        }
        
        return basicValidation
    }
    
    private func saveAsset() {
        guard let amount = Double(currentPrice) else {
            alertMessage = "Por favor, preencha todos os campos com valores válidos."
            showingAlert = true
            return
        }
        
        let interestRate: Double? = assetType == .interest ? Double(annualInterestRate) : nil
        
        let asset = Asset(
            symbol: symbol.uppercased(),
            name: name,
            type: assetType,
            quantity: 1.0, // ✅ SEMPRE 1 para contas financeiras
            averagePrice: amount,
            currentPrice: amount,
            lastUpdated: Date(),
            annualInterestRate: interestRate,
            lastInterestPayment: nil
        )
        
        portfolioManager.addAsset(asset, recordExpense: recordAsExpense)
        dismiss()
    }
}

#Preview {
    AddAssetView()
        .environmentObject(PortfolioManager())
}
