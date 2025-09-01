//
//  WebView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI
import WebKit
import Combine

class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    let onMessage: (ConsoleMessage) -> Void
    
    init(onMessage: @escaping (ConsoleMessage) -> Void) {
        self.onMessage = onMessage
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let method = dict["method"] as? String,
              let args = dict["args"] as? [Any] else { return }
        
        let consoleMessage = ConsoleMessage(
            method: method,
            args: args.map { String(describing: $0) }.joined(separator: " "),
            timestamp: Date()
        )
        onMessage(consoleMessage)
    }
}

struct ConsoleMessage: Identifiable {
    let id = UUID()
    let method: String
    let args: String
    let timestamp: Date
    
    init(method: String, args: String, timestamp: Date) {
        self.method = method
        self.args = args
        self.timestamp = timestamp
    }
}

struct WebStorageItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let type: WebStorageType
    
    init(key: String, value: String, type: WebStorageType) {
        self.key = key
        self.value = value
        self.type = type
    }
}

enum WebStorageType: String, CaseIterable {
    case localStorage = "Local Storage"
    case sessionStorage = "Session Storage"
    case cookies = "Cookies"
}

struct DOMNode: Identifiable, Decodable {
    let id = UUID()
    let tag: String
    let idAttr: String
    let className: String
    let innerText: String?
    let children: [DOMNode]
    
    enum CodingKeys: String, CodingKey {
        case tag, idAttr = "id", className, innerText, children
    }
    
    func toRawText(indent: Int = 0) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = indentString + "<\(tag.lowercased())"
        
        if !idAttr.isEmpty {
            result += " id=\"\(idAttr)\""
        }
        
        if !className.isEmpty {
            result += " class=\"\(className)\""
        }
        
        if children.isEmpty && (innerText == nil || innerText!.isEmpty) {
            result += " />"
        } else {
            result += ">"
            
            // Add inner text if it exists and there are no children
            if children.isEmpty, let text = innerText, !text.isEmpty {
                result += text
            }
            
            for child in children {
                result += "\n" + child.toRawText(indent: indent + 1)
            }
            
            if !children.isEmpty {
                result += "\n" + indentString
            }
            result += "</\(tag.lowercased())>"
        }
        
        return result
    }
}

class WebViewModel: ObservableObject {
    var webView: WKWebView?
    
    init() {}
    
    @MainActor
    func fetchWebStorage() async -> [WebStorageItem] {
        guard let webView = webView else { return [] }
        
        var allItems: [WebStorageItem] = []
        
        // Fetch localStorage
        let localStorageScript = """
        (function() {
            return Object.entries(localStorage);
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
            print("Error fetching localStorage: \(error)")
        }
        
        // Fetch sessionStorage
        let sessionStorageScript = """
        (function() {
            return Object.entries(sessionStorage);
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
            print("Error fetching sessionStorage: \(error)")
        }
        
        // Fetch cookies
        let cookieScript = "document.cookie;"
        
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
            print("Error fetching cookies: \(error)")
        }
        
        return allItems
    }
    
    @MainActor
    func fetchDOMTree() async -> DOMNode? {
        guard let webView = webView else { return nil }
        
        let script = """
        (function() {
            function getDomTree(element) {
                // Get direct text content (not from children)
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
            print("Error fetching DOM: \(error)")
        }
        return nil
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var consoleLogs: [ConsoleMessage]
    let viewModel: WebViewModel
    
    init(url: URL, consoleLogs: Binding<[ConsoleMessage]>, viewModel: WebViewModel) {
        self.url = url
        self._consoleLogs = consoleLogs
        self.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Inject console override script
        let consoleScript = """
        (function() {
            const methods = ['log', 'warn', 'error', 'info', 'debug'];
            methods.forEach((method) => {
                const original = console[method];
                console[method] = function(...args) {
                    window.webkit.messageHandlers.console.postMessage({
                        method: method,
                        args: args
                    });
                    original.apply(console, args);
                };
            });
        })();
        """
        
        let script = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
        
        // Add message handler
        let handler = ConsoleMessageHandler { message in
            DispatchQueue.main.async {
                self.consoleLogs.append(message)
            }
        }
        configuration.userContentController.add(handler, name: "console")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        viewModel.webView = webView
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
    
    class Coordinator: NSObject {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}
