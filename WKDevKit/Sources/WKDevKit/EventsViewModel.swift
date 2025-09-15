import Foundation
import SwiftUI
import Combine

#if os(iOS)
@MainActor
public class EventsViewModel: ObservableObject {
    @Published public var events: [WKWebViewEvent] = []
    @Published public var filteredEvents: [WKWebViewEvent] = []
    @Published public var searchText: String = "" {
        didSet {
            filterEvents()
        }
    }
    @Published public var selectedEventTypes: Set<WKWebViewEventType> = Set(WKWebViewEventType.allCases) {
        didSet {
            filterEvents()
        }
    }
    @Published public var isPaused: Bool = false
    @Published public var autoScroll: Bool = true
    
    private let maxEvents = 1000
    private var pausedEvents: [WKWebViewEvent] = []
    
    public init() {
        filterEvents()
    }
    
    public func addEvent(_ event: WKWebViewEvent) {
        if isPaused {
            pausedEvents.append(event)
        } else {
            events.append(event)
            
            if events.count > maxEvents {
                events.removeFirst(events.count - maxEvents)
            }
            
            filterEvents()
        }
    }
    
    public func clearEvents() {
        events.removeAll()
        pausedEvents.removeAll()
        filteredEvents.removeAll()
    }
    
    public func togglePause() {
        isPaused.toggle()
        
        if !isPaused && !pausedEvents.isEmpty {
            events.append(contentsOf: pausedEvents)
            pausedEvents.removeAll()
            
            if events.count > maxEvents {
                events.removeFirst(events.count - maxEvents)
            }
            
            filterEvents()
        }
    }
    
    public func toggleEventType(_ type: WKWebViewEventType) {
        if selectedEventTypes.contains(type) {
            selectedEventTypes.remove(type)
        } else {
            selectedEventTypes.insert(type)
        }
    }
    
    public func exportEvents() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var output = "WKWebView Events Export\n"
        output += "Generated: \(formatter.string(from: Date()))\n"
        output += "Total Events: \(filteredEvents.count)\n"
        output += String(repeating: "=", count: 80) + "\n\n"
        
        for event in filteredEvents {
            output += "[\(event.formattedTimestamp)] \(event.type.rawValue) - \(event.method)\n"
            if !event.rawDescription.isEmpty {
                let lines = event.rawDescription.split(separator: "\n")
                for line in lines {
                    output += "  \(line)\n"
                }
            }
            output += "\n"
        }
        
        return output
    }
    
    private func filterEvents() {
        filteredEvents = events.filter { event in
            guard selectedEventTypes.contains(event.type) else { return false }
            
            if searchText.isEmpty {
                return true
            }
            
            let searchLower = searchText.lowercased()
            return event.method.lowercased().contains(searchLower) ||
                   event.rawDescription.lowercased().contains(searchLower) ||
                   event.type.rawValue.lowercased().contains(searchLower)
        }
    }
    
    public var eventTypeCounts: [WKWebViewEventType: Int] {
        var counts: [WKWebViewEventType: Int] = [:]
        for type in WKWebViewEventType.allCases {
            counts[type] = events.filter { $0.type == type }.count
        }
        return counts
    }
}
#endif