//
//  WKDevKitEventsView.swift
//  WKDevKit
//
//  Public-facing events view component for standalone use
//

import SwiftUI

#if os(iOS)
/// A standalone SwiftUI view for displaying captured WebView events

public struct WKDevKitEventsView: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    
    public init(eventsViewModel: EventsViewModel) {
        self.eventsViewModel = eventsViewModel
    }
    
    public var body: some View {
        WKWebViewEventsView(eventsViewModel: eventsViewModel)
    }
}

/// A convenience view that can be initialized with a debugger

public struct WKDevKitEventsPanel: View {
    private let debugger: WKDevKitDebugger
    
    public init(debugger: WKDevKitDebugger) {
        self.debugger = debugger
    }
    
    public var body: some View {
        WKWebViewEventsView(eventsViewModel: debugger.eventsViewModel)
    }
}
#endif