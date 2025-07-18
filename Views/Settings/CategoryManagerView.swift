//
//  CategoryManagerView.swift
//  MoneyTrack
//
//  Created by Dinis Santos on 18/07/2025.
//


import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    @State private var newCategory = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(financeManager.financeData.categories, id: \.self) { category in
                        Text(category)
                    }
                    .onDelete(perform: deleteCategories)
                }
                
                HStack {
                    TextField("Nova categoria", text: $newCategory)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Adicionar") {
                        addCategory()
                    }
                    .disabled(newCategory.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Categorias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addCategory() {
        if !newCategory.isEmpty && !financeManager.financeData.categories.contains(newCategory) {
            financeManager.financeData.categories.append(newCategory)
            financeManager.saveData()
            newCategory = ""
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        financeManager.financeData.categories.remove(atOffsets: offsets)
        financeManager.saveData()
    }
}