//
//  EmbeddedWebViewScreen.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

public struct EmbeddedWebViewScreen: View {
    let urlString: String
    
    public init(urlString: String) {
        self.urlString = urlString
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDebugPanel = false
    @State private var consoleLogs: [ConsoleMessage] = []
    @StateObject private var webViewModel = WebViewModel()
    
    public var body: some View {
        NavigationView {
            if let url = URL(string: urlString) {
                WebView(url: url, consoleLogs: $consoleLogs, viewModel: webViewModel)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Embedded WebView")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                dismiss()
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Debug") {
                                showingDebugPanel = true
                            }
                        }
                    }
                    .sheet(isPresented: $showingDebugPanel) {
                        DebugPanel(url: url, consoleLogs: $consoleLogs, webViewModel: webViewModel)
                    }
            } else {
                Text("Invalid URL")
                    .font(.headline)
            }
        }
    }
}





