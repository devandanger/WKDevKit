//
//  WKDevKitDebugger.swift
//  WKDevKit
//
//  Composition-based debugging interface for WKWebView
//

import WebKit
import Combine

#if os(iOS)
/// Main debugger class that can be attached to any WKWebView

@MainActor
public class WKDevKitDebugger: ObservableObject {
    private weak var webView: WKWebView?
    private var configuration: WKDevKitConfiguration
    private var consoleHandler: ConsoleMessageHandler?
    private var messageHandlerName = "wkdevkit_console"
    
    // Delegate proxies
    private var navigationProxy: NavigationDelegateProxy?
    private var uiDelegateProxy: UIDelegateProxy?
    private var scriptMessageProxies: [String: ScriptMessageHandlerProxy] = [:]
    
    // Original delegates
    private weak var originalNavigationDelegate: WKNavigationDelegate?
    private weak var originalUIDelegate: WKUIDelegate?
    
    /// Published array of console messages
    @Published public private(set) var consoleLogs: [ConsoleMessage] = []
    
    /// Events view model for capturing WebView events
    public let eventsViewModel = EventsViewModel()
    
    /// Publisher for console messages
    public var consoleMessagePublisher: AnyPublisher<ConsoleMessage, Never> {
        $consoleLogs
            .compactMap { $0.last }
            .eraseToAnyPublisher()
    }
    
    public init(webView: WKWebView, configuration: WKDevKitConfiguration = .default) {
        self.webView = webView
        self.configuration = configuration
        setupDebugCapabilities()
        
        if configuration.enableEventCapture {
            setupEventCapture()
        }
    }
    
    private func setupDebugCapabilities() {
        guard let webView = webView else { return }
        
        if configuration.enableConsoleLogging {
            injectConsoleScript()
            setupConsoleHandler()
        }
        
        // Enable web inspector for iOS 16.4+
        if configuration.enableWebInspector {
            #if os(iOS)
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            #elseif os(macOS)
            if #available(macOS 13.3, *) {
                webView.isInspectable = true
            }
            #endif
        }
    }
    
    private func injectConsoleScript() {
        guard let webView = webView else { return }
        
        let consoleScript = """
        (function() {
            if (window.__wkdevkit_initialized) return;
            window.__wkdevkit_initialized = true;
            
            const methods = ['log', 'warn', 'error', 'info', 'debug'];
            methods.forEach((method) => {
                const original = console[method];
                console[method] = function(...args) {
                    window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                        method: method,
                        args: args.map(arg => {
                            try {
                                if (typeof arg === 'object') {
                                    return JSON.stringify(arg, null, 2);
                                }
                                return String(arg);
                            } catch {
                                return String(arg);
                            }
                        })
                    });
                    original.apply(console, args);
                };
            });
        })();
        """
        
        let script = WKUserScript(
            source: consoleScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    private func setupConsoleHandler() {
        guard let webView = webView else { return }
        
        consoleHandler = ConsoleMessageHandler { [weak self] message in
            DispatchQueue.main.async {
                self?.consoleLogs.append(message)
                
                // Limit console log history
                if self?.consoleLogs.count ?? 0 > 1000 {
                    self?.consoleLogs.removeFirst(100)
                }
            }
        }
        
        webView.configuration.userContentController.add(
            consoleHandler!,
            name: messageHandlerName
        )
    }
    
    /// Clear all console logs
    public func clearConsole() {
        consoleLogs.removeAll()
    }
    
    /// Fetch the current DOM tree
    @MainActor
    public func fetchDOMTree() async -> DOMNode? {
        guard let webView = webView,
              configuration.enableDOMInspection else { return nil }
        
        let script = """
        (function() {
            function getDomTree(element) {
                let directText = "";
                for (let node of element.childNodes) {
                    if (node.nodeType === Node.TEXT_NODE) {
                        const text = node.textContent.trim();
                        if (text) {
                            directText += (directText ? " " : "") + text;
                        }
                    }
                }
                
                const obj = {
                    tag: element.tagName || "",
                    id: element.id || "",
                    className: (typeof element.className === 'string' ? element.className : element.className?.baseVal || "") || "",
                    innerText: element.children.length === 0 ? (directText || element.innerText?.trim() || null) : (directText || null),
                    children: []
                };
                
                for (let child of element.children) {
                    obj.children.push(getDomTree(child));
                }
                return obj;
            }
            return JSON.stringify(getDomTree(document.body));
        })()
        """
        
        do {
            let result = try await webView.evaluateJavaScript(script)
            if let jsonString = result as? String,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try decoder.decode(DOMNode.self, from: jsonData)
            }
        } catch {
            print("WKDevKit: Error fetching DOM: \(error)")
        }
        return nil
    }
    
    /// Fetch web storage items (localStorage, sessionStorage, cookies)
    @MainActor
    public func fetchWebStorage() async -> [WebStorageItem] {
        guard let webView = webView,
              configuration.enableStorageInspection else { return [] }
        
        var allItems: [WebStorageItem] = []
        
        // Fetch localStorage
        if configuration.storageTypes.contains(.localStorage) {
            let localStorageScript = """
            (function() {
                try {
                    return Object.entries(localStorage || {});
                } catch(e) {
                    return [];
                }
            })();
            """
            
            do {
                let result = try await webView.evaluateJavaScript(localStorageScript)
                if let entries = result as? [[Any]] {
                    let localItems = entries.compactMap { entry -> WebStorageItem? in
                        guard entry.count == 2,
                              let key = entry[0] as? String,
                              let value = entry[1] as? String else { return nil }
                        return WebStorageItem(key: key, value: value, type: .localStorage)
                    }
                    allItems.append(contentsOf: localItems)
                }
            } catch {
                print("WKDevKit: Error fetching localStorage: \(error)")
            }
        }
        
        // Fetch sessionStorage
        if configuration.storageTypes.contains(.sessionStorage) {
            let sessionStorageScript = """
            (function() {
                try {
                    return Object.entries(sessionStorage || {});
                } catch(e) {
                    return [];
                }
            })();
            """
            
            do {
                let result = try await webView.evaluateJavaScript(sessionStorageScript)
                if let entries = result as? [[Any]] {
                    let sessionItems = entries.compactMap { entry -> WebStorageItem? in
                        guard entry.count == 2,
                              let key = entry[0] as? String,
                              let value = entry[1] as? String else { return nil }
                        return WebStorageItem(key: key, value: value, type: .sessionStorage)
                    }
                    allItems.append(contentsOf: sessionItems)
                }
            } catch {
                print("WKDevKit: Error fetching sessionStorage: \(error)")
            }
        }
        
        // Fetch cookies
        if configuration.storageTypes.contains(.cookies) {
            let cookieScript = "document.cookie || '';"
            
            do {
                let result = try await webView.evaluateJavaScript(cookieScript)
                if let cookieString = result as? String, !cookieString.isEmpty {
                    let cookiePairs = cookieString.split(separator: ";")
                    let cookieItems = cookiePairs.compactMap { pair -> WebStorageItem? in
                        let trimmed = pair.trimmingCharacters(in: .whitespaces)
                        let components = trimmed.split(separator: "=", maxSplits: 1)
                        guard components.count == 2 else { return nil }
                        let key = String(components[0])
                        let value = String(components[1])
                        return WebStorageItem(key: key, value: value, type: .cookies)
                    }
                    allItems.append(contentsOf: cookieItems)
                }
            } catch {
                print("WKDevKit: Error fetching cookies: \(error)")
            }
        }
        
        return allItems
    }
    
    /// Execute custom JavaScript in the WebView
    @MainActor
    public func executeJavaScript(_ script: String) async throws -> Any? {
        guard let webView = webView else {
            throw WKDevKitError.webViewDeallocated
        }
        return try await webView.evaluateJavaScript(script)
    }
    
    /// Setup event capture by wrapping delegates
    private func setupEventCapture() {
        guard let webView = webView else { return }
        
        // Wrap navigation delegate
        if let currentNavDelegate = webView.navigationDelegate {
            originalNavigationDelegate = currentNavDelegate
        }
        navigationProxy = NavigationDelegateProxy(
            originalDelegate: originalNavigationDelegate,
            eventsViewModel: eventsViewModel
        )
        webView.navigationDelegate = navigationProxy
        
        // Wrap UI delegate
        if let currentUIDelegate = webView.uiDelegate {
            originalUIDelegate = currentUIDelegate
        }
        uiDelegateProxy = UIDelegateProxy(
            originalDelegate: originalUIDelegate,
            eventsViewModel: eventsViewModel
        )
        webView.uiDelegate = uiDelegateProxy
        
        // Note: Download delegate is handled at the WebView level, not configuration
        // We'll provide a method to set it
    }
    
    
    /// Add a script message handler with event capture
    public func addScriptMessageHandler(name: String, handler: WKScriptMessageHandler) {
        guard let webView = webView else { return }
        
        if configuration.enableEventCapture {
            let proxy = ScriptMessageHandlerProxy(
                handlerName: name,
                originalHandler: handler,
                eventsViewModel: eventsViewModel
            )
            scriptMessageProxies[name] = proxy
            webView.configuration.userContentController.add(proxy, name: name)
        } else {
            webView.configuration.userContentController.add(handler, name: name)
        }
    }
    
    /// Remove a script message handler
    public func removeScriptMessageHandler(name: String) {
        guard let webView = webView else { return }
        webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        scriptMessageProxies.removeValue(forKey: name)
    }
    
    /// Restore original delegates
    private func restoreOriginalDelegates() {
        guard let webView = webView else { return }
        
        if originalNavigationDelegate != nil || navigationProxy != nil {
            webView.navigationDelegate = originalNavigationDelegate
        }
        
        if originalUIDelegate != nil || uiDelegateProxy != nil {
            webView.uiDelegate = originalUIDelegate
        }
        
    }
    
    /// Clean up and remove message handlers
    public func cleanup() {
        guard let webView = webView else { return }
        
        // Remove console handler
        webView.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
        consoleHandler = nil
        
        // Restore original delegates
        if configuration.enableEventCapture {
            restoreOriginalDelegates()
        }
        
        // Remove script message handlers
        for name in scriptMessageProxies.keys {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
        scriptMessageProxies.removeAll()
    }
    
    deinit {
        // Cleanup is handled by the webView when it's deallocated
        // or explicitly via cleanup() method
    }
}
#endif

/// Errors that can occur in WKDevKit
public enum WKDevKitError: Error {
    case webViewDeallocated
    case featureDisabled
    case scriptExecutionFailed(Error)
}