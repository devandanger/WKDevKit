import SwiftUI
import WebKit

#if os(iOS)
import UIKit
#endif

#if os(iOS)

public struct WKWebViewEventsView: View {
    @ObservedObject var eventsViewModel: EventsViewModel
    @State private var selectedEvent: WKWebViewEvent?
    @State private var showExportSheet = false
    @State private var exportedText = ""
    
    public init(eventsViewModel: EventsViewModel) {
        self.eventsViewModel = eventsViewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            filterView
            Divider()
            
            if eventsViewModel.filteredEvents.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("WebView Events")
                .font(.headline)
            
            Spacer()
            
            Text("\(eventsViewModel.filteredEvents.count) events")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                eventsViewModel.togglePause()
            }) {
                Image(systemName: eventsViewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(eventsViewModel.isPaused ? .green : .orange)
            }
            
            Button(action: {
                eventsViewModel.autoScroll.toggle()
            }) {
                Image(systemName: "arrow.down.to.line")
                    .foregroundColor(eventsViewModel.autoScroll ? .blue : .gray)
            }
            .help("Auto-scroll to latest event")
            
            Button(action: {
                exportedText = eventsViewModel.exportEvents()
                showExportSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
            }
            
            Button(action: {
                eventsViewModel.clearEvents()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
    }
    
    private var filterView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search events...", text: $eventsViewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !eventsViewModel.searchText.isEmpty {
                    Button(action: {
                        eventsViewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(WKWebViewEventType.allCases, id: \.self) { type in
                    EventTypeFilterChip(
                        type: type,
                        count: eventsViewModel.eventTypeCounts[type] ?? 0,
                        isSelected: eventsViewModel.selectedEventTypes.contains(type),
                        action: {
                            eventsViewModel.toggleEventType(type)
                        }
                    )
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private var eventsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(eventsViewModel.filteredEvents) { event in
                        EventRowView(event: event, isExpanded: selectedEvent?.id == event.id)
                            .id(event.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedEvent?.id == event.id {
                                        selectedEvent = nil
                                    } else {
                                        selectedEvent = event
                                    }
                                }
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: eventsViewModel.filteredEvents.count) { _ in
                if eventsViewModel.autoScroll,
                   let lastEvent = eventsViewModel.filteredEvents.last {
                    withAnimation {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No events captured")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if eventsViewModel.isPaused {
                Label("Recording is paused", systemImage: "pause.circle.fill")
                    .foregroundColor(.orange)
            } else {
                Text("Navigate in the WebView to see events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    private var exportSheet: some View {
        NavigationView {
            VStack {
                TextEditor(text: .constant(exportedText))
                    .font(.system(.body, design: .monospaced))
                
                HStack {
                    Button("Copy to Clipboard") {
                        UIPasteboard.general.string = exportedText
                        showExportSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Done") {
                        showExportSheet = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Export Events")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct EventTypeFilterChip: View {
    let type: WKWebViewEventType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color(colorName).opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? Color(colorName) : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(colorName) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch type {
        case .navigation:
            return "arrow.right.circle"
        case .scriptMessage:
            return "message.circle"
        case .uiDelegate:
            return "uiwindow.split.2x1"
        }
    }
    
    private var colorName: String {
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


struct EventRowView: View {
    let event: WKWebViewEvent
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: event.typeIcon)
                    .foregroundColor(Color(event.typeColor))
                    .font(.caption)
                
                Text(event.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(event.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(event.typeColor))
                
                Text(event.method)
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                if isExpanded {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            if isExpanded && !event.rawDescription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    Text("Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(event.rawDescription)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
#endif