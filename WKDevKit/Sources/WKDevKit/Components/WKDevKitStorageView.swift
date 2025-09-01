//
//  WKDevKitStorageView.swift
//  WKDevKit
//
//  Standalone web storage viewer component
//

import SwiftUI

#if os(iOS)
/// Standalone web storage viewer
@available(iOS 15.0, *)
public struct WKDevKitStorageView: View {
    public let items: [WebStorageItem]
    @State private var searchText = ""
    @State private var selectedType: WebStorageType?
    
    public init(items: [WebStorageItem]) {
        self.items = items
    }
    
    private var filteredItems: [WebStorageItem] {
        let typeFiltered = selectedType == nil ? items : items.filter { $0.type == selectedType }
        
        if searchText.isEmpty {
            return typeFiltered
        }
        
        return typeFiltered.filter {
            $0.key.localizedCaseInsensitiveContains(searchText) ||
            $0.value.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var availableTypes: [WebStorageType] {
        Array(Set(items.map { $0.type }))
    }
    
    private var groupedItems: [WebStorageType: [WebStorageItem]] {
        Dictionary(grouping: filteredItems, by: { $0.type })
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search storage items...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                if !availableTypes.isEmpty {
                    Menu {
                        Button("All Types") {
                            selectedType = nil
                        }
                        Divider()
                        ForEach(availableTypes, id: \.self) { type in
                            Button(type.rawValue) {
                                selectedType = type
                            }
                        }
                    } label: {
                        Label(
                            selectedType?.rawValue ?? "All",
                            systemImage: "folder"
                        )
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Storage items
            if filteredItems.isEmpty {
                VStack {
                    Spacer()
                    if items.isEmpty {
                        Text("No storage data available")
                            .foregroundColor(.secondary)
                        Text("Refresh to load storage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No matching storage items")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(WebStorageType.allCases, id: \.self) { type in
                        if let typeItems = groupedItems[type], !typeItems.isEmpty {
                            Section(header: StorageSectionHeader(type: type, count: typeItems.count)) {
                                ForEach(typeItems) { item in
                                    StorageItemRow(item: item, searchText: searchText)
                                }
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(InsetGroupedListStyle())
                #else
                .listStyle(PlainListStyle())
                #endif
            }
        }
    }
}

@available(iOS 15.0, *)
private struct StorageSectionHeader: View {
    let type: WebStorageType
    let count: Int
    
    private var icon: String {
        switch type {
        case .localStorage:
            return "externaldrive"
        case .sessionStorage:
            return "clock"
        case .cookies:
            return "network"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(type.rawValue)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

@available(iOS 15.0, *)
private struct StorageItemRow: View {
    let item: WebStorageItem
    let searchText: String
    @State private var isExpanded = false
    
    private func highlightedText(_ text: String) -> AttributedString {
        guard searchText.count >= 2 else {
            return AttributedString(text)
        }
        
        var attributed = AttributedString(text)
        
        if let range = text.range(of: searchText, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            let startIndex = attributed.index(attributed.startIndex, offsetByCharacters: nsRange.location)
            let endIndex = attributed.index(startIndex, offsetByCharacters: nsRange.length)
            attributed[startIndex..<endIndex].backgroundColor = .yellow.opacity(0.3)
        }
        
        return attributed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(highlightedText(item.key))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    
                    if !isExpanded {
                        Text(item.value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(highlightedText(item.value))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}#endif
