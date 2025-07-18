import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    @State private var showingAddAsset = false
    @State private var showingAssetSearch = false
    @State private var selectedAssetType: Asset.AssetType = .crypto
    @State private var showingActionSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header com informações de atualização
                if !portfolioManager.portfolio.assets.isEmpty {
                    PriceUpdateHeader()
                }
                
                if !portfolioManager.portfolio.assets.isEmpty {
                    Picker("Tipo de Ativo", selection: $selectedAssetType) {
                        ForEach(Asset.AssetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
                
                List {
                    ForEach(filteredAssets) { asset in
                        AssetRowView(asset: asset)
                            .onTapGesture {
                                // Atualizar preço individual se necessário
                                if portfolioManager.assetNeedsUpdate(asset) {
                                    portfolioManager.forceUpdatePrices()
                                }
                            }
                    }
                    .onDelete(perform: deleteAssets)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    // Pull to refresh para atualizar preços
                    await portfolioManager.updateAllAssetPrices()
                }
                
                if filteredAssets.isEmpty {
                    EmptyPortfolioView(selectedAssetType: selectedAssetType) {
                        showingActionSheet = true
                    }
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Botão de atualizar preços
                    if portfolioManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: {
                            portfolioManager.forceUpdatePrices()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Atualizar preços")
                    }
                    
                    // Botão de adicionar ativo
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Adicionar Ativo"),
                    message: Text("Escolha como deseja adicionar o ativo"),
                    buttons: [
                        .default(Text("🔍 Buscar com Preços Reais")) {
                            showingAssetSearch = true
                        },
                        .default(Text("✏️ Adicionar Manualmente")) {
                            showingAddAsset = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingAddAsset) {
                AddAssetView()
            }
            .sheet(isPresented: $showingAssetSearch) {
                AssetSearchView()
            }
        }
    }
    
    private var filteredAssets: [Asset] {
        portfolioManager.portfolio.assets.filter { $0.type == selectedAssetType }
    }
    
    private func deleteAssets(offsets: IndexSet) {
        for index in offsets {
            let asset = filteredAssets[index]
            portfolioManager.removeAsset(asset)
        }
    }
}

// MARK: - Supporting Views

struct PriceUpdateHeader: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(portfolioManager.getLastUpdateStatus())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if portfolioManager.isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Atualizando...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Indicador de status das APIs
            APIStatusIndicator()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct APIStatusIndicator: View {
    @StateObject private var priceManager = PriceManager()
    
    var body: some View {
        HStack(spacing: 12) {
            StatusIndicatorDot(
                isActive: priceManager.areAPIsConfigured(),
                activeText: "APIs Configuradas",
                inactiveText: "APIs Não Configuradas"
            )
            
            Spacer()
            
            if priceManager.areAPIsConfigured() {
                Text("Preços em tempo real ativos")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Usando preços simulados")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

struct StatusIndicatorDot: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
            
            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyPortfolioView: View {
    let selectedAssetType: Asset.AssetType
    let addAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconForAssetType)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Nenhum \(selectedAssetType.rawValue.lowercased()) encontrado")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(descriptionForAssetType)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: addAction) {
                Label("Adicionar \(selectedAssetType.rawValue)", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var iconForAssetType: String {
        switch selectedAssetType {
        case .bank: return "building.columns"
        case .savings: return "dollarsign.circle"
        case .crypto: return "bitcoinsign.circle"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .interest: return "percent"
        }
    }
    
    private var descriptionForAssetType: String {
        switch selectedAssetType {
        case .bank:
            return "Adicione suas contas bancárias, cartões e dinheiro em carteira"
        case .savings:
            return "Adicione suas contas poupança e mealheiros"
        case .crypto:
            return "Adicione suas criptomoedas com preços em tempo real da CoinMarketCap"
        case .stock:
            return "Adicione suas ações com cotações atualizadas do mercado"
        case .interest:
            return "Adicione seus investimentos em obrigações e certificados com juros automáticos"
        }
    }
}

// MARK: - Enhanced Asset Row View

struct EnhancedAssetRowView: View {
    let asset: Asset
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(asset.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if portfolioManager.assetNeedsUpdate(asset) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    
                    Text(asset.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(asset.quantity.toQuantityString()) unidades")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Indicador de taxa de juros para investimentos
                    if asset.type == .interest, let rate = asset.annualInterestRate {
                        Text("\(rate.toPercentageString())% ao ano")
                            .font(.caption)
                            .foregroundColor(.mint)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(asset.totalValue.toCurrency())
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: asset.profitLoss >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(abs(asset.profitLoss).toCurrency())
                        Text("(\(asset.profitLossPercentage.toPercentage()))")
                            .font(.caption)
                    }
                    .foregroundColor(asset.profitLoss >= 0 ? .green : .red)
                    
                    Text("Preço: \(asset.currentPrice.toCurrency())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Timestamp da última atualização
                    if asset.type == .crypto || asset.type == .stock {
                        Text("Atualizado: \(timeAgoSince(asset.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func timeAgoSince(_ date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "agora"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
}

#Preview {
    PortfolioView()
        .environmentObject(PortfolioManager())
}
