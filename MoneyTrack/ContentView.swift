import SwiftUI

struct ContentView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    @EnvironmentObject var financeManager: FinanceManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            PortfolioView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Portfolio")
                }
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Transações")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configurações")
                }
        }
        .accentColor(.blue)
    }
}
