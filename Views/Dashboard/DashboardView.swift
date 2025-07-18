import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Resumo Geral
                    SummaryCardView(
                        title: "Patrimônio Total",
                        value: portfolioManager.portfolio.totalValue,
                        color: .blue
                    )
                    
                    HStack(spacing: 15) {
                        SummaryCardView(
                            title: "Receita Mensal",
                            value: financeManager.financeData.monthlyIncome,
                            color: .green
                        )
                        
                        SummaryCardView(
                            title: "Despesa Total",
                            value: financeManager.totalMonthlyExpenses,
                            color: .red
                        )
                    }
                    
                    HStack(spacing: 15) {
                        SummaryCardView(
                            title: "Investimentos Este Mês",
                            value: financeManager.getInvestmentExpenses(),
                            color: .purple
                        )
                        
                        SummaryCardView(
                            title: "Juros Recebidos",
                            value: portfolioManager.getMonthlyInterestEarned(),
                            color: .mint
                        )
                    }
                    
                    // Distribuição de Patrimônio
                    DistributionChartView()
                    
                    // Performance do Portfolio
                    if portfolioManager.portfolio.totalValue > 0 {
                        PerformanceCardView(
                            title: "Portfolio",
                            value: portfolioManager.portfolio.totalValue,
                            profitLoss: portfolioManager.portfolio.totalProfitLoss,
                            percentage: portfolioManager.portfolio.totalProfitLossPercentage
                        )
                    }
                    
                    // ✅ USA InterestPreviewCard do arquivo separado
                    InterestPreviewCard()
                    
                    // Transações Recentes
                    RecentTransactionsView()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Botão para forçar pagamento de juros
                    Button("💰") {
                        portfolioManager.forceInterestPayment()
                    }
                    .help("Forçar pagamento de juros")
                    
                    // Botão de toggle rápido do tema
                    Button(action: {
                        if themeManager.followSystemTheme {
                            themeManager.setFollowSystemTheme(false)
                            themeManager.setDarkMode(!themeManager.isDarkMode)
                        } else {
                            themeManager.toggleDarkMode()
                        }
                    }) {
                        Image(systemName: themeIconName)
                            .foregroundColor(.primary)
                    }
                    .help("Alternar tema")
                }
            }
        }
    }
    
    private var themeIconName: String {
        if themeManager.followSystemTheme {
            return "iphone"
        } else {
            return themeManager.isDarkMode ? "sun.max" : "moon"
        }
    }
}

// ❌ REMOVER: Não declarar InterestPreviewCard aqui se existe arquivo separado

#Preview {
    DashboardView()
        .environmentObject(PortfolioManager())
        .environmentObject(FinanceManager())
        .environmentObject(ThemeManager())
}
