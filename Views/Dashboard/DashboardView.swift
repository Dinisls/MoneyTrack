import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var currencyManager: CurrencyManager // 🆕 Novo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 🆕 NOVA SEÇÃO: Seletor de Moeda e Taxa de Câmbio
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Moeda de Visualização")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            CurrencyToggleView(style: .pill)
                        }
                        
                        Spacer()
                        
                        if currencyManager.selectedCurrency == .USD {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Taxa EUR/USD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Text(currencyManager.getExchangeRateString())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    if currencyManager.isLoadingRates {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Resumo Geral - 🆕 Atualizado com suporte multi-moeda
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Patrimônio Total".uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(currencyManager.selectedCurrency.flag)
                                .font(.title3)
                        }
                        
                        DualPriceView(
                            eurAmount: portfolioManager.portfolio.totalValue,
                            showBothPrices: true,
                            alignment: .leading
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // ✅ ATUALIZADA: Cards de resumo com receitas corretas
                    HStack(spacing: 15) {
                        MultiCurrencySummaryCard(
                            title: "Receitas Totais",
                            eurAmount: financeManager.financeData.totalMonthlyIncome,
                            color: .green,
                            showBothPrices: false
                        )
                        
                        MultiCurrencySummaryCard(
                            title: "Despesas Reais",
                            eurAmount: financeManager.financeData.monthlyExpenses,
                            color: .red,
                            showBothPrices: false
                        )
                    }
                    
                    HStack(spacing: 15) {
                        MultiCurrencySummaryCard(
                            title: "Investimentos",
                            eurAmount: financeManager.financeData.monthlyInvestments,
                            color: .purple,
                            showBothPrices: false
                        )
                        
                        MultiCurrencySummaryCard(
                            title: "Depósitos",
                            eurAmount: financeManager.financeData.monthlyDeposits,
                            color: .blue,
                            showBothPrices: false
                        )
                    }
                    
                    // ✅ NOVA: Card de balanço final
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Balanço do Mês")
                                .font(.headline)
                            
                            Spacer()
                            
                            let balance = financeManager.financeData.finalBalance
                            Image(systemName: balance >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(balance >= 0 ? .green : .red)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Receitas - Despesas - Investimentos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                let balance = financeManager.financeData.finalBalance
                                DualPriceView(
                                    eurAmount: abs(balance),
                                    showBothPrices: false,
                                    alignment: .leading
                                )
                                .foregroundColor(balance >= 0 ? .green : .red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(financeManager.financeData.finalBalance >= 0 ? "Saldo Positivo" : "Déficit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                let percentage = financeManager.financeData.totalMonthlyIncome > 0 ?
                                    (financeManager.financeData.finalBalance / financeManager.financeData.totalMonthlyIncome) * 100 : 0
                                
                                Text("\(abs(percentage), specifier: "%.1f")%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(financeManager.financeData.finalBalance >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // ✅ NOVA: Breakdown detalhado das receitas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breakdown de Receitas")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            BreakdownRow(
                                title: "Salário/Trabalho",
                                amount: financeManager.financeData.monthlyIncome - financeManager.financeData.monthlyDeposits,
                                color: .green,
                                icon: "briefcase.fill"
                            )
                            
                            BreakdownRow(
                                title: "Depósitos Bancários",
                                amount: financeManager.financeData.monthlyDeposits,
                                color: .blue,
                                icon: "building.columns.fill"
                            )
                            
                            BreakdownRow(
                                title: "Juros Recebidos",
                                amount: portfolioManager.getMonthlyInterestEarned(),
                                color: .mint,
                                icon: "percent"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Distribuição de Patrimônio
                    DistributionChartView()
                    
                    // Performance do Portfolio - 🆕 Atualizado
                    if portfolioManager.portfolio.totalValue > 0 {
                        MultiCurrencyPerformanceCard(
                            title: "Performance do Portfolio",
                            totalValue: portfolioManager.portfolio.totalValue,
                            profitLoss: portfolioManager.portfolio.totalProfitLoss,
                            percentage: portfolioManager.portfolio.totalProfitLossPercentage
                        )
                    }
                    
                    // Preview de Juros
                    InterestPreviewCard()
                    
                    // Transações Recentes
                    RecentTransactionsView()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 🆕 Seletor compacto de moeda
                    CurrencyToggleView(style: .compact)
                    
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

// MARK: - 🆕 Multi-Currency Summary Card
struct MultiCurrencySummaryCard: View {
    let title: String
    let eurAmount: Double
    let color: Color
    let showBothPrices: Bool
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(currencyManager.selectedCurrency.flag)
                    .font(.caption)
            }
            
            DualPriceView(
                eurAmount: eurAmount,
                showBothPrices: showBothPrices,
                alignment: .leading
            )
            .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            // Mostrar detalhes ou alternar moeda
            let newCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
            currencyManager.setCurrency(newCurrency)
        }
    }
}

// MARK: - 🆕 Multi-Currency Performance Card
struct MultiCurrencyPerformanceCard: View {
    let title: String
    let totalValue: Double
    let profitLoss: Double
    let percentage: Double
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                CurrencyToggleView(style: .compact)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Valor Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DualPriceView(
                        eurAmount: totalValue,
                        showBothPrices: true,
                        alignment: .leading
                    )
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Lucro/Prejuízo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: profitLoss >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text(abs(profitLoss).toCurrency(using: currencyManager))
                                .fontWeight(.medium)
                            Text("(\(percentage.toPercentage()))")
                                .font(.caption)
                        }
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                        
                        // Valor na moeda secundária
                        let secondaryCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
                        Text(abs(profitLoss).toCurrency(in: secondaryCurrency, using: currencyManager))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - ✅ NOVA: Breakdown Row Component
struct BreakdownRow: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
            }
            
            Spacer()
            
            Text(amount.toCurrency(using: currencyManager))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(amount > 0 ? color : .secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(PortfolioManager())
        .environmentObject(FinanceManager())
        .environmentObject(ThemeManager())
        .environmentObject(CurrencyManager())
}
