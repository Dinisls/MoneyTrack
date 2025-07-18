import SwiftUI

struct InterestPreviewCard: View {
    @EnvironmentObject var portfolioManager: PortfolioManager
    
    var interestAssets: [Asset] {
        portfolioManager.portfolio.assets.filter { 
            $0.type == .interest && $0.annualInterestRate != nil 
        }
    }
    
    var body: some View {
        if !interestAssets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(.mint)
                    Text("Próximos Pagamentos de Juros")
                        .font(.headline)
                }
                
                ForEach(interestAssets) { asset in
                    InterestAssetRowView(asset: asset)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct InterestAssetRowView: View {
    let asset: Asset
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text("\((asset.annualInterestRate ?? 0).toPercentageString())% ao ano")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)
                    
                    Text("Valor: \(asset.totalValue.toCurrency())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(asset.calculateMonthlyInterest().toCurrency())
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Text("próximo mês")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InterestPreviewCard()
        .environmentObject(PortfolioManager())
        .padding()
}
