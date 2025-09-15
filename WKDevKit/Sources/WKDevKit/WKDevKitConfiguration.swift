//
//  WKDevKitConfiguration.swift
//  WKDevKit
//
//  Configuration for WKDevKit debugging features
//

import Foundation

/// Configuration for WKDevKit debugging features
public struct WKDevKitConfiguration: Sendable {
    /// Enable console logging interception
    public var enableConsoleLogging: Bool = true
    
    /// Enable DOM tree inspection
    public var enableDOMInspection: Bool = true
    
    /// Enable web storage inspection
    public var enableStorageInspection: Bool = true
    
    /// Enable web inspector (iOS 16.4+)
    public var enableWebInspector: Bool = true
    
    /// Enable event capture for all WebView delegates
    public var enableEventCapture: Bool = true
    
    /// Which storage types to inspect
    public var storageTypes: Set<WebStorageType> = [.localStorage, .sessionStorage, .cookies]
    
    /// Maximum number of console logs to keep in memory
    public var maxConsoleLogCount: Int = 1000
    
    /// Default configuration with all features enabled
    public static let `default` = WKDevKitConfiguration()
    
    /// Minimal configuration with only console logging
    public static let minimal = WKDevKitConfiguration(
        enableConsoleLogging: true,
        enableDOMInspection: false,
        enableStorageInspection: false,
        enableWebInspector: false,
        enableEventCapture: false
    )
    
    /// Configuration for production builds (all features disabled)
    public static let production = WKDevKitConfiguration(
        enableConsoleLogging: false,
        enableDOMInspection: false,
        enableStorageInspection: false,
        enableWebInspector: false,
        enableEventCapture: false
    )
    
    public init(
        enableConsoleLogging: Bool = true,
        enableDOMInspection: Bool = true,
        enableStorageInspection: Bool = true,
        enableWebInspector: Bool = true,
        enableEventCapture: Bool = true,
        storageTypes: Set<WebStorageType> = [.localStorage, .sessionStorage, .cookies],
        maxConsoleLogCount: Int = 1000
    ) {
        self.enableConsoleLogging = enableConsoleLogging
        self.enableDOMInspection = enableDOMInspection
        self.enableStorageInspection = enableStorageInspection
        self.enableWebInspector = enableWebInspector
        self.enableEventCapture = enableEventCapture
        self.storageTypes = storageTypes
        self.maxConsoleLogCount = maxConsoleLogCount
    }
    
    /// Builder for creating configurations
    public static func builder() -> Builder {
        return Builder()
    }
    
    /// Builder class for fluent configuration
    public class Builder {
        private var config = WKDevKitConfiguration()
        
        public init() {}
        
        @discardableResult
        public func withConsoleLogging(_ enabled: Bool) -> Builder {
            config.enableConsoleLogging = enabled
            return self
        }
        
        @discardableResult
        public func withDOMInspection(_ enabled: Bool) -> Builder {
            config.enableDOMInspection = enabled
            return self
        }
        
        @discardableResult
        public func withStorageInspection(_ enabled: Bool) -> Builder {
            config.enableStorageInspection = enabled
            return self
        }
        
        @discardableResult
        public func withWebInspector(_ enabled: Bool) -> Builder {
            config.enableWebInspector = enabled
            return self
        }
        
        @discardableResult
        public func withEventCapture(_ enabled: Bool) -> Builder {
            config.enableEventCapture = enabled
            return self
        }
        
        @discardableResult
        public func withStorageTypes(_ types: Set<WebStorageType>) -> Builder {
            config.storageTypes = types
            return self
        }
        
        @discardableResult
        public func withMaxConsoleLogCount(_ count: Int) -> Builder {
            config.maxConsoleLogCount = count
            return self
        }
        
        public func build() -> WKDevKitConfiguration {
            return config
        }
    }
}