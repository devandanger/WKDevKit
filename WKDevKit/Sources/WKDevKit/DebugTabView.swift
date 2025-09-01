//
//  DebugTabView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct DebugTabView: View {
    let url: URL
    @Binding var selectedTab: Int
    @Binding var consoleLogs: [ConsoleMessage]
    let webStorageItems: [WebStorageItem]
    let isLoadingStorage: Bool
    let onRefreshStorage: () -> Void
    let domTree: DOMNode?
    let isLoadingDOM: Bool
    let onRefreshDOM: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                ConsoleView(logs: consoleLogs)
                    .tabItem { Label("Console", systemImage: "terminal") }
                    .tag(0)
                
                DOMInspectorView(domTree: domTree, isLoading: isLoadingDOM, onRefresh: onRefreshDOM)
                    .tabItem { Label("DOM", systemImage: "doc.text.magnifyingglass") }
                    .tag(1)
                
                WebStorageView(items: webStorageItems, isLoading: isLoadingStorage, onRefresh: onRefreshStorage)
                    .tabItem { Label("Storage", systemImage: "internaldrive") }
                    .tag(2)
                
                InfoView(url: url)
                    .tabItem { Label("Info", systemImage: "info.circle") }
                    .tag(3)
            }
        }
    }
}