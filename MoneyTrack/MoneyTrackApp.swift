import SwiftUI

@main
struct MoneyTrackApp: App {
    @StateObject private var portfolioManager = PortfolioManager()
    @StateObject private var financeManager = FinanceManager()
    @StateObject private var themeManager = ThemeManager() // 🆕 Novo
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(portfolioManager)
                .environmentObject(financeManager)
                .environmentObject(themeManager) // 🆕 Novo
                .preferredColorScheme(themeManager.getColorScheme()) // 🆕 Aplicar tema
                .onAppear {
                    // Conectar os managers
                    portfolioManager.setFinanceManager(financeManager)
                    
                    portfolioManager.loadData()
                    financeManager.loadData()
                }
        }
    }
}
