//
//  AssetRowView.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct AssetRowView: View {
    let asset: Asset
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(asset.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(asset.quantity, specifier: "%.4f") unidades")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(asset.totalValue.toCurrency())
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: asset.profitLoss >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text(abs(asset.profitLoss).toCurrency())
                    Text("(\(asset.profitLossPercentage.toPercentage()))")
                        .font(.caption)
                }
                .foregroundColor(asset.profitLoss >= 0 ? .green : .red)
                
                Text("Preço: \(asset.currentPrice.toCurrency())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}