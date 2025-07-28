import Foundation
import Combine

// MARK: - Currency Models
enum Currency: String, CaseIterable, Codable {
    case EUR = "EUR"
    case USD = "USD"
    
    var symbol: String {
        switch self {
        case .EUR: return "€"
        case .USD: return "$"
        }
    }
    
    var name: String {
        switch self {
        case .EUR: return "Euro"
        case .USD: return "Dólar Americano"
        }
    }
    
    var flag: String {
        switch self {
        case .EUR: return "🇪🇺"
        case .USD: return "🇺🇸"
        }
    }
}

struct ExchangeRate: Codable {
    let fromCurrency: String
    let toCurrency: String
    let rate: Double
    let lastUpdated: Date
}

struct ExchangeRateResponse: Codable {
    let success: Bool
    let timestamp: Int
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Currency Manager
class CurrencyManager: ObservableObject {
    @Published var selectedCurrency: Currency = .EUR
    @Published var exchangeRates: [String: Double] = [:]
    @Published var isLoadingRates = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let selectedCurrencyKey = "selected_currency_v1"
    private let exchangeRatesKey = "exchange_rates_v1"
    private let lastUpdateKey = "last_exchange_update_v1"
    
    // API gratuita para taxas de câmbio (pode usar exchangerate-api.com)
    private let exchangeAPIKey = "YOUR_EXCHANGE_API_KEY" // Substituir pela sua chave
    private let session = URLSession.shared
    private var updateTimer: Timer?
    
    init() {
        loadSettings()
        startPeriodicUpdates()
        
        // Carregar taxas salvas
        loadSavedRates()
        
        // Primeira atualização se necessário
        if shouldUpdateRates() {
            updateExchangeRates()
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        if let currencyString = userDefaults.string(forKey: selectedCurrencyKey),
           let currency = Currency(rawValue: currencyString) {
            selectedCurrency = currency
        }
    }
    
    private func saveSettings() {
        userDefaults.set(selectedCurrency.rawValue, forKey: selectedCurrencyKey)
    }
    
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveSettings()
        
        // Atualizar taxas se mudou para USD
        if currency == .USD && shouldUpdateRates() {
            updateExchangeRates()
        }
    }
    
    // MARK: - Exchange Rate Management
    
    private func loadSavedRates() {
        if let data = userDefaults.data(forKey: exchangeRatesKey),
           let rates = try? JSONDecoder().decode([String: Double].self, from: data) {
            exchangeRates = rates
        }
        
        if let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTime = lastUpdate
        }
    }
    
    private func saveRates() {
        if let data = try? JSONEncoder().encode(exchangeRates) {
            userDefaults.set(data, forKey: exchangeRatesKey)
        }
        userDefaults.set(Date(), forKey: lastUpdateKey)
    }
    
    private func shouldUpdateRates() -> Bool {
        guard let lastUpdate = lastUpdateTime else { return true }
        
        // Atualizar a cada 4 horas
        let timeInterval = Date().timeIntervalSince(lastUpdate)
        return timeInterval > 14400 // 4 horas em segundos
    }
    
    func updateExchangeRates() {
        guard !isLoadingRates else { return }
        
        isLoadingRates = true
        errorMessage = nil
        
        // Usar API gratuita como fallback se não temos chave configurada
        if exchangeAPIKey == "YOUR_EXCHANGE_API_KEY" || exchangeAPIKey.isEmpty {
            // Usar taxas aproximadas como fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.exchangeRates = [
                    "USD": 1.10, // 1 EUR = 1.10 USD (aproximado)
                    "EUR": 1.0
                ]
                self.lastUpdateTime = Date()
                self.saveRates()
                self.isLoadingRates = false
            }
            return
        }
        
        // Usar API real se temos chave
        fetchRealExchangeRates()
    }
    
    private func fetchRealExchangeRates() {
        let urlString = "https://api.exchangerate-api.com/v4/latest/EUR"
        
        guard let url = URL(string: urlString) else {
            isLoadingRates = false
            return
        }
        
        session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingRates = false
                
                if let error = error {
                    self?.errorMessage = "Erro ao obter taxas: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Dados não recebidos"
                    return
                }
                
                do {
                    let rateResponse = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                    self?.exchangeRates = rateResponse.rates
                    self?.lastUpdateTime = Date()
                    self?.saveRates()
                } catch {
                    self?.errorMessage = "Erro ao processar dados: \(error.localizedDescription)"
                    
                    // Fallback para taxas aproximadas
                    self?.exchangeRates = [
                        "USD": 1.10,
                        "EUR": 1.0
                    ]
                    self?.lastUpdateTime = Date()
                    self?.saveRates()
                }
            }
        }.resume()
    }
    
    private func startPeriodicUpdates() {
        // Atualizar taxas a cada 4 horas
        updateTimer = Timer.scheduledTimer(withTimeInterval: 14400, repeats: true) { _ in
            self.updateExchangeRates()
        }
    }
    
    // MARK: - Currency Conversion
    
    func convert(_ amount: Double, from: Currency, to: Currency) -> Double {
        if from == to { return amount }
        
        // Se convertendo de EUR para USD
        if from == .EUR && to == .USD {
            return amount * (exchangeRates["USD"] ?? 1.10)
        }
        
        // Se convertendo de USD para EUR
        if from == .USD && to == .EUR {
            let usdRate = exchangeRates["USD"] ?? 1.10
            return amount / usdRate
        }
        
        return amount
    }
    
    func formatPrice(_ amount: Double, in currency: Currency = .EUR) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        switch currency {
        case .EUR:
            formatter.currencyCode = "EUR"
            formatter.currencySymbol = "€"
        case .USD:
            formatter.currencyCode = "USD"
            formatter.currencySymbol = "$"
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)0,00"
    }
    
    // MARK: - Utility Functions
    
    func getDisplayPrice(_ eurAmount: Double) -> String {
        switch selectedCurrency {
        case .EUR:
            return formatPrice(eurAmount, in: .EUR)
        case .USD:
            let usdAmount = convert(eurAmount, from: .EUR, to: .USD)
            return formatPrice(usdAmount, in: .USD)
        }
    }
    
    func getBothCurrencies(_ eurAmount: Double) -> (eur: String, usd: String) {
        let eurFormatted = formatPrice(eurAmount, in: .EUR)
        let usdAmount = convert(eurAmount, from: .EUR, to: .USD)
        let usdFormatted = formatPrice(usdAmount, in: .USD)
        
        return (eur: eurFormatted, usd: usdFormatted)
    }
    
    func getExchangeRateString() -> String {
        let usdRate = exchangeRates["USD"] ?? 1.10
        return "1 € = \(String(format: "%.4f", usdRate)) $"
    }
    
    func getLastUpdateString() -> String {
        guard let lastUpdate = lastUpdateTime else {
            return "Nunca atualizado"
        }
        
        let timeInterval = Date().timeIntervalSince(lastUpdate)
        
        if timeInterval < 60 {
            return "Atualizado há poucos segundos"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "Atualizado há \(minutes) minuto(s)"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "Atualizado há \(hours) hora(s)"
        } else {
            let days = Int(timeInterval / 86400)
            return "Atualizado há \(days) dia(s)"
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
