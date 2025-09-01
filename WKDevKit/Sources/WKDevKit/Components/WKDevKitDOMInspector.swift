//
//  WKDevKitDOMInspector.swift
//  WKDevKit
//
//  Standalone DOM inspector component
//

import SwiftUI

#if os(iOS)
/// Standalone DOM inspector view
@available(iOS 15.0, *)
public struct WKDevKitDOMInspector: View {
    public let rootNode: DOMNode?
    @State private var searchText = ""
    @State private var expandedNodes = Set<UUID>()
    @State private var showRawView = false
    
    public init(rootNode: DOMNode?) {
        self.rootNode = rootNode
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search bar and view toggle
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search DOM (tag, id, class, text)...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Picker("View", selection: $showRawView) {
                    Text("Tree").tag(false)
                    Text("Raw").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            .padding()
            
            Divider()
            
            // Content
            if let rootNode = rootNode {
                if showRawView {
                    ScrollView {
                        Text(rootNode.toRawText())
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            WKDevKitDOMNodeView(
                                node: rootNode,
                                searchText: searchText,
                                expandedNodes: $expandedNodes,
                                level: 0
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("No DOM tree available")
                        .foregroundColor(.secondary)
                    Text("Refresh to load DOM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
}

@available(iOS 15.0, *)
private struct WKDevKitDOMNodeView: View {
    let node: DOMNode
    let searchText: String
    @Binding var expandedNodes: Set<UUID>
    let level: Int
    
    @State private var isExpanded: Bool = false
    
    private var matchesSearch: Bool {
        guard searchText.count >= 2 else { return true }
        
        return node.tag.localizedCaseInsensitiveContains(searchText) ||
               node.idAttr.localizedCaseInsensitiveContains(searchText) ||
               node.className.localizedCaseInsensitiveContains(searchText) ||
               (node.innerText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               node.children.contains { childMatches($0) }
    }
    
    private func childMatches(_ child: DOMNode) -> Bool {
        guard searchText.count >= 2 else { return true }
        
        return child.tag.localizedCaseInsensitiveContains(searchText) ||
               child.idAttr.localizedCaseInsensitiveContains(searchText) ||
               child.className.localizedCaseInsensitiveContains(searchText) ||
               (child.innerText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               child.children.contains { childMatches($0) }
    }
    
    private func highlightedText(_ text: String) -> AttributedString {
        guard searchText.count >= 2 else {
            return AttributedString(text)
        }
        
        var attributed = AttributedString(text)
        
        if let range = text.range(of: searchText, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            let startIndex = attributed.index(attributed.startIndex, offsetByCharacters: nsRange.location)
            let endIndex = attributed.index(startIndex, offsetByCharacters: nsRange.length)
#if os(iOS)
            attributed[startIndex..<endIndex].backgroundColor = .yellow.opacity(0.3)
            #endif
        }
        
        return attributed
    }
    
    var body: some View {
        if searchText.count < 2 || matchesSearch {
            VStack(alignment: .leading, spacing: 2) {
                // Node header
                HStack(spacing: 4) {
                    if !node.children.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                                if isExpanded {
                                    expandedNodes.insert(node.id)
                                } else {
                                    expandedNodes.remove(node.id)
                                }
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Spacer()
                            .frame(width: 16)
                    }
                    
                    HStack(spacing: 2) {
                        Text("<")
                            .foregroundColor(.secondary)
                        
                        Text(highlightedText(node.tag.lowercased()))
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        if !node.idAttr.isEmpty {
                            Text(" id=\"")
                                .foregroundColor(.secondary)
                            Text(highlightedText(node.idAttr))
                                .foregroundColor(.green)
                            Text("\"")
                                .foregroundColor(.secondary)
                        }
                        
                        if !node.className.isEmpty {
                            Text(" class=\"")
                                .foregroundColor(.secondary)
                            Text(highlightedText(node.className))
                                .foregroundColor(.orange)
                            Text("\"")
                                .foregroundColor(.secondary)
                        }
                        
                        Text(">")
                            .foregroundColor(.secondary)
                    }
                    .font(.system(.caption, design: .monospaced))
                    
                    Spacer()
                }
                .padding(.leading, CGFloat(level * 16))
                
                // Inner text (if no children)
                if node.children.isEmpty, let innerText = node.innerText, !innerText.isEmpty {
                    Text(highlightedText(innerText))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(3)
                        .padding(.leading, CGFloat((level + 1) * 16 + 16))
                }
                
                // Children
                if isExpanded || (searchText.count >= 2 && node.children.contains { childMatches($0) }) {
                    ForEach(node.children) { child in
                        WKDevKitDOMNodeView(
                            node: child,
                            searchText: searchText,
                            expandedNodes: $expandedNodes,
                            level: level + 1
                        )
                    }
                    
                    // Closing tag
                    HStack(spacing: 2) {
                        Text("</")
                            .foregroundColor(.secondary)
                        Text(node.tag.lowercased())
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        Text(">")
                            .foregroundColor(.secondary)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(.leading, CGFloat(level * 16))
                }
            }
            .onAppear {
                if expandedNodes.contains(node.id) {
                    isExpanded = true
                }
                
                // Auto-expand if searching and has matching children
                if searchText.count >= 2 && node.children.contains(where: childMatches) {
                    isExpanded = true
                    expandedNodes.insert(node.id)
                }
            }
        }
    }
}#endif
