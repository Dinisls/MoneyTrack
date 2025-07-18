import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var assetType: Asset.AssetType = .bank
    @State private var quantity = ""
    @State private var purchasePrice = ""
    @State private var currentPrice = ""
    @State private var recordAsExpense = true
    @State private var annualInterestRate = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações do Ativo")) {
                    TextField(symbolPlaceholder, text: $symbol)
                        .textInputAutocapitalization(.characters)
                    
                    TextField(namePlaceholder, text: $name)
                    
                    Picker("Tipo", selection: $assetType) {
                        ForEach(Asset.AssetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: assetType) { oldValue, newValue in
                        symbol = ""
                        name = ""
                        quantity = ""
                        purchasePrice = ""
                        currentPrice = ""
                        annualInterestRate = ""
                    }
                }
                
                Section(header: Text("Valores")) {
                    TextField(quantityLabel, text: $quantity)
                        .keyboardType(.decimalPad)
                    
                    TextField("Valor Inicial (€)", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    
                    TextField("Valor Atual (€)", text: $currentPrice)
                        .keyboardType(.decimalPad)
                }
                
                // 🆕 Seção de configuração de juros (apenas para tipo .interest)
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
                
                if let qty = Double(quantity), let price = Double(purchasePrice) {
                    Section(header: Text("Resumo")) {
                        HStack {
                            Text("Valor Total do Investimento:")
                            Spacer()
                            Text((qty * price).toCurrency())
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
                
                Section(header: Text("Exemplos")) {
                    Text(exampleText)
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
        }
    }
    
    private var symbolPlaceholder: String {
        switch assetType {
        case .bank: return "Ex: CONTA, CARTAO"
        case .savings: return "Ex: POUPANCA, COFRE"
        case .crypto: return "Ex: BTC, ETH, SOL"
        case .stock: return "Ex: AAPL, TSLA, MSFT"
        case .interest: return "Ex: CA, OT, DP"
        }
    }
    
    private var namePlaceholder: String {
        switch assetType {
        case .bank: return "Ex: Conta CGD, Cartão Millennium"
        case .savings: return "Ex: Conta Poupança, Mealheiro Casa"
        case .crypto: return "Ex: Bitcoin, Ethereum"
        case .stock: return "Ex: Apple Inc., Tesla"
        case .interest: return "Ex: Certificados Aforro, Obrigações Tesouro"
        }
    }
    
    private var quantityLabel: String {
        switch assetType {
        case .bank, .savings, .interest: return "Quantidade (1 para conta única)"
        case .crypto: return "Quantidade (ex: 0.5 BTC)"
        case .stock: return "Número de ações"
        }
    }
    
    private var exampleText: String {
        switch assetType {
        case .bank:
            return "Adicione suas contas bancárias, cartões de débito, dinheiro em carteira, etc."
        case .savings:
            return "Inclua contas poupança, mealheiros, dinheiro guardado em casa, etc."
        case .crypto:
            return "Bitcoin, Ethereum, Solana e outras criptomoedas que possui."
        case .stock:
            return "Ações individuais de empresas cotadas em bolsa."
        case .interest:
            return "Certificados de Aforro (2,5% ao ano), Obrigações do Tesouro (3% ao ano), depósitos a prazo, etc. Os juros serão adicionados automaticamente cada mês."
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
    
    private var isValidForm: Bool {
        let basicValidation = !symbol.isEmpty && !name.isEmpty &&
                             Double(quantity) != nil && Double(purchasePrice) != nil && Double(currentPrice) != nil
        
        if assetType == .interest {
            return basicValidation && Double(annualInterestRate) != nil
        }
        
        return basicValidation
    }
    
    private func saveAsset() {
        guard let qty = Double(quantity),
              let purchasePrice = Double(purchasePrice),
              let currentPrice = Double(currentPrice) else { return }
        
        let interestRate: Double? = assetType == .interest ? Double(annualInterestRate) : nil
        
        let asset = Asset(
            symbol: symbol.uppercased(),
            name: name,
            type: assetType,
            quantity: qty,
            averagePrice: purchasePrice,
            currentPrice: currentPrice,
            lastUpdated: Date(),
            annualInterestRate: interestRate,
            lastInterestPayment: nil
        )
        
        portfolioManager.addAsset(asset, recordExpense: recordAsExpense)
        dismiss()
    }
}
