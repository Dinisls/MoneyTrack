import SwiftUI

extension Color {
    // 🆕 Cores adaptativas para modo escuro
    static let cardBackground = Color(.systemGray6)
    static let cardBackgroundSecondary = Color(.systemGray5)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // 🆕 Cores específicas do MoneyTrack
    static let moneyGreen = Color("MoneyGreen") // Definir em Assets
    static let moneyRed = Color("MoneyRed")     // Definir em Assets
    static let moneyBlue = Color("MoneyBlue")   // Definir em Assets
    
    // 🆕 Fallback se cores customizadas não existirem
    static let incomeColor = Color.green
    static let expenseColor = Color.red
    static let investmentColor = Color.purple
    static let interestColor = Color.mint
}
