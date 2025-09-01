//
//  DebugPanel.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct DebugPanel: View {
    let url: URL
    @Binding var consoleLogs: [ConsoleMessage]
    let webViewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var domTree: DOMNode?
    @State private var isLoadingDOM = false
    @State private var webStorageItems: [WebStorageItem] = []
    @State private var isLoadingStorage = false
    
    var body: some View {
        NavigationView {
            DebugTabView(
                url: url,
                selectedTab: $selectedTab,
                consoleLogs: $consoleLogs,
                webStorageItems: webStorageItems,
                isLoadingStorage: isLoadingStorage,
                onRefreshStorage: fetchWebStorage,
                domTree: domTree,
                isLoadingDOM: isLoadingDOM,
                onRefreshDOM: fetchDOM
            )
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                
//                if selectedTab == 0 {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Clear") { consoleLogs.removeAll() }
//                    }
//                } else if selectedTab == 1 {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Refresh") { fetchDOM() }
//                    }
//                } else if selectedTab == 2 {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Refresh") { fetchLocalStorage() }
//                    }
//                }
            }
        }
        .onAppear {
            if selectedTab == 1 && domTree == nil {
                fetchDOM()
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 && domTree == nil {
                fetchDOM()
            }
        }
    }
    
    private func fetchDOM() {
        isLoadingDOM = true
        Task {
            domTree = await webViewModel.fetchDOMTree()
            isLoadingDOM = false
        }
    }
    
    private func fetchWebStorage() {
        isLoadingStorage = true
        Task {
            webStorageItems = await webViewModel.fetchWebStorage()
            isLoadingStorage = false
        }
    }
}
