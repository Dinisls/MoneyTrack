import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioManager: PortfolioManager
    @StateObject private var priceManager = PriceManager() // 🆕 Para buscar preços
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var assetType: Asset.AssetType = .bank
    @State private var quantity = ""
    @State private var purchasePrice = ""
    @State private var currentPrice = ""
    @State private var recordAsExpense = true
    @State private var annualInterestRate = ""
    
    // 🆕 Estados para controle de preços
    @State private var isLoadingCurrentPrice = false
    @State private var hasLoadedInitialPrice = false
    @State private var showingPriceHelp = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações do Ativo")) {
                    TextField(symbolPlaceholder, text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: symbol) { _, newValue in
                            // 🆕 Buscar preço automaticamente quando símbolo muda
                            if shouldFetchPrice(for: assetType) && !newValue.isEmpty {
                                fetchCurrentPrice()
                            }
                        }
                    
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
                        hasLoadedInitialPrice = false
                    }
                }
                
                Section(header: Text("Valores")) {
                    TextField(quantityLabel, text: $quantity)
                        .keyboardType(.decimalPad)
                    
                    // 🆕 NOVA SEÇÃO: Preços com explicação
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Valor Atual do Mercado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if shouldFetchPrice(for: assetType) {
                                Button(action: { showingPriceHelp = true }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                if isLoadingCurrentPrice {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Button("🔄") {
                                        fetchCurrentPrice()
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Valor atual (€)", text: $currentPrice)
                                .keyboardType(.decimalPad)
                            
                            if shouldFetchPrice(for: assetType) && !symbol.isEmpty {
                                Button("Buscar Preço") {
                                    fetchCurrentPrice()
                                }
                                .font(.caption)
                                .disabled(isLoadingCurrentPrice)
                            }
                        }
                    }
                    
                    // 🆕 NOVA SEÇÃO: Preço de compra com explicação
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Valor de Compra")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: copyCurrentToPurchase) {
                                Text("Copiar do atual")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .disabled(currentPrice.isEmpty)
                        }
                        
                        TextField("Valor pago na compra (€)", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                        
                        if !currentPrice.isEmpty && !purchasePrice.isEmpty,
                           let current = Double(currentPrice),
                           let purchase = Double(purchasePrice),
                           current != purchase {
                            
                            let difference = current - purchase
                            let percentageChange = (difference / purchase) * 100
                            
                            HStack {
                                Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(difference >= 0 ? .green : .red)
                                    .font(.caption)
                                
                                Text("Diferença: \(abs(difference).toCurrency()) (\(abs(percentageChange).toPercentage()))")
                                    .font(.caption)
                                    .foregroundColor(difference >= 0 ? .green : .red)
                            }
                        }
                    }
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
                
                // 🆕 Resumo melhorado
                if let qty = Double(quantity) {
                    Section(header: Text("Resumo")) {
                        if let purchasePrice = Double(purchasePrice) {
                            HStack {
                                Text("Valor Total do Investimento:")
                                Spacer()
                                Text((qty * purchasePrice).toCurrency())
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let currentPrice = Double(currentPrice) {
                            HStack {
                                Text("Valor Atual do Portfolio:")
                                Spacer()
                                Text((qty * currentPrice).toCurrency())
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if let current = Double(currentPrice),
                           let purchase = Double(purchasePrice) {
                            let totalDifference = qty * (current - purchase)
                            
                            HStack {
                                Text(totalDifference >= 0 ? "Lucro Atual:" : "Prejuízo Atual:")
                                Spacer()
                                Text(abs(totalDifference).toCurrency())
                                    .fontWeight(.bold)
                                    .foregroundColor(totalDifference >= 0 ? .green : .red)
                            }
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
            .alert("Sobre os Preços", isPresented: $showingPriceHelp) {
                Button("OK") { }
            } message: {
                Text("• Valor Atual: Preço do ativo no mercado neste momento\n• Valor de Compra: Preço que pagou quando comprou o ativo\n\nA diferença entre estes valores mostra o seu lucro ou prejuízo atual.")
            }
        }
    }
    
    // 🆕 Função para determinar se deve buscar preço
    private func shouldFetchPrice(for type: Asset.AssetType) -> Bool {
        return type == .crypto || type == .stock || type == .interest
    }
    
    // 🆕 Função para buscar preço atual
    private func fetchCurrentPrice() {
        guard !symbol.isEmpty, shouldFetchPrice(for: assetType) else { return }
        
        isLoadingCurrentPrice = true
        
        Task {
            if let price = await priceManager.getCurrentPrice(for: symbol, type: assetType) {
                await MainActor.run {
                    currentPrice = String(price)
                    
                    // 🆕 Se é a primeira vez e não há preço de compra, copiar automaticamente
                    if !hasLoadedInitialPrice && purchasePrice.isEmpty {
                        purchasePrice = String(price)
                    }
                    
                    hasLoadedInitialPrice = true
                    isLoadingCurrentPrice = false
                }
            } else {
                await MainActor.run {
                    isLoadingCurrentPrice = false
                }
            }
        }
    }
    
    // 🆕 Função para copiar preço atual para preço de compra
    private func copyCurrentToPurchase() {
        purchasePrice = currentPrice
    }
    
    // 🆕 Dicas específicas para cada tipo de ativo
    private func getTipsForAssetType() -> String {
        switch assetType {
        case .bank:
            return "💡 Para contas bancárias, use o saldo atual como valor. O valor de compra pode ser o depósito inicial."
        case .savings:
            return "💡 Para poupanças, use o valor atual como saldo. O valor de compra é quanto depositou inicialmente."
        case .crypto:
            return "💡 O valor atual é obtido automaticamente da CoinMarketCap. Ajuste o valor de compra para o preço real que pagou."
        case .stock:
            return "💡 O valor atual é obtido do mercado. Insira o preço real que pagou por cada ação no valor de compra."
        case .interest:
            return "💡 Para obrigações, o valor nominal é usado. Ajuste o valor de compra se pagou prémio ou desconto."
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
            averagePrice: purchasePrice, // 🆕 Usar o preço de compra como custo médio
            currentPrice: currentPrice,
            lastUpdated: Date(),
            annualInterestRate: interestRate,
            lastInterestPayment: nil
        )
        
        portfolioManager.addAsset(asset, recordExpense: recordAsExpense)
        dismiss()
    }
}
