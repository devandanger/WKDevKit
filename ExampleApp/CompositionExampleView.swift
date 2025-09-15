//
//  CompositionExampleView.swift
//  ExampleApp
//
//  Example of using the new composition-based WKDevKit API
//

import Combine
import SwiftUI
import WebKit
import WKDevKit

#if os(iOS)

public struct CompositionExampleView: View {
    let urlString: String
    
    @StateObject private var webViewStore = WebViewStore()
    @State private var showingDebugPanel = false
    @State private var selectedDebugTab = 0
    @State private var domTree: WKDevKit.DOMNode?
    @State private var storageItems: [WebStorageItem] = []
    @State private var isLoadingDOM = false
    @State private var isLoadingStorage = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom WebView using composition
                CustomWebView(url: URL(string: urlString), store: webViewStore)
                    .ignoresSafeArea(edges: .bottom)
                
                // Inline console view at the bottom (optional)
                if webViewStore.showInlineConsole {
                    WKDevKitConsoleView(messages: webViewStore.consoleLogs)
                        .frame(height: 200)
                        .background(Color(UIColor.systemBackground))
                        .shadow(radius: 2)
                }
            }
            .navigationTitle("Composition Example")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Console") {
                        webViewStore.showInlineConsole.toggle()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        showingDebugPanel = true
                    }
                }
            }
            .sheet(isPresented: $showingDebugPanel) {
                CompositionDebugPanel(
                    webViewStore: webViewStore,
                    selectedTab: $selectedDebugTab,
                    domTree: $domTree,
                    storageItems: $storageItems,
                    isLoadingDOM: $isLoadingDOM,
                    isLoadingStorage: $isLoadingStorage
                )
            }
        }
    }
}

// WebView store to manage state
public class WebViewStore: ObservableObject {
    @Published var consoleLogs: [ConsoleMessage] = []
    @Published var showInlineConsole = false
    var debugger: WKDevKitDebugger?
    weak var webView: WKWebView?
}

// Custom WebView implementation using composition
struct CustomWebView: UIViewRepresentable {
    let url: URL?
    let store: WebViewStore
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Add WKDevKit debugging with custom configuration
        let config = WKDevKitConfiguration.builder()
            .withConsoleLogging(true)
            .withDOMInspection(true)
            .withStorageInspection(true)
            .withWebInspector(true)
            .build()
        
        let debugger = webView.addDevKitDebugging(configuration: config)
        
        // Store references
        store.webView = webView
        store.debugger = debugger
        
        // Subscribe to console messages
        let cancellable = debugger.$consoleLogs
            .receive(on: DispatchQueue.main)
            .sink { messages in
                store.consoleLogs = messages
            }
        
        // Store the cancellable (in production, manage this properly)
        context.coordinator.cancellable = cancellable
        
        // Load the URL
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle updates if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var cancellable: AnyCancellable?
    }
}

// Custom debug panel using standalone components
public struct CompositionDebugPanel: View {
    @ObservedObject var webViewStore: WebViewStore
    @Binding var selectedTab: Int
    @Binding var domTree: WKDevKit.DOMNode?
    @Binding var storageItems: [WebStorageItem]
    @Binding var isLoadingDOM: Bool
    @Binding var isLoadingStorage: Bool
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Console tab using standalone component
                WKDevKitConsoleView(messages: webViewStore.consoleLogs)
                    .tabItem {
                        Label("Console", systemImage: "terminal")
                    }
                    .tag(0)
                
                // DOM Inspector tab using standalone component
                ZStack {
                    WKDevKitDOMInspector(rootNode: domTree)
                    
                    if isLoadingDOM {
                        ProgressView("Loading DOM...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
                .tabItem {
                    Label("DOM", systemImage: "doc.text.below.ecg")
                }
                .tag(1)
                .onAppear {
                    if domTree == nil {
                        loadDOM()
                    }
                }
                
                // Storage tab using standalone component
                ZStack {
                    WKDevKitStorageView(items: storageItems)
                    
                    if isLoadingStorage {
                        ProgressView("Loading Storage...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }
                .tag(2)
                .onAppear {
                    if storageItems.isEmpty {
                        loadStorage()
                    }
                }
                
                // Events tab using the new events view
                if let eventsViewModel = webViewStore.debugger?.eventsViewModel {
                    WKWebViewEventsView(eventsViewModel: eventsViewModel)
                        .tabItem {
                            Label("Events", systemImage: "list.bullet.rectangle")
                        }
                        .tag(3)
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedTab == 0 {
                        Button("Clear") {
                            webViewStore.debugger?.clearConsole()
                            webViewStore.consoleLogs.removeAll()
                        }
                    } else if selectedTab == 1 {
                        Button("Refresh") {
                            loadDOM()
                        }
                    } else if selectedTab == 2 {
                        Button("Refresh") {
                            loadStorage()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadDOM() {
        isLoadingDOM = true
        Task {
            domTree = await webViewStore.debugger?.fetchDOMTree()
            isLoadingDOM = false
        }
    }
    
    private func loadStorage() {
        isLoadingStorage = true
        Task {
            storageItems = await webViewStore.debugger?.fetchWebStorage() ?? []
            isLoadingStorage = false
        }
    }
}
#endif
