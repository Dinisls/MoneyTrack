import Foundation
import Combine

// MARK: - Models para APIs
struct CoinMarketCapResponse: Codable {
    let data: [String: CryptoData]
}

struct CryptoData: Codable {
    let id: Int
    let name: String
    let symbol: String
    let quote: Quote
}

struct Quote: Codable {
    let EUR: PriceInfo
}

struct PriceInfo: Codable {
    let price: Double
    let percent_change_24h: Double
    let last_updated: String
}

struct StockData: Codable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
}

struct BondData: Codable {
    let symbol: String
    let name: String
    let yield: Double
    let price: Double
    let maturity: String?
}

// MARK: - Asset Search Results
struct AssetSearchResult: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let name: String
    let type: Asset.AssetType
    let currentPrice: Double
    let change24h: Double?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Price Manager
class PriceManager: ObservableObject {
    @Published var isLoading = false
    @Published var searchResults: [AssetSearchResult] = []
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // API Keys (em produção, usar configuration segura)
    private let coinMarketCapAPIKey = "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e" // Substituir pela sua chave
    private let financialDataAPIKey = "0PT9UKHEJRBJE05I" // Para ações/obrigações
    
    init() {
        // Configurar timer para atualizações automáticas a cada 5 minutos
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateAllPrices()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search Functions
    
    /// Buscar criptomoedas na CoinMarketCap
    func searchCryptos(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // URL da CoinMarketCap API v1 (versão gratuita)
        let urlString = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: query.uppercased()),
            URLQueryItem(name: "convert", value: "EUR")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue(coinMarketCapAPIKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: CoinMarketCapResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "Erro ao buscar criptomoedas: \(error.localizedDescription)"
                        print("Crypto API Error: \(error)")
                    }
                },
                receiveValue: { response in
                    self.searchResults = response.data.map { (symbol, data) in
                        AssetSearchResult(
                            symbol: symbol,
                            name: data.name,
                            type: .crypto,
                            currentPrice: data.quote.EUR.price,
                            change24h: data.quote.EUR.percent_change_24h
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Buscar ações disponíveis na Trade Republic (usando API alternativa)
    func searchStocks(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Usando Alpha Vantage como exemplo (API gratuita para ações)
        let urlString = "https://www.alphavantage.co/query"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "function", value: "SYMBOL_SEARCH"),
            URLQueryItem(name: "keywords", value: query),
            URLQueryItem(name: "apikey", value: financialDataAPIKey)
        ]
        
        guard let url = components.url else { return }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "Erro ao buscar ações: \(error.localizedDescription)"
                    }
                },
                receiveValue: { data in
                    // Processar resposta da Alpha Vantage
                    self.parseStockSearchResults(data)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Buscar obrigações portuguesas e europeias
    func searchBonds(query: String) {
        // Lista estática de obrigações comuns em Portugal/Europa
        let commonBonds = [
            ("PGB", "Obrigações do Tesouro Português 10Y", 3.2),
            ("CA", "Certificados de Aforro", 2.5),
            ("CT", "Certificados do Tesouro", 1.8),
            ("OT", "Obrigações do Tesouro", 3.0),
            ("BUND", "Bund Alemão 10Y", 2.1),
            ("OAT", "OAT França 10Y", 2.8),
            ("BTP", "BTP Itália 10Y", 4.2)
        ]
        
        let filtered = commonBonds.filter { bond in
            bond.0.localizedCaseInsensitiveContains(query) ||
            bond.1.localizedCaseInsensitiveContains(query)
        }
        
        searchResults = filtered.map { bond in
            AssetSearchResult(
                symbol: bond.0,
                name: bond.1,
                type: .interest,
                currentPrice: 1000.0, // Valor nominal
                change24h: nil
            )
        }
    }
    
    // MARK: - Price Updates
    
    /// Obter preço atual de um ativo específico
    func getCurrentPrice(for symbol: String, type: Asset.AssetType) async -> Double? {
        switch type {
        case .crypto:
            return await getCryptoPrice(symbol: symbol)
        case .stock:
            return await getStockPrice(symbol: symbol)
        case .interest:
            return await getBondPrice(symbol: symbol)
        case .bank, .savings:
            return nil // Contas bancárias não têm cotação
        }
    }
    
    private func getCryptoPrice(symbol: String) async -> Double? {
        let urlString = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: symbol.uppercased()),
            URLQueryItem(name: "convert", value: "EUR")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue(coinMarketCapAPIKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        
        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(CoinMarketCapResponse.self, from: data)
            return response.data[symbol.uppercased()]?.quote.EUR.price
        } catch {
            print("Error fetching crypto price: \(error)")
            return nil
        }
    }
    
    private func getStockPrice(symbol: String) async -> Double? {
        // Implementar com Alpha Vantage ou outra API
        let urlString = "https://www.alphavantage.co/query"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "function", value: "GLOBAL_QUOTE"),
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "apikey", value: financialDataAPIKey)
        ]
        
        guard let url = components.url else { return nil }
        
        do {
            let (data, _) = try await session.data(from: url)
            // Processar resposta da Alpha Vantage
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let quote = json["Global Quote"] as? [String: String],
               let priceString = quote["05. price"],
               let price = Double(priceString) {
                return price
            }
        } catch {
            print("Error fetching stock price: \(error)")
        }
        
        return nil
    }
    
    private func getBondPrice(symbol: String) async -> Double? {
        // Para obrigações, retornar valor nominal (1000) ou buscar cotação real
        // Em produção, integrar com APIs de mercado de capitais
        return 1000.0
    }
    
    /// Atualizar todos os preços dos ativos no portfolio
    func updateAllPrices() {
        lastUpdateTime = Date()
        // Esta função será chamada pelo PortfolioManager
    }
    
    // MARK: - Helper Functions
    
    private func parseStockSearchResults(_ data: Data) {
        // Implementar parsing dos resultados de busca de ações
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let bestMatches = json["bestMatches"] as? [[String: String]] {
                
                searchResults = bestMatches.compactMap { match in
                    guard let symbol = match["1. symbol"],
                          let name = match["2. name"] else { return nil }
                    
                    return AssetSearchResult(
                        symbol: symbol,
                        name: name,
                        type: .stock,
                        currentPrice: 0.0, // Será atualizado quando selecionado
                        change24h: nil
                    )
                }
            }
        } catch {
            print("Error parsing stock search results: \(error)")
        }
    }
    
    /// Verificar se as APIs estão configuradas
    func areAPIsConfigured() -> Bool {
        return !coinMarketCapAPIKey.isEmpty &&
               !financialDataAPIKey.isEmpty &&
               coinMarketCapAPIKey != "YOUR_CMC_API_KEY" &&
               financialDataAPIKey != "YOUR_FINANCIAL_API_KEY"
    }
    
    /// Obter lista de criptomoedas populares
    func getPopularCryptos() -> [AssetSearchResult] {
        return [
            AssetSearchResult(symbol: "BTC", name: "Bitcoin", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "ETH", name: "Ethereum", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "ADA", name: "Cardano", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "SOL", name: "Solana", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "DOT", name: "Polkadot", type: .crypto, currentPrice: 0, change24h: nil)
        ]
    }
    
    /// Obter lista de ações populares na Trade Republic
    func getPopularStocks() -> [AssetSearchResult] {
        return [
            AssetSearchResult(symbol: "AAPL", name: "Apple Inc.", type: .stock, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "TSLA", name: "Tesla Inc.", type: .stock, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "MSFT", name: "Microsoft Corp.", type: .stock, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "AMZN", name: "Amazon.com Inc.", type: .stock, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "GOOGL", name: "Alphabet Inc.", type: .stock, currentPrice: 0, change24h: nil)
        ]
    }
}
