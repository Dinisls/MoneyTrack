import Foundation

// MARK: - 🆕 Configuração centralizada de APIs
struct APIConfiguration {
    
    // MARK: - Configurações de API
    
    /// CoinMarketCap - Para criptomoedas
    /// Gratuita até 10,000 calls/mês
    /// Registar em: https://coinmarketcap.com/api/
    static let coinMarketCapAPIKey = "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e"
    
    /// Yahoo Finance - Para ações (GRATUITA SEM CHAVE)
    /// Sem limite, mas pode ter rate limiting
    /// Não precisa de registo
    static let useYahooFinance = true
    
    /// FinnHub - Para ações (RECOMENDADA)
    /// Gratuita até 60 calls/min
    /// Registar em: https://finnhub.io/register
    static let finnHubAPIKey = "YOUR_FINNHUB_KEY"
    
    /// Twelve Data - Para ações
    /// Gratuita até 800 calls/dia
    /// Registar em: https://twelvedata.com/pricing
    static let twelveDataAPIKey = "YOUR_TWELVE_DATA_KEY"
    
    /// Polygon.io - Para ações
    /// Gratuita até 5 calls/min
    /// Registar em: https://polygon.io/pricing
    static let polygonAPIKey = "YOUR_POLYGON_KEY"
    
    /// Alpha Vantage - Backup para ações
    /// Gratuita até 25 calls/dia
    /// Registar em: https://www.alphavantage.co/support/#api-key
    static let alphaVantageAPIKey = "0PT9UKHEJRBJE05I"
    
    // MARK: - URLs das APIs
    
    static let coinMarketCapBaseURL = "https://pro-api.coinmarketcap.com/v1"
    static let yahooFinanceBaseURL = "https://query1.finance.yahoo.com"
    static let finnHubBaseURL = "https://finnhub.io/api/v1"
    static let twelveDataBaseURL = "https://api.twelvedata.com"
    static let polygonBaseURL = "https://api.polygon.io"
    static let alphaVantageBaseURL = "https://www.alphavantage.co/query"
    
    // MARK: - Validação de chaves
    
    static func isCoinMarketCapConfigured() -> Bool {
        return !coinMarketCapAPIKey.isEmpty && 
               coinMarketCapAPIKey != "YOUR_CMC_API_KEY" &&
               coinMarketCapAPIKey != "fa71be35-bf96-4c28-a2e2-d1e6d3756b6e"
    }
    
    static func isFinnHubConfigured() -> Bool {
        return !finnHubAPIKey.isEmpty && finnHubAPIKey != "YOUR_FINNHUB_KEY"
    }
    
    static func isTwelveDataConfigured() -> Bool {
        return !twelveDataAPIKey.isEmpty && twelveDataAPIKey != "YOUR_TWELVE_DATA_KEY"
    }
    
    static func isPolygonConfigured() -> Bool {
        return !polygonAPIKey.isEmpty && polygonAPIKey != "YOUR_POLYGON_KEY"
    }
    
    static func isAlphaVantageConfigured() -> Bool {
        return !alphaVantageAPIKey.isEmpty && alphaVantageAPIKey != "YOUR_ALPHA_VANTAGE_KEY"
    }
    
    // MARK: - Obter APIs disponíveis
    
    static func getAvailableStockAPIs() -> [String] {
        var apis: [String] = []
        
        // Yahoo Finance sempre disponível
        apis.append("Yahoo Finance (Gratuita)")
        
        if isFinnHubConfigured() {
            apis.append("FinnHub (60 calls/min)")
        }
        
        if isTwelveDataConfigured() {
            apis.append("Twelve Data (800 calls/dia)")
        }
        
        if isPolygonConfigured() {
            apis.append("Polygon.io (5 calls/min)")
        }
        
        if isAlphaVantageConfigured() {
            apis.append("Alpha Vantage (25 calls/dia)")
        }
        
        return apis
    }
    
    static func getAPIRecommendations() -> [String] {
        return [
            "🥇 Yahoo Finance: Gratuita, sem chave necessária, boa cobertura",
            "🥈 FinnHub: Gratuita, 60 calls/min, dados em tempo real",
            "🥉 Twelve Data: Gratuita, 800 calls/dia, boa qualidade",
            "📊 CoinMarketCap: Para criptomoedas, 10k calls/mês",
            "⚠️ Alpha Vantage: Apenas 25 calls/dia, usar como backup"
        ]
    }
    
    // MARK: - Instruções de configuração
    
    static func getSetupInstructions() -> [String: String] {
        return [
            "FinnHub": """
                1. Acesse https://finnhub.io/register
                2. Crie uma conta gratuita
                3. Copie a API key do dashboard
                4. Cole em APIConfiguration.swift
                5. Limite: 60 chamadas por minuto
                """,
            
            "Twelve Data": """
                1. Acesse https://twelvedata.com/pricing
                2. Escolha o plano gratuito
                3. Confirme o email e faça login
                4. Vá para API → API Key
                5. Copie a chave e cole no código
                6. Limite: 800 chamadas por dia
                """,
            
            "CoinMarketCap": """
                1. Acesse https://coinmarketcap.com/api/
                2. Clique em "Get Your API Key Now"
                3. Crie conta e confirme email
                4. Acesse o dashboard para ver a chave
                5. Limite: 10,000 chamadas por mês
                """,
                
            "Polygon.io": """
                1. Acesse https://polygon.io/pricing
                2. Escolha o plano "Basic (Free)"
                3. Crie conta e confirme email
                4. Vá para Dashboard → API Keys
                5. Limite: 5 chamadas por minuto
                """
        ]
    }
    
    // MARK: - Limites de rate limiting
    
    static func getRateLimits() -> [String: String] {
        return [
            "Yahoo Finance": "~2000 calls/hora (não oficial)",
            "FinnHub": "60 calls/minuto",
            "Twelve Data": "800 calls/dia",
            "Polygon.io": "5 calls/minuto",
            "Alpha Vantage": "25 calls/dia",
            "CoinMarketCap": "10,000 calls/mês"
        ]
    }
    
    // MARK: - Status das APIs
    
    static func getConfigurationStatus() -> [String: ConfigurationStatus] {
        return [
            "Yahoo Finance": .available,
            "FinnHub": isFinnHubConfigured() ? .configured : .needsSetup,
            "Twelve Data": isTwelveDataConfigured() ? .configured : .needsSetup,
            "Polygon.io": isPolygonConfigured() ? .configured : .needsSetup,
            "Alpha Vantage": isAlphaVantageConfigured() ? .configured : .needsSetup,
            "CoinMarketCap": isCoinMarketCapConfigured() ? .configured : .needsSetup
        ]
    }
    
    enum ConfigurationStatus {
        case available      // Disponível sem configuração
        case configured     // Configurada e pronta
        case needsSetup     // Precisa de configuração
        case error          // Erro na configuração
        
        var emoji: String {
            switch self {
            case .available: return "🟢"
            case .configured: return "✅"
            case .needsSetup: return "🟡"
            case .error: return "🔴"
            }
        }
        
        var description: String {
            switch self {
            case .available: return "Disponível"
            case .configured: return "Configurada"
            case .needsSetup: return "Configuração necessária"
            case .error: return "Erro"
            }
        }
    }
    
    // MARK: - Teste de conectividade
    
    static func getTestURLs() -> [String: String] {
        return [
            "Yahoo Finance": "\(yahooFinanceBaseURL)/v8/finance/chart/AAPL",
            "FinnHub": "\(finnHubBaseURL)/quote?symbol=AAPL&token=\(finnHubAPIKey)",
            "Twelve Data": "\(twelveDataBaseURL)/price?symbol=AAPL&apikey=\(twelveDataAPIKey)",
            "CoinMarketCap": "\(coinMarketCapBaseURL)/cryptocurrency/quotes/latest?symbol=BTC&convert=EUR"
        ]
    }
}
