//
//  WKDevKitDebugViewController.swift
//  WKDevKit
//
//  UIKit debug view controller for WKWebView debugging
//

#if os(iOS)
import UIKit
import WebKit
@available(iOS 15.0, *)
public class WKDevKitDebugViewController: UIViewController {
    private let webView: WKWebView
    private var debugger: WKDevKitDebugger?
    private var debugTabBarController: UITabBarController!
    
    public init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        self.debugger = webView.devKitDebugger
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Debug Panel"
        view.backgroundColor = .systemBackground
        
        // Create tab bar controller
        debugTabBarController = UITabBarController()
        
        // Console tab
        let consoleVC = WKDevKitConsoleViewController()
        consoleVC.tabBarItem = UITabBarItem(
            title: "Console",
            image: UIImage(systemName: "terminal"),
            tag: 0
        )
        
        // DOM tab
        let domVC = WKDevKitDOMViewController(webView: webView)
        domVC.tabBarItem = UITabBarItem(
            title: "DOM",
            image: UIImage(systemName: "doc.text.below.ecg"),
            tag: 1
        )
        
        // Storage tab
        let storageVC = WKDevKitStorageViewController(webView: webView)
        storageVC.tabBarItem = UITabBarItem(
            title: "Storage",
            image: UIImage(systemName: "externaldrive"),
            tag: 2
        )
        
        debugTabBarController.viewControllers = [consoleVC, domVC, storageVC]
        
        // Add tab bar as child
        addChild(debugTabBarController)
        view.addSubview(debugTabBarController.view)
        debugTabBarController.didMove(toParent: self)
        
        // Setup constraints
        debugTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugTabBarController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            debugTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            debugTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            debugTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )
        
        // Connect to debugger
        if let debugger = debugger {
            consoleVC.debugger = debugger
        }
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    /// Present the debug panel modally
    public static func present(from viewController: UIViewController, webView: WKWebView) {
        let debugVC = WKDevKitDebugViewController(webView: webView)
        let navController = UINavigationController(rootViewController: debugVC)
        viewController.present(navController, animated: true)
    }
}
#endif