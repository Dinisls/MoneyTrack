//
//  PerformanceCardView.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct PerformanceCardView: View {
    let title: String
    let value: Double
    let profitLoss: Double
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Valor Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value.toCurrency())
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Lucro/Prejuízo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: profitLoss >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(abs(profitLoss).toCurrency())
                            .fontWeight(.medium)
                        Text("(\(percentage.toPercentage()))")
                            .font(.caption)
                    }
                    .foregroundColor(profitLoss >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
