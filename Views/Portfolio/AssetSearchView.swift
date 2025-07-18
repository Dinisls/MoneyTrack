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

struct AssetDetailsView: View {
    let asset: AssetSearchResult
    let priceManager: PriceManager
    let portfolioManager: PortfolioManager
    
    @Binding var recordAsExpense: Bool
    @Binding var annualInterestRate: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var quantity = ""
    @State private var currentPrice = ""
    @State private var isLoadingPrice = false
    
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
                
                Section(header: Text("Preço Atual")) {
                    HStack {
                        Text("Preço por unidade:")
                        Spacer()
                        if isLoadingPrice {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            TextField("€", text: $currentPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Button("Atualizar Preço") {
                        updateCurrentPrice()
                    }
                    .disabled(isLoadingPrice)
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
                    }
                }
                
                Section(header: Text("Configurações")) {
                    Toggle("Registrar como despesa", isOn: $recordAsExpense)
                }
                
                if let qty = Double(quantity), let price = Double(currentPrice) {
                    Section(header: Text("Resumo")) {
                        HStack {
                            Text("Valor Total:")
                            Spacer()
                            Text((qty * price).toCurrency())
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Adicionar Ativo")
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
                if asset.currentPrice == 0 {
                    updateCurrentPrice()
                }
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
    
    private var isValidForm: Bool {
        guard let _ = Double(quantity), let _ = Double(currentPrice) else { return false }
        
        if asset.type == .interest {
            return Double(annualInterestRate) != nil
        }
        
        return true
    }
    
    private func updateCurrentPrice() {
        isLoadingPrice = true
        
        Task {
            if let price = await priceManager.getCurrentPrice(for: asset.symbol, type: asset.type) {
                await MainActor.run {
                    currentPrice = String(price)
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
              let price = Double(currentPrice) else { return }
        
        let interestRate: Double? = asset.type == .interest ? Double(annualInterestRate) : nil
        
        let newAsset = Asset(
            symbol: asset.symbol,
            name: asset.name,
            type: asset.type,
            quantity: qty,
            averagePrice: price,
            currentPrice: price,
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
