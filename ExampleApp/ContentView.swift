//
//  ContentView.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
//

import SwiftUI
import SwiftData
import SafariServices
import WKDevKit

enum WebViewType: String, CaseIterable {
    case safariInternal = "Safari Internal"
    case externalSafari = "External Safari"
    case embeddedWebView = "Embedded WebView"
    
    var title: String {
        return self.rawValue
    }
}

struct ContentView: View {
    @State private var urlText: String = "https://www.google.com"
    @State private var selectedWebViewType: WebViewType = .embeddedWebView
    @State private var showingSafariView = false
    @State private var showingEmbeddedWebView = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("WebView Inspector")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 20) {
                TextField("Enter URL", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                Picker("WebView Type", selection: $selectedWebViewType) {
                    ForEach(WebViewType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Button("Launch") {
                    launchWebView()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafariView) {
            if let url = URL(string: urlText) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showingEmbeddedWebView) {
            EmbeddedWebViewScreen(urlString: urlText)
        }
    }
    
    private func launchWebView() {
        guard let url = URL(string: urlText) else {
            print("Invalid URL: \(urlText)")
            return
        }
        
        switch selectedWebViewType {
        case .safariInternal:
            showingSafariView = true
        case .externalSafari:
            UIApplication.shared.open(url)
        case .embeddedWebView:
            showingEmbeddedWebView = true
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = .systemBlue
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    ContentView()
}
