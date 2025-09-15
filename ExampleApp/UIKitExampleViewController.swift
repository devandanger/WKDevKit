//
//  UIKitExampleViewController.swift
//  ExampleApp
//
//  Example of using WKDevKit with UIKit
//

#if os(iOS)
import UIKit
import WebKit
import WKDevKit


public class UIKitExampleViewController: UIViewController {
    private var webView: WKWebView!
    private var debugger: WKDevKitDebugger?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
    }
    
    private func setupUI() {
        title = "UIKit Example"
        view.backgroundColor = .systemBackground
        
        // Create web view
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add debug button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Debug",
            style: .plain,
            target: self,
            action: #selector(showDebugPanel)
        )
        
        // Add console button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Console",
            style: .plain,
            target: self,
            action: #selector(showConsoleOnly)
        )
    }
    
    private func setupWebView() {
        // Add WKDevKit debugging with custom configuration
        let config = WKDevKitConfiguration.builder()
            .withConsoleLogging(true)
            .withDOMInspection(true)
            .withStorageInspection(true)
            .withWebInspector(true)
            .build()
        
        debugger = webView.addDevKitDebugging(configuration: config)
        
        // Load a test page
        if let url = URL(string: "https://example.com") {
            webView.load(URLRequest(url: url))
        }
    }
    
    @objc private func showDebugPanel() {
        WKDevKitDebugViewController.present(from: self, webView: webView)
    }
    
    @objc private func showConsoleOnly() {
        let consoleVC = WKDevKitConsoleViewController()
        consoleVC.debugger = debugger
        let navController = UINavigationController(rootViewController: consoleVC)
        present(navController, animated: true)
    }
}#endif
