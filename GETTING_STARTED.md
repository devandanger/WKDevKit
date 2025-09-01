# Getting Started with WKDevKit

A quick guide to integrating WKDevKit into your iOS app for debugging web content.

## Installation

### Swift Package Manager

Add WKDevKit to your project dependencies:

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/devandanger/WKDevKit`
3. Select the version rule and click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/devandanger/WKDevKit", from: "0.1.0")
]
```

## Basic Usage

### Simple Integration

The easiest way to use WKDevKit is with the `EmbeddedWebViewScreen`:

```swift
import SwiftUI
import WKDevKit

struct ContentView: View {
    var body: some View {
        EmbeddedWebViewScreen(urlString: "https://www.google.com")
    }
}
```

That's it! This gives you a fully-featured web view with debugging capabilities.

### Navigation Integration

Embed the web view in your app's navigation flow:

```swift
import SwiftUI
import WKDevKit

struct MyApp: View {
    @State private var showWebView = false
    @State private var urlToLoad = "https://www.google.com"
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Open Web Debugger") {
                    showWebView = true
                }
            }
            .sheet(isPresented: $showWebView) {
                EmbeddedWebViewScreen(urlString: urlToLoad)
            }
        }
    }
}
```

### Dynamic URL Loading

Load different URLs based on user input or app state:

```swift
struct WebDebuggerView: View {
    @State private var urlInput = ""
    @State private var showWebView = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter URL", text: $urlInput)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.URL)
            
            Button("Debug This URL") {
                showWebView = true
            }
            .disabled(urlInput.isEmpty)
        }
        .padding()
        .fullScreenCover(isPresented: $showWebView) {
            EmbeddedWebViewScreen(urlString: urlInput)
        }
    }
}
```

## Using the Debug Panel

Once your web view is loaded, tap the **Debug** button in the navigation bar to access:

### Console Tab
Monitor JavaScript console output in real-time:
- View `console.log`, `console.warn`, `console.error`, `console.info`, and `console.debug` messages
- Color-coded messages for easy identification
- Timestamps for each log entry
- Copy log messages for analysis

### DOM Inspector Tab
Explore the page's DOM structure:
- **Tree View**: Navigate the DOM hierarchy with expandable nodes
- **Raw HTML**: View the complete HTML source
- **Search**: Find elements by tag, ID, class, or text content (min 2 characters)
- **Copy**: Select and copy any text for external analysis

### Storage Tab
Inspect web storage data:
- **Local Storage**: Persistent key-value pairs
- **Session Storage**: Session-scoped storage
- **Cookies**: Document cookies with parsed key-value pairs
- Expandable values for long content
- Auto-refresh when switching tabs

### Info Tab
View current page information:
- Current URL with copy capability

## Common Use Cases

### 1. Debugging JavaScript Errors

```swift
// Your web content
let htmlContent = """
<html>
<script>
    console.log("Page loaded");
    console.error("Something went wrong!");
    
    // This will appear in the Console tab
    try {
        someFunction();
    } catch(e) {
        console.error("Error:", e.message);
    }
</script>
</html>
"""

// Load it in WKDevKit
EmbeddedWebViewScreen(urlString: "data:text/html,\(htmlContent)")
```

### 2. Inspecting Local Storage

Perfect for debugging web apps that use browser storage:

```swift
// Monitor storage changes in your web app
EmbeddedWebViewScreen(urlString: "https://www.google.com")
// Navigate to Debug > Storage tab to see localStorage/sessionStorage
```

### 3. Development Environment Switching

```swift
struct DevelopmentView: View {
    @AppStorage("environment") var environment = "production"
    
    var urlForEnvironment: String {
        switch environment {
        case "local": return "http://localhost:3000"
        case "staging": return "https://staging.yourapp.com"
        default: return "https://yourapp.com"
        }
    }
    
    var body: some View {
        EmbeddedWebViewScreen(urlString: urlForEnvironment)
    }
}
```

## Working with the API

### Available Data Models

```swift
// Console message structure
struct ConsoleMessage {
    let method: String      // "log", "warn", "error", "info", "debug"
    let args: String        // The logged message
    let timestamp: Date     // When it was logged
}

// Storage item structure
struct WebStorageItem {
    let key: String
    let value: String
    let type: WebStorageType  // .localStorage, .sessionStorage, or .cookies
}

// DOM node structure
struct DOMNode {
    let tag: String         // HTML tag name
    let idAttr: String      // Element ID
    let className: String   // CSS classes
    let innerText: String?  // Text content
    let children: [DOMNode] // Child nodes
}
```

## Tips and Best Practices

### Performance Considerations

1. **Large DOMs**: The DOM inspector recursively traverses the entire page structure. For very large pages, this might take a moment.

2. **Console Logging**: All console messages are captured and stored. For apps with heavy logging, consider clearing the console periodically.

3. **Storage Inspection**: Storage data is fetched on-demand when you switch to the Storage tab, ensuring fresh data.

### Security Notes

- WKDevKit is designed for **development and debugging** purposes
- Don't ship to production with debug features exposed to end users
- Consider using conditional compilation:

```swift
struct MyWebView: View {
    var body: some View {
        #if DEBUG
        EmbeddedWebViewScreen(urlString: "https://example.com")
        #else
        RegularWebView(urlString: "https://example.com")
        #endif
    }
}
```

### Troubleshooting

**Invalid URL Error:**
- Ensure your URL string is properly formatted
- Include the protocol (`https://` or `http://`)
- For local development, use `http://localhost:PORT`

**Console logs not appearing:**
- Verify JavaScript is enabled in your web content
- Check that your web page is actually calling console methods
- Note that only `log`, `warn`, `error`, `info`, and `debug` are captured

**Storage appears empty:**
- Ensure the web page has actually set storage values
- Switch tabs to trigger a refresh of storage data
- Check that cookies are enabled for the domain

## Example App

Check out the included `ExampleApp` project for a complete implementation:

```bash
cd ExampleApp
open ExampleApp.xcodeproj
```

The example demonstrates:
- URL input and validation
- Different web view launch modes
- Full debug panel integration
- Error handling

## Requirements

- iOS 15.0+ (package requirement)
- iOS 18.5+ (for example app)
- Xcode 15.0+
- Swift 5.0+

## Next Steps

- Explore the [PROJECT_PLAN.md](./PROJECT_PLAN.md) for upcoming features
- Check the [README.md](./README.md) for detailed feature documentation
- Submit issues or feature requests on GitHub

## Support

For questions, bug reports, or feature requests, please open an issue on the GitHub repository.