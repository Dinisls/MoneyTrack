import SwiftUI

struct APIStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var priceManager = PriceManager()
    @State private var connectivityResults: [String: Bool] = [:]
    @State private var isTestingConnectivity = false
    @State private var showingSetupInstructions = false
    @State private var selectedAPI = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Status Geral
                Section(header: Text("Status das APIs")) {
                    ForEach(Array(APIConfiguration.getConfigurationStatus().keys.sorted()), id: \.self) { apiName in
                        let status = APIConfiguration.getConfigurationStatus()[apiName]!
                        APIStatusRow(
                            apiName: apiName,
                            status: status,
                            connectivityResult: connectivityResults[apiName],
                            onSetupTapped: {
                                selectedAPI = apiName
                                showingSetupInstructions = true
                            }
                        )
                    }
                }
                
                // MARK: - Teste de Conectividade
                Section(header: Text("Teste de Conectividade")) {
                    Button(action: testAllAPIs) {
                        HStack {
                            if isTestingConnectivity {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testando...")
                            } else {
                                Image(systemName: "wifi")
                                Text("Testar Todas as APIs")
                            }
                        }
                    }
                    .disabled(isTestingConnectivity)
                    
                    if !connectivityResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Resultados do Teste:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(connectivityResults.keys.sorted()), id: \.self) { api in
                                HStack {
                                    Image(systemName: connectivityResults[api]! ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(connectivityResults[api]! ? .green : .red)
                                    Text(api)
                                        .font(.caption)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Recomendações
                Section(header: Text("Recomendações")) {
                    ForEach(APIConfiguration.getAPIRecommendations(), id: \.self) { recommendation in
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Limites de Rate
                Section(header: Text("Limites de Uso")) {
                    ForEach(Array(APIConfiguration.getRateLimits().keys.sorted()), id: \.self) { api in
                        HStack {
                            Text(api)
                                .font(.caption)
                            Spacer()
                            Text(APIConfiguration.getRateLimits()[api]!)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Ações
                Section(header: Text("Ações")) {
                    Button("📋 Ver Instruções Detalhadas") {
                        selectedAPI = "Geral"
                        showingSetupInstructions = true
                    }
                    
                    Button("🔄 Recarregar Configuração") {
                        // Forçar reload da view
                        Task {
                            await testAllAPIs()
                        }
                    }
                    
                    NavigationLink("⚙️ Configurações Avançadas") {
                        AdvancedAPISettingsView()
                    }
                }
            }
            .navigationTitle("APIs de Preços")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSetupInstructions) {
                APISetupInstructionsView(apiName: selectedAPI)
            }
            .onAppear {
                testAllAPIs()
            }
        }
    }
    
    private func testAllAPIs() {
        isTestingConnectivity = true
        
        Task {
            let results = await priceManager.testAPIConnectivity()
            
            await MainActor.run {
                connectivityResults = results
                isTestingConnectivity = false
            }
        }
    }
}

// MARK: - API Status Row
struct APIStatusRow: View {
    let apiName: String
    let status: APIConfiguration.ConfigurationStatus
    let connectivityResult: Bool?
    let onSetupTapped: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(status.emoji)
                    Text(apiName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Text(status.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let connectivity = connectivityResult {
                    HStack(spacing: 4) {
                        Image(systemName: connectivity ? "wifi" : "wifi.slash")
                            .foregroundColor(connectivity ? .green : .red)
                            .font(.caption)
                        Text(connectivity ? "Conectada" : "Sem conexão")
                            .font(.caption)
                            .foregroundColor(connectivity ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            if status == .needsSetup {
                Button("Configurar") {
                    onSetupTapped()
                }
                .font(.caption)
                .foregroundColor(.blue)
            } else if status == .configured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - API Setup Instructions View
struct APISetupInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    let apiName: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if apiName == "Geral" {
                        GeneralInstructionsView()
                    } else {
                        SpecificAPIInstructionsView(apiName: apiName)
                    }
                }
                .padding()
            }
            .navigationTitle("Configurar \(apiName)")
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

// MARK: - General Instructions
struct GeneralInstructionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Como Configurar as APIs")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Para obter preços em tempo real, você precisa configurar pelo menos uma API. Aqui estão as melhores opções:")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                APIOptionCard(
                    title: "🥇 Yahoo Finance",
                    description: "Gratuita, sem chave necessária",
                    pros: ["Sem configuração", "Boa cobertura de ações", "Sem limites rígidos"],
                    cons: ["Pode ter rate limiting", "Não oficial"],
                    isRecommended: true
                )
                
                APIOptionCard(
                    title: "🥈 FinnHub",
                    description: "60 chamadas por minuto",
                    pros: ["Dados em tempo real", "API oficial", "Boa documentação"],
                    cons: ["Precisa de registo", "Limite de 60/min"],
                    isRecommended: true
                )
                
                APIOptionCard(
                    title: "🥉 Twelve Data",
                    description: "800 chamadas por dia",
                    pros: ["Boa qualidade", "Muitos mercados", "API estável"],
                    cons: ["Limite diário baixo", "Precisa de registo"],
                    isRecommended: false
                )
            }
            
            Divider()
            
            Text("Passos para Configurar:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionStep(number: 1, text: "Escolha uma API da lista acima")
                InstructionStep(number: 2, text: "Siga as instruções específicas")
                InstructionStep(number: 3, text: "Copie a chave para APIConfiguration.swift")
                InstructionStep(number: 4, text: "Recompile o app")
                InstructionStep(number: 5, text: "Teste a conectividade")
            }
        }
    }
}

// MARK: - Specific API Instructions
struct SpecificAPIInstructionsView: View {
    let apiName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configurar \(apiName)")
                .font(.title2)
                .fontWeight(.bold)
            
            if let instructions = APIConfiguration.getSetupInstructions()[apiName] {
                Text(instructions)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if let rateLimit = APIConfiguration.getRateLimits()[apiName] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Limite de Uso:")
                        .font(.headline)
                    
                    Text(rateLimit)
                        .font(.body)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color(.systemOrange).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            Text("Após Configurar:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionStep(number: 1, text: "Abra APIConfiguration.swift")
                InstructionStep(number: 2, text: "Encontre a linha com \(apiName.lowercased())APIKey")
                InstructionStep(number: 3, text: "Substitua YOUR_XXX_KEY pela sua chave")
                InstructionStep(number: 4, text: "Salve e recompile o app")
                InstructionStep(number: 5, text: "Volte aqui e teste a conectividade")
            }
        }
    }
}

// MARK: - Supporting Components
struct APIOptionCard: View {
    let title: String
    let description: String
    let pros: [String]
    let cons: [String]
    let isRecommended: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                if isRecommended {
                    Text("RECOMENDADA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("✅ Vantagens:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                ForEach(pros, id: \.self) { pro in
                    Text("• \(pro)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("⚠️ Limitações:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                ForEach(cons, id: \.self) { con in
                    Text("• \(con)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Advanced Settings View
struct AdvancedAPISettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Configurações de Rede")) {
                HStack {
                    Text("Timeout de Conexão")
                    Spacer()
                    Text("30 segundos")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Retry Automático")
                    Spacer()
                    Text("3 tentativas")
                        .foregroundColor(.secondary)
                }
                
                Toggle("Cache de Preços", isOn: .constant(true))
                    .disabled(true)
            }
            
            Section(header: Text("Preferências de API")) {
                HStack {
                    Text("API Preferida para Ações")
                    Spacer()
                    Text("Yahoo Finance")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("API Preferida para Crypto")
                    Spacer()
                    Text("CoinMarketCap")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Informações")) {
                Text("As configurações avançadas serão implementadas em versões futuras. Por agora, as APIs são utilizadas automaticamente por ordem de prioridade.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Configurações Avançadas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    APIStatusView()
}
