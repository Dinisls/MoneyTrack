import SwiftUI

struct CurrencyToggleView: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    let style: ToggleStyle
    
    enum ToggleStyle {
        case button        // Botão simples
        case segmented     // Controlo segmentado
        case compact       // Versão compacta
        case pill          // Formato pill
        case dropdown      // Menu dropdown
    }
    
    var body: some View {
        switch style {
        case .button:
            ButtonStyle()
        case .segmented:
            SegmentedStyle()
        case .compact:
            CompactStyle()
        case .pill:
            PillStyle()
        case .dropdown:
            DropdownStyle()
        }
    }
}

// MARK: - Button Style
private extension CurrencyToggleView {
    func ButtonStyle() -> some View {
        Button(action: toggleCurrency) {
            HStack(spacing: 4) {
                Text(currencyManager.selectedCurrency.flag)
                Text(currencyManager.selectedCurrency.rawValue)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

// MARK: - Segmented Style
private extension CurrencyToggleView {
    func SegmentedStyle() -> some View {
        Picker("Moeda", selection: $currencyManager.selectedCurrency) {
            ForEach(Currency.allCases, id: \.self) { currency in
                HStack {
                    Text(currency.flag)
                    Text(currency.rawValue)
                }
                .tag(currency)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - Compact Style
private extension CurrencyToggleView {
    func CompactStyle() -> some View {
        Button(action: toggleCurrency) {
            HStack(spacing: 2) {
                Text(currencyManager.selectedCurrency.flag)
                    .font(.caption)
                Text(currencyManager.selectedCurrency.symbol)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(.systemGray5))
            .cornerRadius(4)
        }
    }
}

// MARK: - Pill Style
private extension CurrencyToggleView {
    func PillStyle() -> some View {
        HStack(spacing: 0) {
            ForEach(Currency.allCases, id: \.self) { currency in
                Button(action: {
                    currencyManager.setCurrency(currency)
                }) {
                    HStack(spacing: 4) {
                        Text(currency.flag)
                            .font(.caption)
                        Text(currency.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        currencyManager.selectedCurrency == currency
                        ? Color.blue
                        : Color.clear
                    )
                    .foregroundColor(
                        currencyManager.selectedCurrency == currency
                        ? .white
                        : .primary
                    )
                }
            }
        }
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Dropdown Style
private extension CurrencyToggleView {
    func DropdownStyle() -> some View {
        Menu {
            ForEach(Currency.allCases, id: \.self) { currency in
                Button(action: {
                    currencyManager.setCurrency(currency)
                }) {
                    HStack {
                        Text(currency.flag)
                        Text(currency.name)
                        Spacer()
                        if currencyManager.selectedCurrency == currency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Divider()
            
            Section("Taxa de Câmbio") {
                HStack {
                    Text(currencyManager.getExchangeRateString())
                    Spacer()
                    if currencyManager.isLoadingRates {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button("🔄") {
                            currencyManager.updateExchangeRates()
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currencyManager.selectedCurrency.flag)
                Text(currencyManager.selectedCurrency.rawValue)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }
}

// MARK: - Helper Functions
private extension CurrencyToggleView {
    func toggleCurrency() {
        let newCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
        currencyManager.setCurrency(newCurrency)
    }
}

// MARK: - Dual Price Display Component
struct DualPriceView: View {
    let eurAmount: Double
    @EnvironmentObject var currencyManager: CurrencyManager
    let showBothPrices: Bool
    let alignment: HorizontalAlignment
    
    init(
        eurAmount: Double,
        showBothPrices: Bool = false,
        alignment: HorizontalAlignment = .trailing
    ) {
        self.eurAmount = eurAmount
        self.showBothPrices = showBothPrices
        self.alignment = alignment
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            // Preço principal na moeda selecionada
            Text(eurAmount.toCurrency(using: currencyManager))
                .font(.headline)
                .fontWeight(.bold)
            
            // Preço secundário (se ativado)
            if showBothPrices {
                let secondaryCurrency: Currency = currencyManager.selectedCurrency == .EUR ? .USD : .EUR
                Text(eurAmount.toCurrency(in: secondaryCurrency, using: currencyManager))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Exchange Rate Info View
struct ExchangeRateInfoView: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Taxa de Câmbio")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if currencyManager.isLoadingRates {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button("🔄") {
                        currencyManager.updateExchangeRates()
                    }
                    .font(.caption)
                }
            }
            
            Text(currencyManager.getExchangeRateString())
                .font(.caption)
                .fontWeight(.medium)
            
            Text(currencyManager.getLastUpdateString())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Estilos de Toggle de Moeda")
            .font(.headline)
        
        CurrencyToggleView(style: .button)
        CurrencyToggleView(style: .segmented)
        CurrencyToggleView(style: .compact)
        CurrencyToggleView(style: .pill)
        CurrencyToggleView(style: .dropdown)
        
        Divider()
        
        DualPriceView(eurAmount: 1234.56, showBothPrices: true)
        
        ExchangeRateInfoView()
    }
    .environmentObject(CurrencyManager())
    .padding()
}
