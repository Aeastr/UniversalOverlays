<div align="center">
  <img width="128" height="128" src="/resources/icon.png" alt="UniversalOverlays Icon">
  <h1><b>UniversalOverlays</b></h1>
  <p>
    Display SwiftUI and UIKit content above your entire app with configurable window levels.
  </p>
</div>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0+-F05138?logo=swift&logoColor=white" alt="Swift 6.0+"></a>
  <a href="https://developer.apple.com"><img src="https://img.shields.io/badge/iOS-17+-000000?logo=apple" alt="iOS 17+"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>


## Overview

Create always-on-top overlays for SwiftUI and UIKit with a simple API. Touches on empty/transparent areas automatically pass through to underlying windows.

- Simple `UniversalOverlay.show { }` API for SwiftUI and UIKit
- Configurable window levels (above status bar, alerts, or topmost)
- Auto-dismiss, animations, and runtime control
- Pass-through touch on empty areas—overlays don't block interaction


## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Aeastr/UniversalOverlays.git", from: "1.0.0")
]
```

```swift
import UniversalOverlays
```

Or in Xcode: **File > Add Packages…** and enter `https://github.com/Aeastr/UniversalOverlays`


## Usage

Touches on empty/transparent areas pass through to the app below. Touches on your overlay content (buttons, text, etc.) are handled normally.

### SwiftUI

```swift
let overlay = UniversalOverlay.show {
    VStack {
        HStack {
            Spacer()
            Text("60 FPS")
                .font(.caption.monospaced())
                .padding(6)
                .background(.black.opacity(0.7))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
        }
        Spacer()
    }
}

// Later, dismiss it
overlay?.dismiss()
```

### UIKit

```swift
let overlayVC = MyOverlayViewController()
overlayVC.view.backgroundColor = .clear

let overlay = UniversalOverlay.show(viewController: overlayVC)
overlay?.dismiss()
```


## Customization

### Configuration

```swift
let config = OverlayConfiguration(
    level: .statusBar + 1,        // Window level
    ignoresSafeArea: true,        // Extend edge-to-edge
    animationDuration: 0.25,      // Fade in/out duration
    autoDismissAfter: 5.0         // Auto-dismiss after 5 seconds
)

let overlay = UniversalOverlay.show(configuration: config) {
    MyOverlayView()
}
```

| Option | Type | Default | Description |
|:-------|:-----|:--------|:------------|
| `level` | `UIWindow.Level` | `.statusBar + 1` | Window z-order |
| `ignoresSafeArea` | `Bool` | `false` | Extend content edge-to-edge |
| `animationDuration` | `TimeInterval` | `0` | Fade animation duration |
| `autoDismissAfter` | `TimeInterval?` | `nil` | Auto-dismiss delay |

### Presets

```swift
UniversalOverlay.show(configuration: .aboveStatusBar) { ... }  // Default
UniversalOverlay.show(configuration: .aboveAlerts) { ... }
UniversalOverlay.show(configuration: .topmost) { ... }         // Highest level
UniversalOverlay.show(configuration: .debug) { ... }           // Auto-dismisses after 3s
```

### Runtime Control

```swift
let overlay = UniversalOverlay.show { MyView() }

overlay?.update { UpdatedView() }           // Update content
overlay?.setLevel(.alert + 1)               // Change window level
overlay?.autoDismiss(after: 10.0)           // Schedule auto-dismiss
overlay?.cancelAutoDismiss()                // Cancel pending auto-dismiss
overlay?.dismiss(animated: true)            // Animated dismiss
```

### Specific Window Scene

```swift
UniversalOverlay.show(in: myWindowScene) {
    MyOverlayView()
}
```

### Manual Setup

For full control, use `PassThroughWindow` directly:

```swift
guard let scene = UIApplication.shared.connectedScenes
    .compactMap({ $0 as? UIWindowScene }).first else { return }

let window = PassThroughWindow(windowScene: scene)
window.windowLevel = .statusBar + 1
window.rootViewController = UIHostingController(rootView: MyOverlay())
window.rootViewController?.view.backgroundColor = .clear
window.isHidden = false
```


## How It Works

`PassThroughWindow` overrides `hitTest(_:with:)` to determine if touches should pass through:

- **Pre-iOS 18**: Checks if the touch hit only the root view's background. If so, returns `nil` to pass through.
- **iOS 18+**: Iterates through subviews in reverse order to find actual content, as hit testing behavior changed in iOS 18.
- **iOS 26+**: View hierarchy traversal no longer available. Samples the pixel alpha at the touch point and passes through if transparent (alpha < 0.01).

The iOS 26 pixel-sampling approach works but isn't ideal. If you know of a better method, contributions are welcome.


## Contributing

Contributions welcome. Please feel free to submit a Pull Request.


## License

MIT. See [LICENSE](LICENSE) for details.
