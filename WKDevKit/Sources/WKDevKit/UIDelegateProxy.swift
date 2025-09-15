import Foundation
import WebKit

@MainActor
public class UIDelegateProxy: NSObject, WKUIDelegate {
    weak var originalDelegate: WKUIDelegate?
    weak var eventsViewModel: EventsViewModel?
    
    public init(originalDelegate: WKUIDelegate? = nil, eventsViewModel: EventsViewModel? = nil) {
        self.originalDelegate = originalDelegate
        self.eventsViewModel = eventsViewModel
        super.init()
    }
    
    private func logEvent(method: UIDelegateMethod, details: [String: Any]) {
        let event = WKWebViewEvent(
            type: .uiDelegate,
            method: method.rawValue,
            details: details
        )
        eventsViewModel?.addEvent(event)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        logEvent(
            method: .createWebViewWithConfiguration,
            details: [
                "url": navigationAction.request.url as Any,
                "navigationType": navigationAction.navigationType.rawValue,
                "targetFrame": navigationAction.targetFrame?.isMainFrame ?? false
            ]
        )
        
        return originalDelegate?.webView?(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        logEvent(
            method: .webViewDidClose,
            details: ["url": webView.url as Any]
        )
        
        originalDelegate?.webViewDidClose?(webView)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        logEvent(
            method: .runJavaScriptAlertPanelWithMessage,
            details: [
                "message": message,
                "sourceURL": frame.request.url as Any,
                "isMainFrame": frame.isMainFrame
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        logEvent(
            method: .runJavaScriptConfirmPanelWithMessage,
            details: [
                "message": message,
                "sourceURL": frame.request.url as Any,
                "isMainFrame": frame.isMainFrame
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        } else {
            completionHandler(false)
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        logEvent(
            method: .runJavaScriptTextInputPanelWithPrompt,
            details: [
                "prompt": prompt,
                "defaultText": defaultText as Any,
                "sourceURL": frame.request.url as Any,
                "isMainFrame": frame.isMainFrame
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
        } else {
            completionHandler(nil)
        }
    }
    
    #if os(iOS)
    
    public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        logEvent(
            method: .requestMediaCapturePermission,
            details: [
                "origin": "\(origin.protocol)://\(origin.host):\(origin.port)",
                "type": type.rawValue,
                "sourceURL": frame.request.url as Any
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, requestMediaCapturePermissionFor: origin, initiatedByFrame: frame, type: type, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.deny)
        }
    }
    #endif
    
    #if os(iOS)
    
    public func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        logEvent(
            method: .requestDeviceOrientationAndMotionPermission,
            details: [
                "origin": "\(origin.protocol)://\(origin.host):\(origin.port)",
                "sourceURL": frame.request.url as Any
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, requestDeviceOrientationAndMotionPermissionFor: origin, initiatedByFrame: frame, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.deny)
        }
    }
    #endif
}