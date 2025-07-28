import SwiftUI

@main
struct MoneyTrackApp: App {
    @StateObject private var portfolioManager = PortfolioManager()
    @StateObject private var financeManager = FinanceManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var currencyManager = CurrencyManager() // 🆕 Novo
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(portfolioManager)
                .environmentObject(financeManager)
                .environmentObject(themeManager)
                .environmentObject(currencyManager) // 🆕 Novo
                .preferredColorScheme(themeManager.getColorScheme())
                .onAppear {
                    // Conectar os managers
                    portfolioManager.setFinanceManager(financeManager)
                    
                    portfolioManager.loadData()
                    financeManager.loadData()
                    
                    // 🆕 Inicializar taxas de câmbio
                    currencyManager.updateExchangeRates()
                }
        }
    }
}
