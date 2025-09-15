import Foundation
import WebKit

@MainActor
public class NavigationDelegateProxy: NSObject, WKNavigationDelegate {
    weak var originalDelegate: WKNavigationDelegate?
    weak var eventsViewModel: EventsViewModel?
    
    public init(originalDelegate: WKNavigationDelegate? = nil, eventsViewModel: EventsViewModel? = nil) {
        self.originalDelegate = originalDelegate
        self.eventsViewModel = eventsViewModel
        super.init()
    }
    
    private func logEvent(method: NavigationEventMethod, details: [String: Any]) {
        let event = WKWebViewEvent(
            type: .navigation,
            method: method.rawValue,
            details: details
        )
        eventsViewModel?.addEvent(event)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        logEvent(
            method: .decidePolicyForNavigationAction,
            details: [
                "url": navigationAction.request.url as Any,
                "navigationType": navigationAction.navigationType.rawValue,
                "targetFrame": navigationAction.targetFrame?.isMainFrame ?? false
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var details: [String: Any] = [
            "url": navigationResponse.response.url as Any,
            "mimeType": navigationResponse.response.mimeType as Any
        ]
        
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            details["statusCode"] = httpResponse.statusCode
        }
        
        logEvent(method: .decidePolicyForNavigationResponse, details: details)
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        logEvent(
            method: .didStartProvisionalNavigation,
            details: ["url": webView.url as Any]
        )
        
        originalDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        logEvent(
            method: .didReceiveServerRedirectForProvisionalNavigation,
            details: ["url": webView.url as Any]
        )
        
        originalDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logEvent(
            method: .didFailProvisionalNavigation,
            details: [
                "url": webView.url as Any,
                "error": error.localizedDescription
            ]
        )
        
        originalDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logEvent(
            method: .didCommitNavigation,
            details: ["url": webView.url as Any]
        )
        
        originalDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logEvent(
            method: .didFinishNavigation,
            details: [
                "url": webView.url as Any,
                "title": webView.title as Any
            ]
        )
        
        originalDelegate?.webView?(webView, didFinish: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logEvent(
            method: .didFailNavigation,
            details: [
                "url": webView.url as Any,
                "error": error.localizedDescription
            ]
        )
        
        originalDelegate?.webView?(webView, didFail: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        logEvent(
            method: .didReceiveAuthenticationChallenge,
            details: [
                "protectionSpace": challenge.protectionSpace.host,
                "authenticationMethod": challenge.protectionSpace.authenticationMethod
            ]
        )
        
        if let originalDelegate = originalDelegate {
            originalDelegate.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        logEvent(
            method: .webContentProcessDidTerminate,
            details: ["url": webView.url as Any]
        )
        
        originalDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }
}