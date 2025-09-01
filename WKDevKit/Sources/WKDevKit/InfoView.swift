//
//  InfoView.swift
//  InAppWebViewInspector
//
//  Created on 8/31/25.
//

import SwiftUI

struct InfoView: View {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current URL")
                    .font(.headline)
                Text(url.absoluteString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}