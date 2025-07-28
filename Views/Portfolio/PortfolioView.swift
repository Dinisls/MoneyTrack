import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    @State private var showingAddAsset = false
    @State private var showingAssetSearch = false
    @State private var showingBankTransaction = false
    @State private var selectedAssetType: Asset.AssetType = .bank
    @State private var showingActionSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header com informações de atualização
                if !portfolioManager.portfolio.assets.isEmpty {
                    PriceUpdateHeader()
                }
                
                // ✅ Quick Actions para Banco/Mealheiro/Juros
                if hasFinancialAccounts {
                    QuickActionsBar(showingBankTransaction: $showingBankTransaction)
                }
                
                // ✅ SEMPRE MOSTRAR: Picker de seções (mesmo quando vazio)
                Picker("Tipo de Ativo", selection: $selectedAssetType) {
                    ForEach(Asset.AssetType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Lista ou Empty State
                if filteredAssets.isEmpty {
                    EmptyPortfolioView(selectedAssetType: selectedAssetType) {
                        // ✅ COMPORTAMENTO INTELIGENTE: Mesmo comportamento do botão +
                        if selectedAssetType == .bank || selectedAssetType == .savings || selectedAssetType == .interest {
                            showingAddAsset = true
                        } else {
                            showingActionSheet = true
                        }
                    }
                } else {
                    List {
                        ForEach(filteredAssets) { asset in
                            EnhancedAssetRowView(asset: asset)
                                .onTapGesture {
                                    // Mostrar transações bancárias se for conta financeira
                                    if asset.type == .bank || asset.type == .savings || asset.type == .interest {
                                        showingBankTransaction = true
                                    } else if portfolioManager.assetNeedsUpdate(asset) {
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
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // ✅ Botão de transações bancárias (só aparece se há contas bancárias)
                    if hasFinancialAccounts {
                        Button(action: {
                            showingBankTransaction = true
                        }) {
                            Image(systemName: "creditcard")
                        }
                        .help("Transações bancárias")
                    }
                    
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
                    
                    // Botão de adicionar ativo - ✅ COMPORTAMENTO INTELIGENTE
                    Button(action: {
                        // Se está numa seção financeira, vai direto para adicionar manualmente
                        if selectedAssetType == .bank || selectedAssetType == .savings || selectedAssetType == .interest {
                            showingAddAsset = true
                        } else {
                            // Para crypto/ações, mostra opções
                            showingActionSheet = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Adicionar \(selectedAssetType.rawValue)"),
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
            .sheet(isPresented: $showingBankTransaction) {
                BankTransactionView(preselectedType: nil)
            }
        }
    }
    
    // ✅ Propriedade: Verificar se tem contas financeiras
    private var hasFinancialAccounts: Bool {
        portfolioManager.portfolio.assets.contains { asset in
            asset.type == .bank || asset.type == .savings || asset.type == .interest
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

// MARK: - Quick Actions Bar
struct QuickActionsBar: View {
    @Binding var showingBankTransaction: Bool
    @State private var selectedTransactionType: BankTransactionView.BankTransactionType? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ações Rápidas")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Entrada",
                        icon: "plus.circle.fill",
                        color: .green,
                        description: "Receber dinheiro"
                    ) {
                        selectedTransactionType = .deposit
                        showingBankTransaction = true
                    }
                    
                    QuickActionButton(
                        title: "Saída",
                        icon: "minus.circle.fill",
                        color: .red,
                        description: "Gastar dinheiro"
                    ) {
                        selectedTransactionType = .withdrawal
                        showingBankTransaction = true
                    }
                    
                    QuickActionButton(
                        title: "Transferir",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .blue,
                        description: "Entre contas"
                    ) {
                        selectedTransactionType = nil // Deixar user escolher
                        showingBankTransaction = true
                    }
                    
                    QuickActionButton(
                        title: "Poupança",
                        icon: "banknote.fill",
                        color: .orange,
                        description: "Para mealheiro"
                    ) {
                        selectedTransactionType = .transferToSavings
                        showingBankTransaction = true
                    }
                    
                    QuickActionButton(
                        title: "Investir",
                        icon: "percent",
                        color: .mint,
                        description: "Em juros"
                    ) {
                        selectedTransactionType = .transferToInterest
                        showingBankTransaction = true
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showingBankTransaction) {
            BankTransactionView(preselectedType: selectedTransactionType)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 75)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                // Ícone e título
                VStack(spacing: 16) {
                    Image(systemName: iconForAssetType)
                        .font(.system(size: 60))
                        .foregroundColor(colorForAssetType)
                    
                    Text("Nenhum \(selectedAssetType.rawValue.lowercased()) encontrado")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                // Descrição
                Text(descriptionForAssetType)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Botão de ação
                Button(action: addAction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Adicionar \(selectedAssetType.rawValue)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(colorForAssetType)
                    .cornerRadius(25)
                }
                
                // ✅ Dicas específicas por tipo
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 Dicas:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(tipsForAssetType, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(colorForAssetType)
                                .fontWeight(.bold)
                            Text(tip)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var iconForAssetType: String {
        switch selectedAssetType {
        case .bank: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .interest: return "percent"
        }
    }
    
    private var colorForAssetType: Color {
        switch selectedAssetType {
        case .bank: return .blue
        case .savings: return .green
        case .crypto: return .orange
        case .stock: return .purple
        case .interest: return .mint
        }
    }
    
    private var descriptionForAssetType: String {
        switch selectedAssetType {
        case .bank:
            return "Adicione suas contas bancárias para começar a controlar seu dinheiro e fazer transações"
        case .savings:
            return "Crie mealheiros e contas poupança para organizar suas economias"
        case .crypto:
            return "Invista em criptomoedas e acompanhe seus preços em tempo real"
        case .stock:
            return "Construa seu portfólio de ações com cotações atualizadas do mercado"
        case .interest:
            return "Invista em produtos que geram juros automáticos mensalmente"
        }
    }
    
    private var tipsForAssetType: [String] {
        switch selectedAssetType {
        case .bank:
            return [
                "Adicione sua conta principal primeiro",
                "Use nomes claros como 'Conta CGD' ou 'Cartão Millennium'",
                "Depois poderá fazer transferências entre contas"
            ]
        case .savings:
            return [
                "Perfeito para organizar objetivos de poupança",
                "Pode definir taxas de juro se aplicável",
                "Transfer dinheiro diretamente do banco"
            ]
        case .crypto:
            return [
                "Use a busca para encontrar preços atuais",
                "Bitcoin, Ethereum e outras moedas populares",
                "Preços atualizados automaticamente"
            ]
        case .stock:
            return [
                "Busque por ticker (AAPL, TSLA, MSFT)",
                "Preços em tempo real dos mercados",
                "Acompanhe lucros e prejuízos"
            ]
        case .interest:
            return [
                "Certificados de Aforro, Obrigações do Tesouro",
                "Juros calculados e pagos automaticamente",
                "Defina a taxa de juro anual"
            ]
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
                        
                        // ✅ Indicador para contas que podem fazer transações
                        if asset.type == .bank || asset.type == .savings || asset.type == .interest {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
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
                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.caption2)
                                .foregroundColor(.mint)
                            Text("\(rate.toPercentageString())% ao ano")
                                .font(.caption)
                                .foregroundColor(.mint)
                        }
                    }
                    
                    // ✅ Dica para contas bancárias
                    if asset.type == .bank || asset.type == .savings || asset.type == .interest {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Toque para transações")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(asset.totalValue.toCurrency())
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // Mostrar lucro/prejuízo apenas para investimentos
                    if asset.type == .crypto || asset.type == .stock {
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
                        
                        Text("Atualizado: \(timeAgoSince(asset.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        // Para contas bancárias, mostrar info de saldo
                        Text("Saldo disponível")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if asset.type == .interest, let rate = asset.annualInterestRate {
                            let monthlyInterest = asset.calculateMonthlyInterest()
                            if monthlyInterest > 0 {
                                Text("Próximos juros: \(monthlyInterest.toCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.mint)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .contentShape(Rectangle()) // Torna toda a área clicável
        .background(
            // Background diferenciado para contas financeiras
            (asset.type == .bank || asset.type == .savings || asset.type == .interest) ?
            Color.blue.opacity(0.05) : Color.clear
        )
        .cornerRadius(8)
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
