import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var themeManager: ThemeManager // 🆕 Novo
    @State private var monthlyBudget = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 🆕 NOVA SEÇÃO: Aparência
                Section(header: Text("Aparência")) {
                    Toggle("Seguir tema do sistema", isOn: $themeManager.followSystemTheme)
                        .onChange(of: themeManager.followSystemTheme) { _, newValue in
                            themeManager.setFollowSystemTheme(newValue)
                        }
                    
                    if !themeManager.followSystemTheme {
                        Toggle("Modo Escuro", isOn: $themeManager.isDarkMode)
                            .onChange(of: themeManager.isDarkMode) { _, newValue in
                                themeManager.setDarkMode(newValue)
                            }
                    }
                    
                    // Preview do tema atual
                    HStack {
                        Text("Tema atual:")
                        Spacer()
                        HStack {
                            if themeManager.followSystemTheme {
                                Image(systemName: "iphone")
                                Text("Sistema")
                            } else {
                                Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                Text(themeManager.isDarkMode ? "Escuro" : "Claro")
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Orçamento")) {
                    HStack {
                        Text("Orçamento Mensal")
                        Spacer()
                        TextField("€", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if financeManager.financeData.monthlyBudget > 0 {
                        let remaining = financeManager.financeData.monthlyBudget - financeManager.financeData.monthlyExpenses
                        HStack {
                            Text("Restante do Orçamento")
                            Spacer()
                            Text(remaining.toCurrency())
                                .foregroundColor(remaining >= 0 ? .green : .red)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: min(financeManager.financeData.monthlyExpenses, financeManager.financeData.monthlyBudget),
                                   total: financeManager.financeData.monthlyBudget)
                            .progressViewStyle(LinearProgressViewStyle(tint: remaining >= 0 ? .green : .red))
                    }
                }
                
                Section(header: Text("Categorias")) {
                    Button("Gerenciar Categorias") {
                        // Implementar CategoryManagerView
                    }
                }
                
                Section(header: Text("Dados")) {
                    Button("Exportar Dados") {
                        exportData()
                    }
                    
                    Button("Limpar Todos os Dados", role: .destructive) {
                        clearAllData()
                    }
                }
                
                Section(header: Text("Sobre")) {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Desenvolvido por")
                        Spacer()
                        Text("MoneyTrack Team")
                            .foregroundColor(.secondary)
                    }
                    
                    // 🆕 Info sobre o tema
                    HStack {
                        Text("Suporte a Modo Escuro")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Configurações")
            .onAppear {
                monthlyBudget = String(financeManager.financeData.monthlyBudget)
            }
            .onChange(of: monthlyBudget) { oldValue, newValue in
                if let budget = Double(newValue) {
                    financeManager.setBudget(budget)
                }
            }
            .alert("MoneyTrack", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func exportData() {
        alertMessage = "Funcionalidade de exportação será implementada em breve!"
        showingAlert = true
    }
    
    private func clearAllData() {
        financeManager.financeData = FinanceData()
        financeManager.saveData()
        alertMessage = "Todos os dados foram limpos!"
        showingAlert = true
    }
}

#Preview {
    SettingsView()
        .environmentObject(FinanceManager())
        .environmentObject(ThemeManager())
}
