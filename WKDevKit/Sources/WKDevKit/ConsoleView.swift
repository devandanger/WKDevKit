//
//  ConsoleView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct ConsoleView: View {
    let logs: [ConsoleMessage]
    
    init(logs: [ConsoleMessage]) {
        self.logs = logs
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if logs.isEmpty {
                        Text("No console logs yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(logs) { log in
                            ConsoleLogRow(log: log)
                                .id(log.id)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onChange(of: logs.count) { _ in
                if let lastLog = logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.white)
    }
}

struct ConsoleLogRow: View {
    let log: ConsoleMessage
    
    init(log: ConsoleMessage) {
        self.log = log
    }
    
    var logColor: Color {
        switch log.method {
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
    
    var logIcon: String {
        switch log.method {
        case "error":
            return "xmark.circle.fill"
        case "warn":
            return "exclamationmark.triangle.fill"
        case "info":
            return "info.circle.fill"
        case "debug":
            return "ant.fill"
        default:
            return "chevron.right.circle.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: logIcon)
                .foregroundColor(logColor)
                .font(.caption)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.args)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(logColor)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(log.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}