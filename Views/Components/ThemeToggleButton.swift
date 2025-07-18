//
//  ThemeToggleButton.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let style: ToggleStyle
    
    enum ToggleStyle {
        case icon
        case text
        case compact
    }
    
    var body: some View {
        switch style {
        case .icon:
            Button(action: toggleTheme) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
        case .text:
            Button(action: toggleTheme) {
                Label(buttonText, systemImage: iconName)
            }
            
        case .compact:
            Button(action: toggleTheme) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.caption)
                    Text(compactText)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
    }
    
    private func toggleTheme() {
        if themeManager.followSystemTheme {
            themeManager.setFollowSystemTheme(false)
            themeManager.setDarkMode(true)
        } else {
            themeManager.toggleDarkMode()
        }
    }
    
    private var iconName: String {
        if themeManager.followSystemTheme {
            return "iphone"
        } else {
            return themeManager.isDarkMode ? "sun.max" : "moon"
        }
    }
    
    private var buttonText: String {
        if themeManager.followSystemTheme {
            return "Seguindo Sistema"
        } else {
            return themeManager.isDarkMode ? "Modo Claro" : "Modo Escuro"
        }
    }
    
    private var compactText: String {
        if themeManager.followSystemTheme {
            return "Auto"
        } else {
            return themeManager.isDarkMode ? "Escuro" : "Claro"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ThemeToggleButton(style: .icon)
        ThemeToggleButton(style: .text)
        ThemeToggleButton(style: .compact)
    }
    .environmentObject(ThemeManager())
    .padding()
}