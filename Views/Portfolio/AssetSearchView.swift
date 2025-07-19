import SwiftUI

struct AssetSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioManager: PortfolioManager
    @StateObject private var priceManager = PriceManager()
    
    @State private var searchText = ""
    @State private var selectedAssetType: Asset.AssetType = .crypto
    @State private var quantity = ""
    @State private var recordAsExpense = true
    @State private var selectedAsset: AssetSearchResult?
    @State private var showingAssetDetails = false
    @State private var annualInterestRate = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Picker de tipo de ativo
                Picker("Tipo de Ativo", selection: $selectedAssetType) {
                    Text("Criptomoedas").tag(Asset.AssetType.crypto)
                    Text("Ações").tag(Asset.AssetType.stock)
                    Text("Obrigações").tag(Asset.AssetType.interest)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedAssetType) { _ in
                    searchText = ""
                    priceManager.searchResults = []
                }
                
                // Barra de pesquisa
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                // Status das APIs
                if !priceManager.areAPIsConfigured() {
                    APIStatusBanner()
                }
                
                // Loading indicator
                if priceManager.isLoading {
                    ProgressView("Buscando ativos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Lista de resultados
                    List {
                        if searchText.isEmpty {
                            // Mostrar ativos populares quando não há busca
                            PopularAssetsSection(
                                assetType: selectedAssetType,
                                priceManager: priceManager,
                                onAssetSelected: { asset in
                                    selectedAsset = asset
                                    showingAssetDetails = true
                                }
                            )
                        } else {
                            // Resultados da busca
                            ForEach(priceManager.searchResults) { asset in
                                AssetSearchRowView(asset: asset) {
                                    selectedAsset = asset
                                    showingAssetDetails = true
                                }
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage = priceManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Buscar Ativos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAssetDetails) {
                if let asset = selectedAsset {
                    AssetDetailsView(
                        asset: asset,
                        priceManager: priceManager,
                        portfolioManager: portfolioManager,
                        recordAsExpense: $recordAsExpense,
                        annualInterestRate: $annualInterestRate
                    )
                }
            }
        }
    }
    
    private func performSearch() {
        switch selectedAssetType {
        case .crypto:
            priceManager.searchCryptos(query: searchText)
        case .stock:
            priceManager.searchStocks(query: searchText)
        case .interest:
            priceManager.searchBonds(query: searchText)
        case .bank, .savings:
            break
        }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Buscar ativo...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Buscar") {
                onSearchButtonClicked()
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal)
    }
}

struct APIStatusBanner: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("APIs não configuradas")
                    .fontWeight(.medium)
            }
            
            Text("Para obter preços em tempo real, configure as chaves da CoinMarketCap e Alpha Vantage no PriceManager.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct PopularAssetsSection: View {
    let assetType: Asset.AssetType
    let priceManager: PriceManager
    let onAssetSelected: (AssetSearchResult) -> Void
    
    var popularAssets: [AssetSearchResult] {
        switch assetType {
        case .crypto:
            return priceManager.getPopularCryptos()
        case .stock:
            return priceManager.getPopularStocks()
        case .interest:
            return [
                AssetSearchResult(symbol: "CA", name: "Certificados de Aforro", type: .interest, currentPrice: 1000, change24h: nil),
                AssetSearchResult(symbol: "CT", name: "Certificados do Tesouro", type: .interest, currentPrice: 1000, change24h: nil),
                AssetSearchResult(symbol: "OT", name: "Obrigações do Tesouro", type: .interest, currentPrice: 1000, change24h: nil)
            ]
        case .bank, .savings:
            return []
        }
    }
    
    var body: some View {
        Section(header: Text("Ativos Populares")) {
            ForEach(popularAssets) { asset in
                AssetSearchRowView(asset: asset) {
                    onAssetSelected(asset)
                }
            }
        }
    }
}

struct AssetSearchRowView: View {
    let asset: AssetSearchResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(asset.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if asset.type == .crypto || asset.type == .stock {
                        Text("Tipo: \(asset.type.rawValue)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if asset.currentPrice > 0 {
                        Text(asset.currentPrice.toCurrency())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    if let change = asset.change24h {
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text("\(abs(change), specifier: "%.2f")%")
                                .font(.caption)
                        }
                        .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 🆕 MELHORADA: AssetDetailsView com Separação de Preços

struct AssetDetailsView: View {
    let asset: AssetSearchResult
    let priceManager: PriceManager
    let portfolioManager: PortfolioManager
    
    @Binding var recordAsExpense: Bool
    @Binding var annualInterestRate: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var quantity = ""
    @State private var currentPrice = ""
    @State private var purchasePrice = "" // 🆕 Separar preço de compra
    @State private var isLoadingPrice = false
    @State private var showingPriceHelp = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ativo Selecionado")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(asset.symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(asset.name)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("Tipo: \(asset.type.rawValue)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 🆕 NOVA SEÇÃO: Preços separados com explicação
                Section(header:
                    HStack {
                        Text("Preços")
                        Spacer()
                        Button(action: { showingPriceHelp = true }) {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                ) {
                    // Preço atual do mercado
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Valor Atual do Mercado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if isLoadingPrice {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Button("🔄") {
                                    updateCurrentPrice()
                                }
                                .font(.caption)
                            }
                        }
                        
                        HStack {
                            TextField("€", text: $currentPrice)
                                .keyboardType(.decimalPad)
                            
                            Button("Atualizar") {
                                updateCurrentPrice()
                            }
                            .font(.caption)
                            .disabled(isLoadingPrice)
                        }
                    }
                    
                    Divider()
                    
                    // Preço de compra
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Valor de Compra (preço que pagou)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Copiar do atual") {
                                purchasePrice = currentPrice
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .disabled(currentPrice.isEmpty)
                        }
                        
                        TextField("Preço real pago por unidade (€)", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    // 🆕 Mostrar diferença se ambos os preços estão preenchidos
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
                            
                            Text("Diferença por unidade: \(abs(difference).toCurrency()) (\(abs(percentageChange).toPercentage()))")
                                .font(.caption)
                                .foregroundColor(difference >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(difference >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                Section(header: Text("Quantidade")) {
                    TextField(quantityLabel, text: $quantity)
                        .keyboardType(.decimalPad)
                }
                
                if asset.type == .interest {
                    Section(header: Text("Taxa de Juros")) {
                        HStack {
                            TextField("Taxa anual", text: $annualInterestRate)
                                .keyboardType(.decimalPad)
                            Text("% ao ano")
                                .foregroundColor(.secondary)
                        }
                        
                        if let rate = Double(annualInterestRate), let amount = Double(currentPrice) {
                            let monthlyInterest = (amount * rate / 12 / 100)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Juros mensais estimados: \(monthlyInterest.toCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section(header: Text("Configurações")) {
                    Toggle("Registrar como despesa", isOn: $recordAsExpense)
                    
                    if recordAsExpense {
                        Text("O valor investido será automaticamente registrado como despesa.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 🆕 Resumo detalhado
                if let qty = Double(quantity) {
                    Section(header: Text("Resumo do Investimento")) {
                        if let purchasePriceValue = Double(purchasePrice) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Valor Total Investido")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text((qty * purchasePriceValue).toCurrency())
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if let currentPriceValue = Double(currentPrice) {
                                    VStack(alignment: .trailing) {
                                        Text("Valor Atual")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text((qty * currentPriceValue).toCurrency())
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            
                            // Lucro/Prejuízo total
                            if let currentPriceValue = Double(currentPrice),
                               let purchasePriceValue = Double(purchasePrice) {
                                let totalDifference = qty * (currentPriceValue - purchasePriceValue)
                                let percentageChange = (totalDifference / (qty * purchasePriceValue)) * 100
                                
                                Divider()
                                
                                HStack {
                                    Image(systemName: totalDifference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(totalDifference >= 0 ? .green : .red)
                                    
                                    VStack(alignment: .leading) {
                                        Text(totalDifference >= 0 ? "Lucro Atual" : "Prejuízo Atual")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(abs(totalDifference).toCurrency()) (\(abs(percentageChange).toPercentage()))")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(totalDifference >= 0 ? .green : .red)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(totalDifference >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // 🆕 Dicas baseadas no tipo de ativo
                Section(header: Text("💡 Dica")) {
                    Text(getTipForAssetType())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Adicionar \(asset.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Adicionar") {
                        addAsset()
                    }
                    .disabled(!isValidForm)
                }
            }
            .onAppear {
                currentPrice = String(asset.currentPrice)
                // 🆕 Automaticamente copiar preço atual para preço de compra na primeira vez
                if purchasePrice.isEmpty {
                    purchasePrice = String(asset.currentPrice)
                }
                
                if asset.currentPrice == 0 {
                    updateCurrentPrice()
                }
            }
            .alert("Sobre os Preços", isPresented: $showingPriceHelp) {
                Button("OK") { }
            } message: {
                Text("🔹 Valor Atual: Preço do ativo no mercado neste momento\n🔹 Valor de Compra: Preço real que pagou quando comprou\n\nEsta separação permite calcular com precisão o seu lucro ou prejuízo real.")
            }
        }
    }
    
    private var quantityLabel: String {
        switch asset.type {
        case .crypto: return "Quantidade (ex: 0.5)"
        case .stock: return "Número de ações"
        case .interest: return "Valor nominal"
        case .bank, .savings: return "Quantidade"
        }
    }
    
    private func getTipForAssetType() -> String {
        switch asset.type {
        case .crypto:
            return "O preço atual é obtido em tempo real. Ajuste o valor de compra para o preço exato que pagou na exchange."
        case .stock:
            return "Cotação atual do mercado. No valor de compra, coloque o preço real por ação que pagou (incluindo taxas se desejar)."
        case .interest:
            return "Para obrigações, o valor atual é o nominal. Ajuste o valor de compra se pagou prémio ou desconto."
        case .bank, .savings:
            return "Para contas, use o saldo atual e o valor inicial depositado."
        }
    }
    
    private var isValidForm: Bool {
        guard !quantity.isEmpty,
              !currentPrice.isEmpty,
              !purchasePrice.isEmpty,
              Double(quantity) != nil,
              Double(currentPrice) != nil,
              Double(purchasePrice) != nil else { return false }
        
        if asset.type == .interest {
            return !annualInterestRate.isEmpty && Double(annualInterestRate) != nil
        }
        
        return true
    }
    
    private func updateCurrentPrice() {
        isLoadingPrice = true
        
        Task {
            if let price = await priceManager.getCurrentPrice(for: asset.symbol, type: asset.type) {
                await MainActor.run {
                    currentPrice = String(price)
                    // 🆕 Se ainda não há preço de compra definido, copiar automaticamente
                    if purchasePrice.isEmpty {
                        purchasePrice = String(price)
                    }
                    isLoadingPrice = false
                }
            } else {
                await MainActor.run {
                    isLoadingPrice = false
                }
            }
        }
    }
    
    private func addAsset() {
        guard let qty = Double(quantity),
              let currentPriceValue = Double(currentPrice),
              let purchasePriceValue = Double(purchasePrice) else { return }
        
        let interestRate: Double? = asset.type == .interest ? Double(annualInterestRate) : nil
        
        let newAsset = Asset(
            symbol: asset.symbol,
            name: asset.name,
            type: asset.type,
            quantity: qty,
            averagePrice: purchasePriceValue, // 🆕 Usar o preço de compra real
            currentPrice: currentPriceValue,  // 🆕 Manter o preço atual do mercado
            lastUpdated: Date(),
            annualInterestRate: interestRate,
            lastInterestPayment: nil
        )
        
        portfolioManager.addAsset(newAsset, recordExpense: recordAsExpense)
        dismiss()
    }
}

#Preview {
    AssetSearchView()
        .environmentObject(PortfolioManager())
}
