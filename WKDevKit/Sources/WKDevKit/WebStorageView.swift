//
//  WebStorageView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct WebStorageView: View {
    let items: [WebStorageItem]
    let isLoading: Bool
    let onRefresh: () -> Void
    
    init(items: [WebStorageItem], isLoading: Bool, onRefresh: @escaping () -> Void) {
        self.items = items
        self.isLoading = isLoading
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading storage...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else if items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "internaldrive")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No storage items")
                        .foregroundColor(.secondary)
                    Button("Load Storage", action: onRefresh)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(WebStorageType.allCases, id: \.self) { storageType in
                            let sectionItems = items.filter { $0.type == storageType }
                            if !sectionItems.isEmpty {
                                WebStorageSection(storageType: storageType, items: sectionItems)
                            }
                        }
                    }
                }
                .background(Color.white)
            }
        }
        .onAppear {
            if items.isEmpty && !isLoading {
                onRefresh()
            }
        }
    }
}

struct WebStorageSection: View {
    let storageType: WebStorageType
    let items: [WebStorageItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text(storageType.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("(\(items.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            // Section Items
            ForEach(items) { item in
                WebStorageItemRow(item: item)
            }
        }
    }
}

struct WebStorageItemRow: View {
    let item: WebStorageItem
    @State private var isExpanded = false
    
    var truncatedValue: String {
        let maxLength = 100
        if item.value.count > maxLength {
            return String(item.value.prefix(maxLength)) + "..."
        }
        return item.value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Key
                    Text(item.key)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                    
                    // Value (truncated or full)
                    Text(isExpanded ? item.value : truncatedValue)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if item.value.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}
