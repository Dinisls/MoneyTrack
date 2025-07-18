import Foundation
import Combine

class PortfolioManager: ObservableObject {
    @Published var portfolio = Portfolio()
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let portfolioKey = "portfolio_data_v6"
    private var timer: Timer?
    private var interestTimer: Timer?
    private var priceUpdateTimer: Timer? // 🆕 Timer para atualizações de preço
    
    weak var financeManager: FinanceManager?
    private let priceManager = PriceManager() // 🆕 Integração com PriceManager
    
    init() {
        loadData()
        startPriceUpdates()
        startInterestPayments()
        startRealTimePriceUpdates() // 🆕 Iniciar atualizações de preços reais
    }
    
    func setFinanceManager(_ manager: FinanceManager) {
        self.financeManager = manager
    }
    
    func loadData() {
        if let data = userDefaults.data(forKey: portfolioKey),
           let decodedPortfolio = try? JSONDecoder().decode(Portfolio.self, from: data) {
            self.portfolio = decodedPortfolio
        } else {
            // Dados de exemplo atualizados com juros
            let sampleAssets = [
                Asset(symbol: "CONTA", name: "Conta Corrente", type: .bank, quantity: 1, averagePrice: 2500, currentPrice: 2500, lastUpdated: Date()),
                Asset(symbol: "POUPANCA", name: "Conta Poupança", type: .savings, quantity: 1, averagePrice: 5000, currentPrice: 5150, lastUpdated: Date()),
                Asset(symbol: "BTC", name: "Bitcoin", type: .crypto, quantity: 0.5, averagePrice: 35000, currentPrice: 37500, lastUpdated: Date()),
                Asset(symbol: "AAPL", name: "Apple Inc.", type: .stock, quantity: 10, averagePrice: 150, currentPrice: 155, lastUpdated: Date()),
                Asset(symbol: "CA", name: "Certificados de Aforro", type: .interest, quantity: 1, averagePrice: 3000, currentPrice: 3000, lastUpdated: Date(), annualInterestRate: 2.5, lastInterestPayment: nil)
            ]
            self.portfolio.assets = sampleAssets
            self.saveData()
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(portfolio) {
            userDefaults.set(encoded, forKey: portfolioKey)
        }
    }
    
    func addAsset(_ asset: Asset, recordExpense: Bool = true) {
        let totalInvestment = asset.quantity * asset.averagePrice
        
        if let index = portfolio.assets.firstIndex(where: { $0.symbol == asset.symbol && $0.type == asset.type }) {
            let existingAsset = portfolio.assets[index]
            let totalQuantity = existingAsset.quantity + asset.quantity
            let totalCost = (existingAsset.quantity * existingAsset.averagePrice) + (asset.quantity * asset.averagePrice)
            let newAveragePrice = totalCost / totalQuantity
            
            portfolio.assets[index].quantity = totalQuantity
            portfolio.assets[index].averagePrice = newAveragePrice
            
            // Manter a taxa de juros se existir
            if asset.type == .interest && asset.annualInterestRate != nil {
                portfolio.assets[index].annualInterestRate = asset.annualInterestRate
            }
        } else {
            portfolio.assets.append(asset)
        }
        
        if recordExpense {
            registerAssetPurchaseAsExpense(asset: asset, totalAmount: totalInvestment)
        }
        
        saveData()
        
        // 🆕 Atualizar preço imediatamente para novos ativos
        Task {
            await updateAssetPrice(asset)
        }
    }
    
    func removeAsset(_ asset: Asset) {
        portfolio.assets.removeAll { $0.id == asset.id }
        saveData()
    }
    
    // 🆕 Sistema de atualizações de preços em tempo real
    private func startRealTimePriceUpdates() {
        // Atualizar preços a cada 5 minutos para criptos e ações
        priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.updateAllAssetPrices()
            }
        }
        
        // Primeira atualização imediata
        Task {
            await updateAllAssetPrices()
        }
    }
    
    // 🆕 Atualizar todos os preços dos ativos
    @MainActor
    func updateAllAssetPrices() async {
        isLoading = true
        var hasChanges = false
        
        for i in 0..<portfolio.assets.count {
            let asset = portfolio.assets[i]
            
            // Só atualizar preços para criptos, ações e obrigações
            if asset.type == .crypto || asset.type == .stock || asset.type == .interest {
                if let newPrice = await priceManager.getCurrentPrice(for: asset.symbol, type: asset.type) {
                    portfolio.assets[i].currentPrice = newPrice
                    portfolio.assets[i].lastUpdated = Date()
                    hasChanges = true
                    
                    print("💰 Preço atualizado: \(asset.symbol) - \(newPrice.toCurrency())")
                }
            }
        }
        
        if hasChanges {
            saveData()
        }
        
        isLoading = false
    }
    
    // 🆕 Atualizar preço de um ativo específico
    private func updateAssetPrice(_ asset: Asset) async {
        guard asset.type == .crypto || asset.type == .stock || asset.type == .interest else { return }
        
        if let newPrice = await priceManager.getCurrentPrice(for: asset.symbol, type: asset.type),
           let index = portfolio.assets.firstIndex(where: { $0.id == asset.id }) {
            
            await MainActor.run {
                portfolio.assets[index].currentPrice = newPrice
                portfolio.assets[index].lastUpdated = Date()
                saveData()
            }
        }
    }
    
    // 🆕 Forçar atualização manual de preços
    func forceUpdatePrices() {
        Task {
            await updateAllAssetPrices()
        }
    }
    
    // 🆕 Verificar se um ativo precisa de atualização de preço
    func assetNeedsUpdate(_ asset: Asset) -> Bool {
        guard asset.type == .crypto || asset.type == .stock else { return false }
        
        let timeSinceUpdate = Date().timeIntervalSince(asset.lastUpdated)
        return timeSinceUpdate > 300 // 5 minutos
    }
    
    // 🆕 Obter status da última atualização de preços
    func getLastUpdateStatus() -> String {
        let cryptoAssets = portfolio.assets.filter { $0.type == .crypto || $0.type == .stock }
        
        guard !cryptoAssets.isEmpty else { return "Sem ativos para atualizar" }
        
        let oldestUpdate = cryptoAssets.map { $0.lastUpdated }.min() ?? Date()
        let timeSinceUpdate = Date().timeIntervalSince(oldestUpdate)
        
        if timeSinceUpdate < 60 {
            return "Atualizado há poucos segundos"
        } else if timeSinceUpdate < 3600 {
            let minutes = Int(timeSinceUpdate / 60)
            return "Atualizado há \(minutes) minuto(s)"
        } else {
            let hours = Int(timeSinceUpdate / 3600)
            return "Atualizado há \(hours) hora(s)"
        }
    }
    
    // Resto do código existente...
    
    // 🆕 Iniciar sistema de pagamento de juros automático
    private func startInterestPayments() {
        // Verificar juros a cada hora (em produção pode ser diário)
        interestTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.processMonthlyInterest()
        }
        
        // Processar imediatamente na inicialização
        processMonthlyInterest()
    }
    
    // 🆕 Processar pagamento de juros mensais
    func processMonthlyInterest() {
        var hasChanges = false
        
        for i in 0..<portfolio.assets.count {
            var asset = portfolio.assets[i]
            
            if asset.shouldReceiveInterest() {
                let interestAmount = asset.calculateMonthlyInterest()
                
                if interestAmount > 0 {
                    // Adicionar juros ao valor atual
                    let newTotalValue = asset.totalValue + interestAmount
                    asset.currentPrice = newTotalValue / asset.quantity
                    asset.lastInterestPayment = Date()
                    asset.lastUpdated = Date()
                    
                    portfolio.assets[i] = asset
                    hasChanges = true
                    
                    // Registrar como receita de juros
                    registerInterestPayment(asset: asset, interestAmount: interestAmount)
                    
                    print("💰 Juros pagos: \(asset.name) - \(interestAmount.toCurrency())")
                }
            }
        }
        
        if hasChanges {
            saveData()
        }
    }
    
    // 🆕 Registrar pagamento de juros como receita (✅ CORRIGIDO)
    private func registerInterestPayment(asset: Asset, interestAmount: Double) {
        guard let financeManager = financeManager else { return }
        
        // ✅ Formatação correta da taxa de juros
        let interestRate = asset.annualInterestRate ?? 0
        let rateText = String(format: "%.1f", interestRate)
        let description = "Juros mensais de \(asset.name) (\(rateText)% ao ano)"
        
        let interestTransaction = Transaction(
            date: Date(),
            type: .interestEarned,
            category: "Juros Recebidos",
            amount: interestAmount,
            description: description,
            assetSymbol: asset.symbol,
            quantity: nil,
            price: nil
        )
        
        financeManager.addTransaction(interestTransaction)
        
        print("💰 Juros registrados: \(description) - \(interestAmount.toCurrency())")
    }
    
    // 🆕 Função manual para forçar pagamento de juros (para testes)
    func forceInterestPayment() {
        processMonthlyInterest()
    }
    
    // 🆕 Obter total de juros recebidos este mês
    func getMonthlyInterestEarned() -> Double {
        guard let financeManager = financeManager else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return financeManager.financeData.transactions
            .filter { $0.type == .interestEarned && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func registerAssetPurchaseAsExpense(asset: Asset, totalAmount: Double) {
        guard let financeManager = financeManager else { return }
        
        let category = getCategoryForAssetType(asset.type)
        let description = getDescriptionForAsset(asset)
        let transactionType = getTransactionTypeForAssetType(asset.type)
        
        let expenseTransaction = Transaction(
            date: Date(),
            type: transactionType,
            category: category,
            amount: totalAmount,
            description: description,
            assetSymbol: asset.symbol,
            quantity: asset.quantity,
            price: asset.averagePrice
        )
        
        financeManager.addTransaction(expenseTransaction)
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
    
    // ✅ CORRIGIDO: Descrição para ativos
    private func getDescriptionForAsset(_ asset: Asset) -> String {
        switch asset.type {
        case .bank:
            return "Depósito em \(asset.name)"
        case .savings:
            return "Depósito em \(asset.name)"
        case .crypto:
            return "Compra de \(asset.quantity.toCryptoQuantity()) \(asset.symbol)"
        case .stock:
            if asset.quantity == floor(asset.quantity) {
                return "Compra de \(Int(asset.quantity)) ações \(asset.symbol)"
            } else {
                return "Compra de \(asset.quantity.toQuantityString()) ações \(asset.symbol)"
            }
        case .interest:
            let rateText = asset.annualInterestRate != nil ? " (\(asset.annualInterestRate!.toPercentageString())% ao ano)" : ""
            return "Investimento em \(asset.name)\(rateText)"
        }
    }
    
    private func getTransactionTypeForAssetType(_ type: Asset.AssetType) -> Transaction.TransactionType {
        switch type {
        case .bank: return .bankDeposit
        case .savings: return .savingsDeposit
        case .crypto: return .cryptoBuy
        case .stock: return .stockBuy
        case .interest: return .interestInvestment
        }
    }
    
    func getBankBalance() -> Double {
        portfolio.assets.filter { $0.type == .bank }.reduce(0) { $0 + $1.totalValue }
    }
    
    func getSavingsBalance() -> Double {
        portfolio.assets.filter { $0.type == .savings }.reduce(0) { $0 + $1.totalValue }
    }
    
    func getCryptoBalance() -> Double {
        portfolio.assets.filter { $0.type == .crypto }.reduce(0) { $0 + $1.totalValue }
    }
    
    func getStockBalance() -> Double {
        portfolio.assets.filter { $0.type == .stock }.reduce(0) { $0 + $1.totalValue }
    }
    
    func getInterestBalance() -> Double {
        portfolio.assets.filter { $0.type == .interest }.reduce(0) { $0 + $1.totalValue }
    }
    
    private func startPriceUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updatePrices()
        }
    }
    
    private func updatePrices() {
        for i in 0..<portfolio.assets.count {
            let randomChange: Double
            
            switch portfolio.assets[i].type {
            case .bank:
                randomChange = 0
            case .savings:
                randomChange = Double.random(in: 0...0.001)
            case .crypto:
                // Não usar mudanças aleatórias se temos preços reais
                randomChange = priceManager.areAPIsConfigured() ? 0 : Double.random(in: -0.05...0.05)
            case .stock:
                // Não usar mudanças aleatórias se temos preços reais
                randomChange = priceManager.areAPIsConfigured() ? 0 : Double.random(in: -0.02...0.02)
            case .interest:
                // Juros não têm volatilidade - crescem apenas com os pagamentos mensais
                randomChange = 0
            }
            
            if randomChange != 0 {
                portfolio.assets[i].currentPrice *= (1 + randomChange)
                portfolio.assets[i].lastUpdated = Date()
            }
        }
        
        if !priceManager.areAPIsConfigured() {
            saveData()
        }
    }
    
    deinit {
        timer?.invalidate()
        interestTimer?.invalidate()
        priceUpdateTimer?.invalidate()
    }
}
