import Foundation
import WebKit

@MainActor
public class ScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    let handlerName: String
    weak var originalHandler: WKScriptMessageHandler?
    weak var eventsViewModel: EventsViewModel?
    
    public init(handlerName: String, originalHandler: WKScriptMessageHandler? = nil, eventsViewModel: EventsViewModel? = nil) {
        self.handlerName = handlerName
        self.originalHandler = originalHandler
        self.eventsViewModel = eventsViewModel
        super.init()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let event = WKWebViewEvent(
            type: .scriptMessage,
            method: handlerName,
            details: [
                "name": message.name,
                "body": String(describing: message.body),
                "frameInfo": message.frameInfo.request.url?.absoluteString ?? "unknown"
            ]
        )
        eventsViewModel?.addEvent(event)
        
        originalHandler?.userContentController(userContentController, didReceive: message)
    }
}