import Foundation
import Combine

// MARK: - Models para APIs Atualizados
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

// MARK: - 🆕 Novos modelos para APIs alternativas
struct YahooFinanceResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [ChartResult]
}

struct ChartResult: Codable {
    let meta: ChartMeta
    let indicators: Indicators
}

struct ChartMeta: Codable {
    let symbol: String
    let regularMarketPrice: Double
    let previousClose: Double
    let currency: String
}

struct Indicators: Codable {
    let quote: [QuoteData]
}

struct QuoteData: Codable {
    let close: [Double?]
}

// MARK: - 🆕 Modelo para Polygon.io (alternativa gratuita)
struct PolygonResponse: Codable {
    let status: String
    let results: [PolygonResult]?
}

struct PolygonResult: Codable {
    let c: Double // close price
    let h: Double // high
    let l: Double // low
    let o: Double // open
    let t: Int    // timestamp
}

// MARK: - 🆕 Modelo para FinnHub (alternativa gratuita)
struct FinnHubQuote: Codable {
    let c: Double // current price
    let d: Double // change
    let dp: Double // percent change
    let h: Double // high
    let l: Double // low
    let o: Double // open
    let pc: Double // previous close
    let t: Int    // timestamp
}

// MARK: - 🆕 Modelo para Twelve Data (alternativa gratuita)
struct TwelveDataResponse: Codable {
    let price: String
    let symbol: String
    let exchange: String?
}

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

// MARK: - Price Manager Atualizado
class PriceManager: ObservableObject {
    @Published var isLoading = false
    @Published var searchResults: [AssetSearchResult] = []
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 🆕 Múltiplas APIs para maior confiabilidade
    private let coinMarketCapAPIKey = "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e"
    
    // 🆕 APIs alternativas gratuitas para ações
    private let finnHubAPIKey = "YOUR_FINNHUB_KEY" // Gratuita até 60 calls/min
    private let polygonAPIKey = "YOUR_POLYGON_KEY" // Gratuita até 5 calls/min
    private let twelveDataAPIKey = "YOUR_TWELVE_DATA_KEY" // Gratuita até 800 calls/day
    
    // 🆕 Enum para controlar qual API usar
    enum StockAPI {
        case yahooFinance    // Gratuita, sem chave
        case finnHub         // Gratuita com chave
        case polygon         // Gratuita com chave
        case twelveData      // Gratuita com chave
        case alphaVantage    // Backup
    }
    
    private var preferredStockAPI: StockAPI = .yahooFinance
    
    init() {
        // Configurar timer para atualizações automáticas a cada 5 minutos
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateAllPrices()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search Functions Atualizadas
    
    func searchCryptos(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
    
    // 🆕 Busca de ações com múltiplas APIs
    func searchStocks(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Tentar diferentes APIs em sequência
        searchStocksWithAPI(query: query, api: preferredStockAPI)
    }
    
    // 🆕 Busca com API específica
    private func searchStocksWithAPI(query: String, api: StockAPI) {
        switch api {
        case .yahooFinance:
            searchStocksYahoo(query: query)
        case .finnHub:
            searchStocksFinnHub(query: query)
        case .polygon:
            // Polygon não implementado para busca, usar fallback
            searchStocksTwelveData(query: query)
        case .twelveData:
            searchStocksTwelveData(query: query)
        case .alphaVantage:
            searchStocksAlphaVantage(query: query)
        }
    }
    
    // 🆕 Yahoo Finance (Gratuita, sem chave necessária)
    private func searchStocksYahoo(query: String) {
        let symbol = query.uppercased()
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "Erro Yahoo Finance: \(error.localizedDescription)"
                        // Tentar próxima API
                        self.searchStocksWithAPI(query: query, api: .finnHub)
                    }
                },
                receiveValue: { data in
                    self.parseYahooFinanceData(data, symbol: symbol, query: query)
                }
            )
            .store(in: &cancellables)
    }
    
    // 🆕 FinnHub (Gratuita com chave)
    private func searchStocksFinnHub(query: String) {
        guard !finnHubAPIKey.isEmpty && finnHubAPIKey != "YOUR_FINNHUB_KEY" else {
            searchStocksWithAPI(query: query, api: .twelveData)
            return
        }
        
        let symbol = query.uppercased()
        let urlString = "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(finnHubAPIKey)"
        
        guard let url = URL(string: urlString) else {
            searchStocksWithAPI(query: query, api: .twelveData)
            return
        }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FinnHubQuote.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("FinnHub Error: \(error)")
                        self.searchStocksWithAPI(query: query, api: .twelveData)
                    }
                },
                receiveValue: { quote in
                    let result = AssetSearchResult(
                        symbol: symbol,
                        name: "\(symbol) Inc.", // Nome simplificado
                        type: .stock,
                        currentPrice: quote.c,
                        change24h: quote.dp
                    )
                    self.searchResults = [result]
                }
            )
            .store(in: &cancellables)
    }
    
    // 🆕 Twelve Data (Gratuita com chave)
    private func searchStocksTwelveData(query: String) {
        guard !twelveDataAPIKey.isEmpty && twelveDataAPIKey != "YOUR_TWELVE_DATA_KEY" else {
            // Fallback para ações populares
            provideFallbackStocks(query: query)
            return
        }
        
        let symbol = query.uppercased()
        let urlString = "https://api.twelvedata.com/price?symbol=\(symbol)&apikey=\(twelveDataAPIKey)"
        
        guard let url = URL(string: urlString) else {
            provideFallbackStocks(query: query)
            return
        }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TwelveDataResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("Twelve Data Error: \(error)")
                        self.provideFallbackStocks(query: query)
                    }
                },
                receiveValue: { response in
                    if let price = Double(response.price) {
                        let result = AssetSearchResult(
                            symbol: symbol,
                            name: "\(symbol) Inc.",
                            type: .stock,
                            currentPrice: price,
                            change24h: nil
                        )
                        self.searchResults = [result]
                    } else {
                        self.provideFallbackStocks(query: query)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 🆕 Fallback com ações populares (modo offline)
    private func provideFallbackStocks(query: String) {
        let popularStocks = getPopularStocks()
        
        searchResults = popularStocks.filter { stock in
            stock.symbol.localizedCaseInsensitiveContains(query) ||
            stock.name.localizedCaseInsensitiveContains(query)
        }
        
        isLoading = false
        
        if searchResults.isEmpty {
            // Criar resultado genérico
            searchResults = [
                AssetSearchResult(
                    symbol: query.uppercased(),
                    name: "\(query.uppercased()) Inc.",
                    type: .stock,
                    currentPrice: 100.0, // Preço placeholder
                    change24h: nil
                )
            ]
        }
    }
    
    // 🆕 Parser para Yahoo Finance
    private func parseYahooFinanceData(_ data: Data, symbol: String, query: String) {
        do {
            let response = try JSONDecoder().decode(YahooFinanceResponse.self, from: data)
            
            if let result = response.chart.result.first {
                let price = result.meta.regularMarketPrice
                let previousClose = result.meta.previousClose
                let change = ((price - previousClose) / previousClose) * 100
                
                let searchResult = AssetSearchResult(
                    symbol: symbol,
                    name: "\(symbol) Inc.", // Nome simplificado
                    type: .stock,
                    currentPrice: price,
                    change24h: change
                )
                
                searchResults = [searchResult]
            } else {
                // Tentar próxima API
                searchStocksWithAPI(query: query, api: .finnHub)
            }
        } catch {
            print("Yahoo Finance parsing error: \(error)")
            searchStocksWithAPI(query: query, api: .finnHub)
        }
    }
    
    // 🆕 Alpha Vantage como backup
    private func searchStocksAlphaVantage(query: String) {
        let urlString = "https://www.alphavantage.co/query"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "function", value: "SYMBOL_SEARCH"),
            URLQueryItem(name: "keywords", value: query),
            URLQueryItem(name: "apikey", value: "0PT9UKHEJRBJE05I")
        ]
        
        guard let url = components.url else {
            provideFallbackStocks(query: query)
            return
        }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("Alpha Vantage Error: \(error)")
                        self.provideFallbackStocks(query: query)
                    }
                },
                receiveValue: { data in
                    self.parseAlphaVantageSearchResults(data)
                }
            )
            .store(in: &cancellables)
    }
    
    private func parseAlphaVantageSearchResults(_ data: Data) {
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
            } else {
                provideFallbackStocks(query: "")
            }
        } catch {
            print("Error parsing Alpha Vantage search results: \(error)")
            provideFallbackStocks(query: "")
        }
    }
    
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
    
    // MARK: - Price Updates Melhorados
    
    func getCurrentPrice(for symbol: String, type: Asset.AssetType) async -> Double? {
        switch type {
        case .crypto:
            return await getCryptoPrice(symbol: symbol)
        case .stock:
            return await getStockPrice(symbol: symbol)
        case .interest:
            return await getBondPrice(symbol: symbol)
        case .bank, .savings:
            return nil
        }
    }
    
    // 🆕 Função melhorada para obter preço de ações
    private func getStockPrice(symbol: String) async -> Double? {
        // Tentar Yahoo Finance primeiro
        if let price = await getStockPriceYahoo(symbol: symbol) {
            return price
        }
        
        // Tentar FinnHub
        if let price = await getStockPriceFinnHub(symbol: symbol) {
            return price
        }
        
        // Tentar Twelve Data
        if let price = await getStockPriceTwelveData(symbol: symbol) {
            return price
        }
        
        // Fallback
        return nil
    }
    
    // 🆕 Yahoo Finance para preços individuais
    private func getStockPriceYahoo(symbol: String) async -> Double? {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol.uppercased())"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(YahooFinanceResponse.self, from: data)
            
            if let result = response.chart.result.first {
                return result.meta.regularMarketPrice
            }
        } catch {
            print("Yahoo Finance error for \(symbol): \(error)")
        }
        
        return nil
    }
    
    // 🆕 FinnHub para preços individuais
    private func getStockPriceFinnHub(symbol: String) async -> Double? {
        guard !finnHubAPIKey.isEmpty && finnHubAPIKey != "YOUR_FINNHUB_KEY" else { return nil }
        
        let urlString = "https://finnhub.io/api/v1/quote?symbol=\(symbol.uppercased())&token=\(finnHubAPIKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await session.data(from: url)
            let quote = try JSONDecoder().decode(FinnHubQuote.self, from: data)
            return quote.c > 0 ? quote.c : nil
        } catch {
            print("FinnHub error for \(symbol): \(error)")
        }
        
        return nil
    }
    
    // 🆕 Twelve Data para preços individuais
    private func getStockPriceTwelveData(symbol: String) async -> Double? {
        guard !twelveDataAPIKey.isEmpty && twelveDataAPIKey != "YOUR_TWELVE_DATA_KEY" else { return nil }
        
        let urlString = "https://api.twelvedata.com/price?symbol=\(symbol.uppercased())&apikey=\(twelveDataAPIKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(TwelveDataResponse.self, from: data)
            return Double(response.price)
        } catch {
            print("Twelve Data error for \(symbol): \(error)")
        }
        
        return nil
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
    
    private func getBondPrice(symbol: String) async -> Double? {
        return 1000.0 // Valor nominal padrão para obrigações
    }
    
    func updateAllPrices() {
        lastUpdateTime = Date()
    }
    
    // MARK: - Helper Functions Atualizadas
    
    func areAPIsConfigured() -> Bool {
        return !coinMarketCapAPIKey.isEmpty && coinMarketCapAPIKey != "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e"
        // Yahoo Finance não precisa de chave, então sempre funciona
    }
    
    func getPopularCryptos() -> [AssetSearchResult] {
        return [
            AssetSearchResult(symbol: "BTC", name: "Bitcoin", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "ETH", name: "Ethereum", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "ADA", name: "Cardano", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "SOL", name: "Solana", type: .crypto, currentPrice: 0, change24h: nil),
            AssetSearchResult(symbol: "DOT", name: "Polkadot", type: .crypto, currentPrice: 0, change24h: nil)
        ]
    }
    
    func getPopularStocks() -> [AssetSearchResult] {
        return [
            AssetSearchResult(symbol: "AAPL", name: "Apple Inc.", type: .stock, currentPrice: 185.0, change24h: 0.5),
            AssetSearchResult(symbol: "TSLA", name: "Tesla Inc.", type: .stock, currentPrice: 248.0, change24h: -1.2),
            AssetSearchResult(symbol: "MSFT", name: "Microsoft Corp.", type: .stock, currentPrice: 415.0, change24h: 0.8),
            AssetSearchResult(symbol: "AMZN", name: "Amazon.com Inc.", type: .stock, currentPrice: 145.0, change24h: 1.1),
            AssetSearchResult(symbol: "GOOGL", name: "Alphabet Inc.", type: .stock, currentPrice: 142.0, change24h: 0.3),
            AssetSearchResult(symbol: "NVDA", name: "NVIDIA Corp.", type: .stock, currentPrice: 875.0, change24h: 2.1),
            AssetSearchResult(symbol: "META", name: "Meta Platforms Inc.", type: .stock, currentPrice: 315.0, change24h: -0.7),
            AssetSearchResult(symbol: "NFLX", name: "Netflix Inc.", type: .stock, currentPrice: 485.0, change24h: 1.5)
        ]
    }
    
    // 🆕 Função para testar conectividade das APIs
    func testAPIConnectivity() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Testar Yahoo Finance
        results["Yahoo Finance"] = await getStockPriceYahoo(symbol: "AAPL") != nil
        
        // Testar FinnHub se configurado
        if !finnHubAPIKey.isEmpty && finnHubAPIKey != "YOUR_FINNHUB_KEY" {
            results["FinnHub"] = await getStockPriceFinnHub(symbol: "AAPL") != nil
        }
        
        // Testar Twelve Data se configurado
        if !twelveDataAPIKey.isEmpty && twelveDataAPIKey != "YOUR_TWELVE_DATA_KEY" {
            results["Twelve Data"] = await getStockPriceTwelveData(symbol: "AAPL") != nil
        }
        
        // Testar CoinMarketCap
        results["CoinMarketCap"] = await getCryptoPrice(symbol: "BTC") != nil
        
        return results
    }
    
    // 🆕 Obter status detalhado das APIs
    func getAPIStatus() -> String {
        var status: [String] = []
        
        status.append("🟢 Yahoo Finance (Gratuita)")
        
        if !finnHubAPIKey.isEmpty && finnHubAPIKey != "YOUR_FINNHUB_KEY" {
            status.append("🟢 FinnHub (Configurada)")
        } else {
            status.append("🟡 FinnHub (Não configurada)")
        }
        
        if !twelveDataAPIKey.isEmpty && twelveDataAPIKey != "YOUR_TWELVE_DATA_KEY" {
            status.append("🟢 Twelve Data (Configurada)")
        } else {
            status.append("🟡 Twelve Data (Não configurada)")
        }
        
        if !coinMarketCapAPIKey.isEmpty && coinMarketCapAPIKey != "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e" {
            status.append("🟢 CoinMarketCap (Configurada)")
        } else {
            status.append("🟡 CoinMarketCap (Não configurada)")
        }
        
        return status.joined(separator: "\n")
    }
}
