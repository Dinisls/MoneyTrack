import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var followSystemTheme: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let isDarkModeKey = "isDarkMode_v2"
    private let followSystemThemeKey = "followSystemTheme_v2"
    
    init() {
        loadThemeSettings()
        observeSystemThemeChanges()
    }
    
    func loadThemeSettings() {
        // ✅ Método mais seguro para verificar configurações
        let hasFollowSystemSetting = userDefaults.object(forKey: followSystemThemeKey) != nil
        let hasDarkModeSetting = userDefaults.object(forKey: isDarkModeKey) != nil
        
        if hasFollowSystemSetting && hasDarkModeSetting {
            // Carregar configurações existentes
            followSystemTheme = userDefaults.bool(forKey: followSystemThemeKey)
            isDarkMode = userDefaults.bool(forKey: isDarkModeKey)
        } else {
            // Primeira vez - usar padrões e salvar
            followSystemTheme = true
            isDarkMode = false
            saveThemeSettings()
        }
        
        print("🎨 Tema carregado: seguirSistema=\(followSystemTheme), escuro=\(isDarkMode)")
    }
    
    func saveThemeSettings() {
        userDefaults.set(isDarkMode, forKey: isDarkModeKey)
        userDefaults.set(followSystemTheme, forKey: followSystemThemeKey)
        
        print("💾 Tema salvo: seguirSistema=\(followSystemTheme), escuro=\(isDarkMode)")
    }
    
    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        followSystemTheme = false
        saveThemeSettings()
    }
    
    func setFollowSystemTheme(_ enabled: Bool) {
        followSystemTheme = enabled
        if enabled {
            // Quando ativar "seguir sistema", detectar tema atual do sistema
            updateFromSystemTheme()
        }
        saveThemeSettings()
    }
    
    func toggleDarkMode() {
        setDarkMode(!isDarkMode)
    }
    
    // ✅ NOVO: Detectar tema atual do sistema
    private func updateFromSystemTheme() {
        // Esta função será chamada quando necessário
        // O sistema automaticamente aplicará o tema correto
    }
    
    // ✅ NOVO: Observar mudanças no tema do sistema
    private func observeSystemThemeChanges() {
        // Observar mudanças no tema do sistema iOS
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if self.followSystemTheme {
                // Atualizar quando app se torna ativo
                self.objectWillChange.send()
            }
        }
    }
    
    // Determinar o esquema de cores baseado nas configurações
    func getColorScheme() -> ColorScheme? {
        if followSystemTheme {
            return nil // Usa o tema do sistema automaticamente
        } else {
            return isDarkMode ? .dark : .light
        }
    }
    
    // ✅ NOVO: Função para debug/testes
    func getCurrentThemeDescription() -> String {
        if followSystemTheme {
            return "Seguindo tema do sistema"
        } else {
            return isDarkMode ? "Modo escuro fixo" : "Modo claro fixo"
        }
    }
    
    // ✅ NOVO: Reset para configurações padrão
    func resetToDefaults() {
        followSystemTheme = true
        isDarkMode = false
        saveThemeSettings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
