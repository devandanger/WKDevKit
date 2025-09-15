//
//  WKDevKitDebuggable.swift
//  WKDevKit
//
//  Protocol-based debugging interface
//

import WebKit

#if os(iOS)
/// Protocol that can be adopted by any WKWebView to enable debugging

@MainActor
public protocol WKDevKitDebuggable: AnyObject {
    /// The debugger instance attached to this WebView
    var devKitDebugger: WKDevKitDebugger? { get }
    
    /// Enable debugging with the specified configuration
    /// - Parameter configuration: Configuration for debugging features
    /// - Returns: The debugger instance
    @discardableResult
    func enableDebugging(configuration: WKDevKitConfiguration) -> WKDevKitDebugger
    
    /// Disable debugging and clean up resources
    func disableDebugging()
}

/// Default implementation for WKWebView

extension WKWebView: WKDevKitDebuggable {
    public func enableDebugging(configuration: WKDevKitConfiguration = .default) -> WKDevKitDebugger {
        return addDevKitDebugging(configuration: configuration)
    }
    
    public func disableDebugging() {
        removeDevKitDebugging()
    }
}

/// Convenience protocol for custom WebView implementations

public protocol CustomWebViewDebuggable: WKDevKitDebuggable {
    /// The underlying WKWebView instance
    var webView: WKWebView { get }
}

/// Default implementation for custom WebView wrappers

extension CustomWebViewDebuggable {
    public var devKitDebugger: WKDevKitDebugger? {
        return webView.devKitDebugger
    }
    
    @discardableResult
    public func enableDebugging(configuration: WKDevKitConfiguration = .default) -> WKDevKitDebugger {
        return webView.enableDebugging(configuration: configuration)
    }
    
    public func disableDebugging() {
        webView.disableDebugging()
    }
}
#endif