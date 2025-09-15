import Foundation
import WebKit

public enum WKWebViewEventType: String, CaseIterable {
    case navigation = "Navigation"
    case scriptMessage = "Script Message"
    case uiDelegate = "UI Delegate"
}

public enum NavigationEventMethod: String {
    case decidePolicyForNavigationAction = "decidePolicyForNavigationAction"
    case decidePolicyForNavigationResponse = "decidePolicyForNavigationResponse"
    case didStartProvisionalNavigation = "didStartProvisionalNavigation"
    case didReceiveServerRedirectForProvisionalNavigation = "didReceiveServerRedirectForProvisionalNavigation"
    case didFailProvisionalNavigation = "didFailProvisionalNavigation"
    case didCommitNavigation = "didCommitNavigation"
    case didFinishNavigation = "didFinishNavigation"
    case didFailNavigation = "didFailNavigation"
    case didReceiveAuthenticationChallenge = "didReceiveAuthenticationChallenge"
    case webContentProcessDidTerminate = "webContentProcessDidTerminate"
}

public enum UIDelegateMethod: String {
    case createWebViewWithConfiguration = "createWebViewWithConfiguration"
    case webViewDidClose = "webViewDidClose"
    case runJavaScriptAlertPanelWithMessage = "runJavaScriptAlertPanelWithMessage"
    case runJavaScriptConfirmPanelWithMessage = "runJavaScriptConfirmPanelWithMessage"
    case runJavaScriptTextInputPanelWithPrompt = "runJavaScriptTextInputPanelWithPrompt"
    case decidePolicyForWindowFeatures = "decidePolicyForWindowFeatures"
    case contextMenuConfigurationForElement = "contextMenuConfigurationForElement"
    case contextMenuDidEndForElement = "contextMenuDidEndForElement"
    case contextMenuWillDisplayForElement = "contextMenuWillDisplayForElement"
    case showLockdownModeFirstUseMessage = "showLockdownModeFirstUseMessage"
    case requestMediaCapturePermission = "requestMediaCapturePermission"
    case requestDeviceOrientationAndMotionPermission = "requestDeviceOrientationAndMotionPermission"
}

public struct WKWebViewEvent: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let type: WKWebViewEventType
    public let method: String
    public let details: [String: Any]
    public let rawDescription: String
    
    public init(type: WKWebViewEventType, method: String, details: [String: Any]) {
        self.timestamp = Date()
        self.type = type
        self.method = method
        self.details = details
        self.rawDescription = Self.formatDetails(details)
    }
    
    private static func formatDetails(_ details: [String: Any]) -> String {
        var result = ""
        for (key, value) in details {
            if let url = value as? URL {
                result += "\(key): \(url.absoluteString)\n"
            } else if let error = value as? Error {
                result += "\(key): \(error.localizedDescription)\n"
            } else if let request = value as? URLRequest {
                result += "\(key): \(request.url?.absoluteString ?? "no URL")\n"
            } else if let response = value as? URLResponse {
                result += "\(key): \(response.url?.absoluteString ?? "no URL")\n"
            } else {
                result += "\(key): \(String(describing: value))\n"
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    public var typeIcon: String {
        switch type {
        case .navigation:
            return "arrow.right.circle"
        case .scriptMessage:
            return "message.circle"
        case .uiDelegate:
            return "uiwindow.split.2x1"
        }
    }
    
    public var typeColor: String {
        switch type {
        case .navigation:
            return "blue"
        case .scriptMessage:
            return "purple"
        case .uiDelegate:
            return "orange"
        }
    }
}