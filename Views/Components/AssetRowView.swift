import SwiftUI

struct AssetRowView: View {
    let asset: Asset
    @EnvironmentObject var currencyManager: CurrencyManager // 🆕 Novo
    @State private var showBothPrices = false // 🆕 Controlo para mostrar ambas as moedas
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(asset.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // 🆕 Indicador de moeda para ações/crypto
                    if asset.type == .crypto || asset.type == .stock {
                        Text(currencyManager.selectedCurrency.flag)
                            .font(.caption)
                    }
                }
                
                Text(asset.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(asset.quantity.toQuantityString()) unidades")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Indicador de taxa de juros para investimentos
                if asset.type == .interest, let rate = asset.annualInterestRate {
                    Text("\(rate.toPercentageString())% ao ano")
                        .font(.caption)
                        .foregroundColor(.mint)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 🆕 NOVO: Valor total com suporte multi-moeda
                DualPriceView(
                    eurAmount: asset.totalValue,
                    showBothPrices: showBothPrices,
                    alignment: .trailing
                )
                
                // 🆕 Lucro/Prejuízo com suporte multi-moeda
                HStack(spacing: 4) {
                    Image(systemName: asset.profitLoss >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(abs(asset.profitLoss).toCurrency(using: currencyManager))
                            .font(.caption)
                        
                        if showBothPrices {
                            let secondaryCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
                            Text(abs(asset.profitLoss).toCurrency(in: secondaryCurrency, using: currencyManager))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("(\(asset.profitLossPercentage.toPercentage()))")
                        .font(.caption)
                }
                .foregroundColor(asset.profitLoss >= 0 ? .green : .red)
                
                // 🆕 Preço unitário com suporte multi-moeda
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Preço: \(asset.currentPrice.toCurrency(using: currencyManager))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showBothPrices {
                        let secondaryCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
                        Text(asset.currentPrice.toCurrency(in: secondaryCurrency, using: currencyManager))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            // 🆕 Menu de contexto para opções de visualização
            Button(action: {
                showBothPrices.toggle()
            }) {
                Label(
                    showBothPrices ? "Ocultar Preços Duplos" : "Mostrar Preços Duplos",
                    systemImage: showBothPrices ? "eye.slash" : "eye"
                )
            }
            
            Divider()
            
            Button(action: {
                currencyManager.setCurrency(.EUR)
            }) {
                Label("Mostrar em Euros", systemImage: "eurosign.circle")
            }
            
            Button(action: {
                currencyManager.setCurrency(.USD)
            }) {
                Label("Mostrar em Dólares", systemImage: "dollarsign.circle")
            }
        }
    }
}

#Preview {
    let sampleAsset = Asset(
        symbol: "AAPL",
        name: "Apple Inc.",
        type: .stock,
        quantity: 10,
        averagePrice: 150,
        currentPrice: 155,
        lastUpdated: Date(),
        annualInterestRate: nil,
        lastInterestPayment: nil
    )
    
    return AssetRowView(asset: sampleAsset)
        .environmentObject(CurrencyManager())
        .padding()
}
