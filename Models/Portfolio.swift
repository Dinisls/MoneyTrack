//
//  Portfolio.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import Foundation

struct Portfolio: Codable {
    var assets: [Asset] = []
    
    var totalValue: Double {
        assets.reduce(0) { $0 + $1.totalValue }
    }
    
    var totalCost: Double {
        assets.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalProfitLoss: Double {
        totalValue - totalCost
    }
    
    var totalProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return ((totalValue - totalCost) / totalCost) * 100
    }
}