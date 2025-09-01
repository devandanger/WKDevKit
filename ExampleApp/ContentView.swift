//
//  ContentView.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import SafariServices
#endif
import WKDevKit

#if os(iOS)
enum WebViewType: String, CaseIterable {
    case embeddedWebView = "Embedded WebView (Legacy)"
    case compositionBased = "Composition Based (New)"
    
    var title: String {
        return self.rawValue
    }
}

@available(iOS 15.0, *)
public struct ContentView: View {
    @State private var urlText: String = "https://www.google.com"
    @State private var selectedWebViewType: WebViewType = .compositionBased
    @State private var showingEmbeddedWebView = false
    @State private var showingCompositionView = false
    
    public var body: some View {
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
        .sheet(isPresented: $showingEmbeddedWebView) {
            EmbeddedWebViewScreen(urlString: urlText)
        }
        .sheet(isPresented: $showingCompositionView) {
            CompositionExampleView(urlString: urlText)
        }
    }
    
    private func launchWebView() {
        guard let url = URL(string: urlText) else {
            print("Invalid URL: \(urlText)")
            return
        }
        
        switch selectedWebViewType {

        case .embeddedWebView:
            showingEmbeddedWebView = true
        case .compositionBased:
            showingCompositionView = true
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
#endif
