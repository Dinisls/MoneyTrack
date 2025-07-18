import SwiftUI

struct DistributionChartView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribuição de Patrimônio")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ChartSegmentView(
                        title: "Banco",
                        value: portfolioManager.getBankBalance(),
                        color: .blue,
                        icon: "building.columns"
                    )
                    
                    ChartSegmentView(
                        title: "Mealheiro",
                        value: portfolioManager.getSavingsBalance(),
                        color: .green,
                        icon: "dollarsign.circle"
                    )
                    
                    ChartSegmentView(
                        title: "Criptomoedas",
                        value: portfolioManager.getCryptoBalance(),
                        color: .orange,
                        icon: "bitcoinsign.circle"
                    )
                    
                    ChartSegmentView(
                        title: "Ações",
                        value: portfolioManager.getStockBalance(),
                        color: .purple,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    ChartSegmentView(
                        title: "Dinheiro em Juros",
                        value: portfolioManager.getInterestBalance(),
                        color: .cyan,
                        icon: "percent"
                    )
                }
                .padding(.horizontal)
            }
            
            // ✅ CORRIGIDO: PercentageBreakdownView definida no mesmo arquivo
            if portfolioManager.portfolio.totalValue > 0 {
                PercentageBreakdownView()
            }
        }
        .padding(.vertical)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    private var cardBackgroundColor: Color {
        Color(.systemGray6)
    }
}

// ✅ ADICIONADO: ChartSegmentView no mesmo arquivo
struct ChartSegmentView: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value.toCurrency())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(minWidth: 90)
    }
}

// ✅ ADICIONADO: PercentageBreakdownView que estava em falta
struct PercentageBreakdownView: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distribuição (%)")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                PercentageRowView(
                    title: "Banco",
                    percentage: portfolioManager.getBankBalance() / portfolioManager.portfolio.totalValue * 100,
                    color: .blue
                )
                
                PercentageRowView(
                    title: "Mealheiro",
                    percentage: portfolioManager.getSavingsBalance() / portfolioManager.portfolio.totalValue * 100,
                    color: .green
                )
                
                PercentageRowView(
                    title: "Criptomoedas",
                    percentage: portfolioManager.getCryptoBalance() / portfolioManager.portfolio.totalValue * 100,
                    color: .orange
                )
                
                PercentageRowView(
                    title: "Ações",
                    percentage: portfolioManager.getStockBalance() / portfolioManager.portfolio.totalValue * 100,
                    color: .purple
                )
                
                PercentageRowView(
                    title: "Dinheiro em Juros",
                    percentage: portfolioManager.getInterestBalance() / portfolioManager.portfolio.totalValue * 100,
                    color: .cyan
                )
            }
            .padding(.horizontal)
        }
    }
}

// ✅ ADICIONADO: PercentageRowView que também estava em falta
struct PercentageRowView: View {
    let title: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(percentage, specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// ✅ Preview para testar
#Preview {
    DistributionChartView()
        .environmentObject(PortfolioManager())
        .padding()
}
