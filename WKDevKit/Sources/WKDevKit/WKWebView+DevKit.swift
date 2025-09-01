//
//  WKWebView+DevKit.swift
//  WKDevKit
//
//  Extension to add debugging capabilities to any WKWebView
//

import WebKit
import ObjectiveC

#if os(iOS)
@MainActor
private enum AssociationKey {
    static let debugger = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
}

@available(iOS 15.0, *)
public extension WKWebView {
    /// Add WKDevKit debugging capabilities to this WebView
    /// - Parameter configuration: Configuration for debugging features
    /// - Returns: The debugger instance attached to this WebView
    @discardableResult
    func addDevKitDebugging(configuration: WKDevKitConfiguration = .default) -> WKDevKitDebugger {
        // Check if debugger already exists
        if let existingDebugger = devKitDebugger {
            return existingDebugger
        }
        
        // Create and attach new debugger
        let debugger = WKDevKitDebugger(webView: self, configuration: configuration)
        
        // Store debugger as associated object
        objc_setAssociatedObject(
            self,
            AssociationKey.debugger,
            debugger,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        return debugger
    }
    
    /// The attached WKDevKit debugger, if any
    var devKitDebugger: WKDevKitDebugger? {
        return objc_getAssociatedObject(self, AssociationKey.debugger) as? WKDevKitDebugger
    }
    
    /// Remove WKDevKit debugging from this WebView
    func removeDevKitDebugging() {
        devKitDebugger?.cleanup()
        objc_setAssociatedObject(
            self,
            AssociationKey.debugger,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
#endif