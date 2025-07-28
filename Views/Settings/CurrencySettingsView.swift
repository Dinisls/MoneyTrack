import SwiftUI

struct CurrencySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showingExchangeRateDetails = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Seleção de Moeda
                Section(header: Text("Moeda de Visualização")) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        HStack {
                            Text(currency.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.name)
                                    .font(.body)
                                
                                Text(currency.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if currencyManager.selectedCurrency == currency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currencyManager.setCurrency(currency)
                        }
                    }
                    
                    Text("Todos os valores no app serão exibidos na moeda selecionada.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Taxa de Câmbio
                Section(header: Text("Taxa de Câmbio")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EUR para USD")
                                .font(.body)
                            
                            Text(currencyManager.getExchangeRateString())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if currencyManager.isLoadingRates {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button("Atualizar") {
                                currencyManager.updateExchangeRates()
                            }
                            .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Última Atualização")
                        Spacer()
                        Text(currencyManager.getLastUpdateString())
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    Button("Ver Detalhes da Taxa") {
                        showingExchangeRateDetails = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // MARK: - Exemplos de Conversão
                Section(header: Text("Exemplos de Conversão")) {
                    ConversionExampleRow(eurAmount: 100)
                    ConversionExampleRow(eurAmount: 1000)
                    ConversionExampleRow(eurAmount: 10000)
                }
                
                // MARK: - Configurações Avançadas
                Section(header: Text("Configurações")) {
                    Toggle("Atualização Automática", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Intervalo de Atualização")
                        Spacer()
                        Text("4 horas")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("As taxas de câmbio são atualizadas automaticamente a cada 4 horas quando o app está em uso.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Informações
                Section(header: Text("Sobre")) {
                    HStack {
                        Text("Fonte dos Dados")
                        Spacer()
                        Text("ExchangeRate-API")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Precisão")
                        Spacer()
                        Text("4 casas decimais")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("As taxas de câmbio são fornecidas por serviços externos e podem ter pequenos atrasos. Para investimentos profissionais, consulte sempre fontes oficiais.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Configurar Moeda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExchangeRateDetails) {
                ExchangeRateDetailsView()
            }
        }
    }
}

// MARK: - Conversion Example Row
struct ConversionExampleRow: View {
    let eurAmount: Double
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        HStack {
            Text(eurAmount.toCurrency(in: .EUR, using: currencyManager))
                .fontWeight(.medium)
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Spacer()
            
            Text(eurAmount.toCurrency(in: .USD, using: currencyManager))
                .foregroundColor(.blue)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Exchange Rate Details View
struct ExchangeRateDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Gráfico visual da taxa
                ExchangeRateVisualization()
                
                // Calculadora de conversão
                CurrencyCalculator()
                
                // Histórico (placeholder)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Histórico Recente")
                        .font(.headline)
                    
                    Text("Funcionalidade de histórico será implementada em versões futuras.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Detalhes da Taxa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Exchange Rate Visualization
struct ExchangeRateVisualization: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Taxa de Câmbio Atual")
                .font(.headline)
            
            HStack(spacing: 20) {
                CurrencyBlock(currency: .EUR, amount: 1.0)
                
                Image(systemName: "equal")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                CurrencyBlock(
                    currency: .USD,
                    amount: currencyManager.exchangeRates["USD"] ?? 1.10
                )
            }
            
            Text(currencyManager.getLastUpdateString())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CurrencyBlock: View {
    let currency: Currency
    let amount: Double
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(currency.flag)
                .font(.largeTitle)
            
            Text(currency.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(currencyManager.formatPrice(amount, in: currency))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(width: 100, height: 80)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Currency Calculator
struct CurrencyCalculator: View {
    @State private var inputAmount = ""
    @State private var fromCurrency: Currency = .EUR
    @State private var toCurrency: Currency = .USD
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var convertedAmount: Double {
        guard let amount = Double(inputAmount) else { return 0 }
        return currencyManager.convert(amount, from: fromCurrency, to: toCurrency)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calculadora de Conversão")
                .font(.headline)
            
            HStack {
                TextField("Valor", text: $inputAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("De", selection: $fromCurrency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Text("=")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(currencyManager.formatPrice(convertedAmount, in: toCurrency))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Picker("Para", selection: $toCurrency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    CurrencySettingsView()
        .environmentObject(CurrencyManager())
}
