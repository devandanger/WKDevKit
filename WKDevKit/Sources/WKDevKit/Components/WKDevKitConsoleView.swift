//
//  WKDevKitConsoleView.swift
//  WKDevKit
//
//  Standalone console view component
//

import SwiftUI

#if os(iOS)
/// Standalone console view that displays console messages

public struct WKDevKitConsoleView: View {
    public let messages: [ConsoleMessage]
    @State private var searchText = ""
    @State private var selectedMethod: String? = nil
    
    public init(messages: [ConsoleMessage]) {
        self.messages = messages
    }
    
    private var filteredMessages: [ConsoleMessage] {
        let methodFiltered = selectedMethod == nil ? messages : messages.filter { $0.method == selectedMethod }
        
        if searchText.isEmpty {
            return methodFiltered
        }
        
        return methodFiltered.filter {
            $0.args.localizedCaseInsensitiveContains(searchText) ||
            $0.method.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var availableMethods: [String] {
        Array(Set(messages.map { $0.method })).sorted()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search console logs...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Menu {
                    Button("All Methods") {
                        selectedMethod = nil
                    }
                    Divider()
                    ForEach(availableMethods, id: \.self) { method in
                        Button(method.capitalized) {
                            selectedMethod = method
                        }
                    }
                } label: {
                    Label(
                        selectedMethod?.capitalized ?? "All",
                        systemImage: "line.horizontal.3.decrease.circle"
                    )
                }
            }
            .padding()
            
            Divider()
            
            // Console messages
            if filteredMessages.isEmpty {
                VStack {
                    Spacer()
                    if messages.isEmpty {
                        Text("No console logs yet")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No matching console logs")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredMessages) { message in
                                ConsoleMessageRow(message: message)
                                    .id(message.id)
                                Divider()
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessage = filteredMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: filteredMessages.count) { _ in
                        if let lastMessage = filteredMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}


private struct ConsoleMessageRow: View {
    let message: ConsoleMessage
    
    private var methodColor: Color {
        switch message.method {
        case "error":
            return .red
        case "warn":
            return .orange
        case "info":
            return .blue
        case "debug":
            return .purple
        default:
            return .primary
        }
    }
    
    private var methodIcon: String {
        switch message.method {
        case "error":
            return "xmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "info":
            return "info.circle.fill"
        case "debug":
            return "ant.fill"
        default:
            return "text.bubble.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: methodIcon)
                .foregroundColor(methodColor)
                .font(.footnote)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.args)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                
                Text(message.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
#endif