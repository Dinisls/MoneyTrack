import SwiftUI

struct SummaryCardView: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value.toCurrency())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackgroundColor) // 🆕 Cor adaptativa
        .cornerRadius(12)
    }
    
    // 🆕 Cor de fundo adaptativa para modo escuro
    private var cardBackgroundColor: Color {
        Color(.systemGray6)
    }
}

#Preview {
    HStack {
        SummaryCardView(title: "Teste Claro", value: 1234.56, color: .blue)
        SummaryCardView(title: "Teste Escuro", value: 9876.54, color: .green)
    }
    .padding()
    .preferredColorScheme(.dark)
}
